//
//  EmailViewModel.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 12/3/2026.
//

import Foundation
import Combine

@MainActor
class EmailViewModel: ObservableObject {
    @Published var emails: [Email] = []
    @Published var dailyBrief = ""
    @Published var isLoading = false
    @Published var loadingMessage = "Fetching emails…"
    @Published var error: String? = nil

    private let gmailService     = GmailService()
    private let outlookService   = OutlookService()
    private let anthropicService = AnthropicService()

    // MARK: - Computed counts (for sidebar)

    var urgentCount:  Int { emails.filter { $0.priority == .urgent }.count }
    var mediumCount:  Int { emails.filter { $0.priority == .medium }.count }
    var lowCount:     Int { emails.filter { $0.priority == .low    }.count }
    var gmailCount:   Int { emails.filter { $0.source   == .gmail  }.count }
    var outlookCount: Int { emails.filter { $0.source   == .outlook }.count }

    // MARK: - Load

    func loadEmails() async {
        isLoading     = true
        loadingMessage = "Fetching emails…"
        error          = nil

        do {
            var rawEmails: [Email] = []

            // Fetch from each authenticated source concurrently
            let gmailAuthenticated   = KeychainHelper.load(key: "gmail_access_token")   != nil
            let outlookAuthenticated = KeychainHelper.load(key: "outlook_access_token") != nil

            try await withThrowingTaskGroup(of: [Email].self) { group in
                if gmailAuthenticated {
                    group.addTask { try await self.gmailService.fetchRecentEmails(maxResults: 20) }
                }
                if outlookAuthenticated {
                    group.addTask { try await self.outlookService.fetchRecentEmails(maxResults: 20) }
                }
                for try await batch in group {
                    rawEmails.append(contentsOf: batch)
                }
            }

            loadingMessage = "Analysing with Claude…"

            var analysed: [Email] = []
            for raw in rawEmails {
                let result = (try? await anthropicService.analyzeEmail(raw)) ?? raw
                analysed.append(result)
            }

            analysed.sort { $0.receivedAt > $1.receivedAt }
            emails    = analysed
            isLoading = false

            // Generate daily brief from urgent emails
            let urgent = analysed.filter { $0.priority == .urgent }
            if urgent.isEmpty {
                dailyBrief = "No urgent items today — you're all caught up."
            } else {
                dailyBrief = (try? await anthropicService.generateDailyBrief(for: urgent))
                    ?? "You have \(urgent.count) urgent item(s) needing attention today."
            }
        } catch {
            self.error    = error.localizedDescription
            isLoading     = false
        }
    }

    func refresh() {
        Task { await loadEmails() }
    }
}
