//
//  GmailAuthService.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

import Foundation
import AppKit
import Combine
import AuthenticationServices

class GmailAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false
    
    private let clientID = Config.Gmail.clientID
    private let redirectURI = Config.Gmail.redirectURI
    private let scope = Config.Gmail.scope

    func startOAuthFlow() {
      var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
      components.queryItems = [
          .init(name: "client_id", value: clientID),
          .init(name: "redirect_uri", value: redirectURI),
          .init(name: "response_type", value: "code"),
          .init(name: "scope", value: scope),
          .init(name: "access_type", value: "offline")
      ]

      let session = ASWebAuthenticationSession(
          url: components.url!,
          callbackURLScheme: "com.ritthick.MailMind"
      ) { [weak self] callbackURL, error in
          if let error = error {
              print("Auth error: \(error)")
              return
          }
          guard let url = callbackURL else {
              print("No callback URL")
              return
          }
          print("Callback URL: \(url)")
          guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
              .queryItems?
              .first(where: { $0.name == "code" })?
              .value else {
              print("No code found")
              return
          }
          print("Got code: \(code)")
          Task {
              do {
                  try await self?.handleCallback(code: code)
              } catch {
                  print("handleCallback error: \(error)")
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

    // Step 2: Exchange auth code for tokens
    func handleCallback(code: String) async throws {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        //Save tokens to Keychain
        KeychainHelper.save(key: "gmail_access_token", value: response.accessToken)
        if let refresh = response.refreshToken {
            KeychainHelper.save(key: "gmail_refresh_token", value: refresh)
        }
        
        await MainActor.run { isAuthenticated = true }
    }
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
