//
//  AnthropicService.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 12/3/2026.
//

import Foundation

class AnthropicService {
    private let apiKey = Config.Anthropic.apiKey
    private let model  = "claude-haiku-4-5-20251001"

    // MARK: - Public

    /// Returns a new Email with AI-generated summary, priority, and tags.
    func analyzeEmail(_ email: Email) async throws -> Email {
        let prompt = """
        Analyze this email and respond ONLY with a JSON object — no explanation, no markdown, just raw JSON.

        Format:
        {"summary":"1-2 sentence summary","priority":"urgent|medium|low","tags":["tag1","tag2"]}

        Priority rules:
        - urgent: requires action today, imminent deadline, or critical decision
        - medium: needs attention within a few days
        - low: informational, no action needed

        Valid tags (pick 1–2 that best fit): Action Needed, Decision Required, Contract, Meeting, Finance, Hiring, Incident, Info Only

        Email:
        From: \(email.sender)
        Subject: \(email.subject)
        Body: \(email.body.prefix(800))
        """

        let text = try await callClaudeText(prompt: prompt)
        let analysis = parseEmailAnalysis(from: text)

        let priority: Priority
        switch analysis.priority.lowercased() {
        case "urgent": priority = .urgent
        case "low":    priority = .low
        default:       priority = .medium
        }

        return Email(
            id: email.id,
            sender: email.sender,
            subject: email.subject,
            body: email.body,
            receivedAt: email.receivedAt,
            source: email.source,
            priority: priority,
            summary: analysis.summary,
            tags: analysis.tags
        )
    }

    /// Generates a 1–2 sentence daily brief from the list of urgent emails.
    func generateDailyBrief(for emails: [Email]) async throws -> String {
        let items = emails.map { "- \($0.sender): \($0.summary.isEmpty ? $0.subject : $0.summary)" }
                         .joined(separator: "\n")
        let prompt = """
        Write a concise 1–2 sentence daily brief about these urgent emails. \
        Be specific about what actions are needed. No greeting, no formatting.

        \(items)
        """
        return try await callClaudeText(prompt: prompt)
    }

    // MARK: - Private

    private func callClaudeText(prompt: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey,          forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",    forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 300,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response  = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let content = response.content.first?.text else {
            throw URLError(.cannotDecodeContentData)
        }
        return content
    }

    private func parseEmailAnalysis(from text: String) -> EmailAnalysis {
        // Strip any markdown code fences Claude might add
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```",     with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract first {...} block
        if let start = cleaned.firstIndex(of: "{"),
           let end   = cleaned.lastIndex(of: "}") {
            let jsonSlice = String(cleaned[start...end])
            if let data  = jsonSlice.data(using: .utf8),
               let parsed = try? JSONDecoder().decode(EmailAnalysis.self, from: data) {
                return parsed
            }
        }
        // Fallback
        return EmailAnalysis(summary: text.prefix(120).description, priority: "medium", tags: ["Info Only"])
    }
}

// MARK: - Response Models

private struct AnthropicResponse: Decodable {
    let content: [AnthropicContent]
}

private struct AnthropicContent: Decodable {
    let type: String
    let text: String
}

struct EmailAnalysis: Decodable {
    let summary: String
    let priority: String
    let tags: [String]
}
