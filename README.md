 ---                                                                                                                                                     
  # MailMind                                                                                                                                                
                                                                                                                                                          
  A native macOS email client that uses Claude AI to triage and summarise your inbox in real time.                                                        
                                                            
  ## Features

  - AI-powered triage — Every email is analysed by Claude and assigned a priority (Urgent, Medium, or Low) along with a concise summary, so you can see
  what matters at a glance.
  - Daily Brief — A short, automatically generated brief surfaces the most urgent items requiring action each day.
  - Multi-account support — Connect Gmail and Outlook simultaneously. Emails from both accounts appear in a unified feed.
  - Label filtering — Emails are automatically tagged by Claude (Action Needed, Meeting, Finance, Info Only) and can be filtered from the sidebar.
  - Source & priority filters — Quickly narrow the feed by account source or priority level.
  - Minimal dark UI — Built with SwiftUI, designed to stay out of your way.

  ## Tech Stack

  - SwiftUI — Native macOS interface
  - Claude API (Haiku) — Email analysis, prioritisation, tagging, and daily brief generation
  - Gmail API — Fetches recent emails via OAuth 2.0
  - Microsoft Graph API — Fetches Outlook emails via OAuth 2.0 with PKCE
  - Keychain — Tokens are stored securely on-device

  ## How It Works

  1. Connect your Gmail and/or Outlook account on first launch.
  2. MailMind fetches your most recent emails and sends each one to Claude for analysis.
  3. Claude returns a priority level, a 1–2 sentence summary, and relevant tags.
  4. Your inbox is displayed ranked by priority, with filters in the sidebar to drill down by priority, source, or label.

  ## Disclaimer

  This app is not publicly usable in its current state. Because it uses a development OAuth configuration, only email addresses explicitly added as
  authorised test accounts can authenticate. If you try to connect your account and it fails or is rejected, this is the reason — your email has not been
  added as an approved test user. This is a personal project and is not intended for general distribution at this time.

  ## Requirements

  - macOS 14 (Sonnet) or later
  - Xcode 15+
  - A valid Anthropic API key
  - Gmail and/or Microsoft Azure app credentials (see Config.example.swift)

  ## Setup (for contributors)

  1. Duplicate Config.example.swift and rename it Config.swift.
  2. Fill in your Anthropic API key, Gmail client ID/redirect URI, and Azure client ID/tenant ID/redirect URI.
  3. Build and run in Xcode.

  ---
