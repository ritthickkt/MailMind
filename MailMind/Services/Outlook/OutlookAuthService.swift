//
//  OutlookAuthService.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 13/3/2026.
//

import Foundation
import AppKit
import Combine
import AuthenticationServices
import CryptoKit

class OutlookAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false

    private let clientID   = Config.Outlook.clientID
    private let tenantID   = Config.Outlook.tenantID
    private let redirectURI = Config.Outlook.redirectURI
    private let scope      = Config.Outlook.scope

    private var codeVerifier: String = ""

    override init() {
        super.init()
        isAuthenticated = KeychainHelper.load(key: "outlook_access_token") != nil
    }

    func startOAuthFlow() {
        codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(
            string: "https://login.microsoftonline.com/\(tenantID)/oauth2/v2.0/authorize"
        )!
        components.queryItems = [
            .init(name: "client_id",             value: clientID),
            .init(name: "response_type",          value: "code"),
            .init(name: "redirect_uri",           value: redirectURI),
            .init(name: "scope",                  value: scope),
            .init(name: "response_mode",          value: "query"),
            .init(name: "code_challenge",         value: codeChallenge),
            .init(name: "code_challenge_method",  value: "S256"),
        ]

        let session = ASWebAuthenticationSession(
            url: components.url!,
            callbackURLScheme: "com.ritthick.MailMind"
        ) { [weak self] callbackURL, error in
            if let error = error {
                print("Outlook auth error: \(error)")
                return
            }
            guard let url = callbackURL else { return }
            guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "code" })?
                .value else {
                print("No code found in Outlook callback")
                return
            }
            Task {
                do {
                    try await self?.handleCallback(code: code)
                } catch {
                    print("Outlook handleCallback error: \(error)")
                }
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first!
    }

    // MARK: - Token Exchange

    func handleCallback(code: String) async throws {
        let url = URL(string: "https://login.microsoftonline.com/\(tenantID)/oauth2/v2.0/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "client_id":     clientID,
            "code":          code,
            "redirect_uri":  redirectURI,
            "grant_type":    "authorization_code",
            "code_verifier": codeVerifier,
            "scope":         scope,
        ]
        request.httpBody = urlEncodedBody(params)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OutlookTokenResponse.self, from: data)

        KeychainHelper.save(key: "outlook_access_token", value: response.accessToken)
        if let refresh = response.refreshToken {
            KeychainHelper.save(key: "outlook_refresh_token", value: refresh)
        }

        await MainActor.run { isAuthenticated = true }
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func urlEncodedBody(_ params: [String: String]) -> Data? {
        params
            .map { k, v in
                let encodedKey   = k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? k
                let encodedValue = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
            .data(using: .utf8)
    }
}

// MARK: - Response Model

struct OutlookTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
    }
}
