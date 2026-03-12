//
//  GmailService.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 12/3/2026.
//

import Foundation
import AppKit

class GmailService {
    private var accessToken: String?

    init() {
        self.accessToken = KeychainHelper.load(key: "gmail_access_token")
    }

    // MARK: - Public API

    func fetchRecentEmails(maxResults: Int = 20) async throws -> [Email] {
        let ids = try await fetchEmailIDs(maxResults: maxResults)
        return try await withThrowingTaskGroup(of: Email?.self) { group in
            for id in ids {
                group.addTask { try? await self.fetchEmail(id: id) }
            }
            var emails: [Email] = []
            for try await email in group {
                if let email { emails.append(email) }
            }
            return emails.sorted { $0.receivedAt > $1.receivedAt }
        }
    }

    // MARK: - Fetch IDs

    func fetchEmailIDs(maxResults: Int = 20) async throws -> [String] {
        var components = URLComponents(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages")!
        components.queryItems = [.init(name: "maxResults", value: "\(maxResults)")]

        var request = URLRequest(url: components.url!)
        try await authorize(&request)

        let (data, response) = try await URLSession.shared.data(for: request)
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            try await refreshAccessToken()
            var retryRequest = URLRequest(url: components.url!)
            try await authorize(&retryRequest)
            let (retryData, _) = try await URLSession.shared.data(for: retryRequest)
            let decoded = try JSONDecoder().decode(MessageListResponse.self, from: retryData)
            return decoded.messages?.map { $0.id } ?? []
        }

        let decoded = try JSONDecoder().decode(MessageListResponse.self, from: data)
        return decoded.messages?.map { $0.id } ?? []
    }

    // MARK: - Fetch Single Email

    func fetchEmail(id: String) async throws -> Email {
        var components = URLComponents(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)")!
        components.queryItems = [.init(name: "format", value: "full")]

        var request = URLRequest(url: components.url!)
        try await authorize(&request)

        let (data, response) = try await URLSession.shared.data(for: request)
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            try await refreshAccessToken()
            var retryRequest = URLRequest(url: components.url!)
            try await authorize(&retryRequest)
            let (retryData, _) = try await URLSession.shared.data(for: retryRequest)
            return try parseGmailMessage(try JSONDecoder().decode(GmailMessage.self, from: retryData))
        }

        let message = try JSONDecoder().decode(GmailMessage.self, from: data)
        return try parseGmailMessage(message)
    }

    // MARK: - Parsing

    private func parseGmailMessage(_ message: GmailMessage) throws -> Email {
        let headers = message.payload.headers ?? []
        let subject = headers.first(where: { $0.name.lowercased() == "subject" })?.value ?? "(No Subject)"
        let sender  = headers.first(where: { $0.name.lowercased() == "from" })?.value ?? "Unknown"

        let receivedAt: Date
        if let ms = Double(message.internalDate) {
            receivedAt = Date(timeIntervalSince1970: ms / 1000)
        } else {
            receivedAt = Date()
        }

        let body = extractBody(from: message.payload)

        return Email(
            id: UUID(),
            sender: sender,
            subject: subject,
            body: body,
            receivedAt: receivedAt,
            source: .gmail,
            priority: .medium,
            summary: "",
            tags: []
        )
    }

    /// Recursively walks the MIME tree to find the plain-text (or HTML fallback) body.
    private func extractBody(from payload: MessagePayload) -> String {
        // Prefer text/plain
        if let text = findPart(in: payload, mimeType: "text/plain") {
            return decodeBase64URL(text) ?? ""
        }
        // Fallback to text/html stripped of tags
        if let html = findPart(in: payload, mimeType: "text/html") {
            return stripHTML(decodeBase64URL(html) ?? "")
        }
        // Direct body data (non-multipart)
        if let data = payload.body?.data {
            return decodeBase64URL(data) ?? ""
        }
        return ""
    }

    private func findPart(in payload: MessagePayload, mimeType: String) -> String? {
        if payload.mimeType == mimeType, let data = payload.body?.data {
            return data
        }
        for part in payload.parts ?? [] {
            if let found = findPartInMessagePart(part, mimeType: mimeType) {
                return found
            }
        }
        return nil
    }

    private func findPartInMessagePart(_ part: MessagePart, mimeType: String) -> String? {
        if part.mimeType == mimeType, let data = part.body?.data {
            return data
        }
        for child in part.parts ?? [] {
            if let found = findPartInMessagePart(child, mimeType: mimeType) {
                return found
            }
        }
        return nil
    }

    private func decodeBase64URL(_ string: String) -> String? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil))?.string ?? html
    }

    // MARK: - Auth Helpers

    private func authorize(_ request: inout URLRequest) async throws {
        guard let token = accessToken ?? KeychainHelper.load(key: "gmail_access_token") else {
            throw URLError(.userAuthenticationRequired)
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = KeychainHelper.load(key: "gmail_refresh_token") else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "client_id": Config.Gmail.clientID,
            "grant_type": "refresh_token"
        ]
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        KeychainHelper.save(key: "gmail_access_token", value: response.accessToken)
        accessToken = response.accessToken
    }
}

// MARK: - Response Models

struct MessageListResponse: Decodable {
    let messages: [MessageID]?
}

struct MessageID: Decodable {
    let id: String
}

struct GmailMessage: Decodable {
    let id: String
    let internalDate: String
    let payload: MessagePayload
}

struct MessagePayload: Decodable {
    let mimeType: String?
    let headers: [MessageHeader]?
    let body: MessageBody?
    let parts: [MessagePart]?
}

struct MessageHeader: Decodable {
    let name: String
    let value: String
}

struct MessageBody: Decodable {
    let data: String?
}

struct MessagePart: Decodable {
    let mimeType: String
    let body: MessageBody?
    let parts: [MessagePart]?
}

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
