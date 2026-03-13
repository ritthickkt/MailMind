//
//  ContentView.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel    = EmailViewModel()
    @StateObject private var gmailAuth   = GmailAuthService()
    @StateObject private var outlookAuth = OutlookAuthService()
    @State private var selectedPriority: Priority? = .urgent
    @State private var selectedSource: EmailSource? = nil
    @State private var selectedLabel: String? = nil

    var filteredEmails: [Email] {
        viewModel.emails.filter { email in
            (selectedPriority == nil || email.priority == selectedPriority) &&
            (selectedSource   == nil || email.source   == selectedSource)   &&
            (selectedLabel    == nil || email.tags.contains(selectedLabel!))
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                selectedPriority: $selectedPriority,
                selectedSource: $selectedSource,
                selectedLabel: $selectedLabel,
                viewModel: viewModel,
                gmailAuth: gmailAuth,
                outlookAuth: outlookAuth
            )

            Rectangle()
                .fill(Color.mmBorder)
                .frame(width: 1)

            VStack(spacing: 0) {
                headerBar
                Rectangle()
                    .fill(Color.mmBorder)
                    .frame(height: 1)
                contentArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.mmSurface)
        }
        .background(Color.mmBg)
        .preferredColorScheme(.dark)
        .frame(minWidth: 680, minHeight: 520)
        .onAppear {
            if isAnyAuthenticated { viewModel.refresh() }
        }
        .onChange(of: gmailAuth.isAuthenticated) { _, isAuth in
            if isAuth { viewModel.refresh() }
        }
        .onChange(of: outlookAuth.isAuthenticated) { _, isAuth in
            if isAuth { viewModel.refresh() }
        }
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Text(selectedPriority?.rawValue.capitalized ?? "All")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(Color.mmText)
                Text("Inbox")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.mmAccent)
            }
            Spacer()
            HStack(spacing: 6) {
                filterPill("All",     source: nil)
                filterPill("Gmail",   source: .gmail)
                filterPill("Outlook", source: .outlook)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func filterPill(_ label: String, source: EmailSource?) -> some View {
        let isActive = selectedSource == source
        Button(label) {
            selectedSource = source
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, design: .monospaced))
        .tracking(0.6)
        .foregroundStyle(isActive ? Color.mmAccent : Color.mmMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isActive ? Color.mmAccent.opacity(0.08) : Color.clear)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                isActive ? Color.mmAccent : Color.mmBorder,
                lineWidth: 1
            )
        )
    }

    // MARK: - Content area

    private var isAnyAuthenticated: Bool {
        gmailAuth.isAuthenticated || outlookAuth.isAuthenticated
    }

    @ViewBuilder
    private var contentArea: some View {
        if !isAnyAuthenticated {
            connectView
        } else if viewModel.isLoading {
            loadingView
        } else if let err = viewModel.error {
            errorView(err)
        } else {
            emailFeed
        }
    }

    private var emailFeed: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !viewModel.dailyBrief.isEmpty {
                    DailyBriefView(brief: viewModel.dailyBrief)
                        .padding(16)
                }

                if filteredEmails.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredEmails) { email in
                        EmailRowView(email: email)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No emails")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color.mmMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.mmAccent)
            Text(viewModel.loadingMessage)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.mmMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var connectView: some View {
        VStack(spacing: 20) {
            Text("✦")
                .font(.system(size: 32))
                .foregroundStyle(Color.mmAccent)
            Text("Connect an account to get started")
                .font(.system(size: 14, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.mmMuted)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                connectButton(
                    label: "Connect Gmail",
                    color: Color.mmGmail,
                    action: { gmailAuth.startOAuthFlow() }
                )
                connectButton(
                    label: "Connect Outlook",
                    color: Color.mmOutlook,
                    action: { outlookAuth.startOAuthFlow() }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func connectButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(color)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Failed to load emails")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.mmUrgent)
            Text(message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.mmMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try again") { viewModel.refresh() }
                .buttonStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.mmAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
