//
//  EmailRowView.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

import SwiftUI

struct EmailRowView: View {
    let email: Email

    // MARK: - Derived

    private var senderName: String {
        email.sender.components(separatedBy: " — ").first ?? email.sender
    }

    private var companyName: String? {
        let parts = email.sender.components(separatedBy: " — ")
        return parts.count > 1 ? parts[1] : nil
    }

    private var initials: String {
        let parts = senderName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    private var formattedTime: String {
        let diff = Date().timeIntervalSince(email.receivedAt)
        if diff < 3600  { return "\(max(1, Int(diff / 60)))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: email.receivedAt)
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Priority bar — 3 px strip on left edge
            Rectangle()
                .fill(email.priority.color)
                .frame(width: 3)

            HStack(alignment: .top, spacing: 14) {
                avatarView
                contentView
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(Color.mmSurface)
        .overlay(
            Rectangle()
                .fill(Color.mmBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Sub-views

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(email.priority.avatarBg)
                .frame(width: 36, height: 36)
            Text(initials)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(email.priority.avatarFg)
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Sender row
            HStack(spacing: 6) {
                sourceBadge
                HStack(spacing: 4) {
                    Text(senderName)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.mmText)
                    if let company = companyName {
                        Text("— \(company)")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.mmMuted)
                    }
                }
                Spacer()
                Text(formattedTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.mmMuted)
            }

            // Subject — monospaced, muted
            Text(email.subject)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.mmText.opacity(0.55))
                .lineLimit(1)

            // Summary — serif italic
            if !email.summary.isEmpty {
                Text(email.summary)
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.mmText.opacity(0.75))
                    .lineSpacing(3)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Tags
            if !email.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(email.tags, id: \.self) { tag in
                        tagBadge(tag)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private var sourceBadge: some View {
        let isGmail = email.source == .gmail
        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(isGmail ? Color.mmGmail : Color.mmOutlook)
                .frame(width: 14, height: 14)
            Text(isGmail ? "G" : "O")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func tagBadge(_ tag: String) -> some View {
        let style = tagStyle(for: tag)
        return Text(tag)
            .font(.system(size: 9, design: .monospaced))
            .tracking(0.8)
            .foregroundStyle(style.fg)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(style.bg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(style.border, lineWidth: 1))
    }

    private struct TagStyle {
        let fg: Color; let bg: Color; let border: Color
    }

    private func tagStyle(for tag: String) -> TagStyle {
        let t = tag.lowercased()
        if t.contains("action") || t.contains("decision") || t.contains("incident") {
            return TagStyle(
                fg: Color(hex: "e87878"),
                bg: Color.mmUrgent.opacity(0.12),
                border: Color.mmUrgent.opacity(0.2)
            )
        }
        if t.contains("meeting") || t.contains("schedule") {
            return TagStyle(
                fg: Color(hex: "7ec4b0"),
                bg: Color.mmLow.opacity(0.12),
                border: Color.mmLow.opacity(0.2)
            )
        }
        if t.contains("finance") || t.contains("contract") || t.contains("hiring") || t.contains("invoice") {
            return TagStyle(
                fg: Color.mmAccent,
                bg: Color.mmAccent.opacity(0.10),
                border: Color.mmAccent.opacity(0.2)
            )
        }
        // Info / default
        return TagStyle(
            fg: Color.mmMuted,
            bg: Color.white.opacity(0.05),
            border: Color.mmBorder
        )
    }
}
