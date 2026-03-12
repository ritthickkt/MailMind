//
//  SidebarView.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedPriority: Priority?
    @Binding var selectedSource: EmailSource?
    @ObservedObject var viewModel: EmailViewModel
    @ObservedObject var gmailAuth: GmailAuthService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: PRIORITY
                sectionLabel("Priority")

                priorityRow(.urgent, label: "Urgent", count: viewModel.urgentCount)
                priorityRow(.medium, label: "Medium", count: viewModel.mediumCount)
                priorityRow(.low,    label: "Low",    count: viewModel.lowCount)

                divider

                // MARK: SOURCE
                sectionLabel("Source")

                sourceRow(.gmail,   label: "Gmail",   letter: "G",
                          color: .mmGmail,   count: viewModel.gmailCount)
                sourceRow(.outlook, label: "Outlook", letter: "O",
                          color: .mmOutlook, count: viewModel.outlookCount)

                divider

                // MARK: LABELS
                sectionLabel("Labels")

                labelRow("⚡", "Action Required")
                labelRow("📅", "Meetings")
                labelRow("💰", "Finance")
                labelRow("ℹ️", "Info Only")

                Spacer()

                // Connect / auth button at bottom
                if !gmailAuth.isAuthenticated {
                    Divider()
                        .overlay(Color.mmBorder)
                        .padding(.vertical, 8)
                    connectButton
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 200)
        .background(Color.mmBg)
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func priorityRow(_ priority: Priority, label: String, count: Int) -> some View {
        let isActive = selectedPriority == priority
        Button {
            selectedPriority = priority
        } label: {
            HStack(spacing: 8) {
                Text("●")
                    .font(.system(size: 8))
                    .foregroundStyle(priority.color)
                Text(label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(isActive ? Color.mmAccent : Color.mmMuted)
                Spacer()
                if count > 0 {
                    countBadge(count, active: isActive)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isActive ? Color.mmAccent.opacity(0.10) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func sourceRow(_ source: EmailSource, label: String, letter: String,
                           color: Color, count: Int) -> some View {
        let isActive = selectedSource == source
        Button {
            selectedSource = (selectedSource == source) ? nil : source
        } label: {
            HStack(spacing: 8) {
                Text(letter)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(isActive ? Color.mmAccent : Color.mmMuted)
                Spacer()
                if count > 0 {
                    countBadge(count, active: isActive)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isActive ? Color.mmAccent.opacity(0.10) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func labelRow(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 12))
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.mmMuted)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 7)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(Color.mmMuted)
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
            .padding(.top, 4)
    }

    private func countBadge(_ n: Int, active: Bool) -> some View {
        Text("\(n)")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(active ? Color.mmAccent : Color.mmMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                active
                    ? Color.mmAccent.opacity(0.20)
                    : Color.white.opacity(0.07)
            )
            .clipShape(Capsule())
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.mmBorder)
            .frame(height: 1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    private var connectButton: some View {
        Button {
            gmailAuth.startOAuthFlow()
        } label: {
            HStack {
                Image(systemName: "envelope.badge")
                Text("Connect Gmail")
                    .font(.system(size: 11, design: .monospaced))
            }
            .foregroundStyle(Color.mmAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.mmAccent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.mmAccent.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
