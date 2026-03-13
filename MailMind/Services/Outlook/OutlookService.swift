//
//  OutlookService.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 13/3/2026.
//

import Foundation
import AppKit

class OutlookService {
    private var accessToken: String?

    init() {
        self.accessToken = KeychainHelper.load(key: "outlook_access_token")
    }

    // MARK: - Public API

    func fetchRecentEmails(maxResults: Int = 20) async throws -> [Email] {
        var components = URLComponents(string: "https://graph.microsoft.com/v1.0/me/messages")!
        components.queryItems = [
            .init(name: "$top",     value: "\(maxResults)"),
            .init(name: "$select",  value: "id,subject,from,receivedDateTime,body"),
            .init(name: "$orderby", value: "receivedDateTime desc"),
        ]

        var request = URLRequest(url: components.url!)
        try await authorize(&request)

        let (data, response) = try await URLSession.shared.data(for: request)
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            try await refreshAccessToken()
            var retryRequest = URLRequest(url: components.url!)
            try await authorize(&retryRequest)
            let (retryData, _) = try await URLSession.shared.data(for: retryRequest)
            return try parseMessages(from: retryData)
        }

        return try parseMessages(from: data)
    }

    // MARK: - Parsing

    private func parseMessages(from data: Data) throws -> [Email] {
        let decoded = try JSONDecoder().decode(GraphMessageListResponse.self, from: data)
        return decoded.value.compactMap { parseGraphMessage($0) }
    }

    private func parseGraphMessage(_ message: GraphMessage) -> Email? {
        let sender  = message.from?.emailAddress.name
                   ?? message.from?.emailAddress.address
                   ?? "Unknown"
        let subject = message.subject ?? "(No Subject)"

        let receivedAt: Date
        if let dateStr = message.receivedDateTime,
           let date = ISO8601DateFormatter().date(from: dateStr) {
            receivedAt = date
        } else {
            receivedAt = Date()
        }

        let body: String
        if let content = message.body?.content {
            body = message.body?.contentType?.lowercased() == "html"
                ? stripHTML(content)
                : content
        } else {
            body = ""
        }

        return Email(
            id: UUID(),
            sender: sender,
            subject: subject,
            body: body,
            receivedAt: receivedAt,
            source: .outlook,
            priority: .medium,
            summary: "",
            tags: []
        )
    }

    private func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil))?.string ?? html
    }

    // MARK: - Auth Helpers

    private func authorize(_ request: inout URLRequest) async throws {
        guard let token = accessToken ?? KeychainHelper.load(key: "outlook_access_token") else {
            throw URLError(.userAuthenticationRequired)
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = KeychainHelper.load(key: "outlook_refresh_token") else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = URL(
            string: "https://login.microsoftonline.com/\(Config.Outlook.tenantID)/oauth2/v2.0/token"
        )!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "client_id":     Config.Outlook.clientID,
            "refresh_token": refreshToken,
            "grant_type":    "refresh_token",
            "scope":         Config.Outlook.scope,
        ]
        request.httpBody = params
            .map { k, v in
                let ek = k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? k
                let ev = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
                return "\(ek)=\(ev)"
            }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OutlookRefreshResponse.self, from: data)
        KeychainHelper.save(key: "outlook_access_token", value: response.accessToken)
        accessToken = response.accessToken
    }
}

// MARK: - Response Models

struct GraphMessageListResponse: Decodable {
    let value: [GraphMessage]
}

struct GraphMessage: Decodable {
    let id: String
    let subject: String?
    let from: GraphSender?
    let receivedDateTime: String?
    let body: GraphMessageBody?
}

struct GraphSender: Decodable {
    let emailAddress: GraphEmailAddress
}

struct GraphEmailAddress: Decodable {
    let name: String?
    let address: String
}

struct GraphMessageBody: Decodable {
    let contentType: String?
    let content: String?
}

struct OutlookRefreshResponse: Decodable {
    let accessToken: String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
