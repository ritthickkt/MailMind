import Foundation
//
//  MockData.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

struct MockData {
    static let dailyBrief = "You have 2 urgent items requiring action before EOD: a contract awaiting your DocuSign signature (Meridian Legal) and a production outage opened by TechVentures. Three medium-priority threads need replies — no meetings require prep today."

    static let emails: [Email] = [

        // URGENT — Gmail
        Email(
            id: UUID(),
            sender: "Sarah Chen — Meridian Legal",
            subject: "Re: Q4 Vendor Contract — Signature Required by EOD",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 17),
            source: .gmail,
            priority: .urgent,
            summary: "Needs your DocuSign signature on the Q4 vendor contract. Deal lapses at 5 PM if unsigned — this is a hard deadline.",
            tags: ["Action Needed", "Contract"]
        ),

        // URGENT — Outlook
        Email(
            id: UUID(),
            sender: "Marcus Webb — TechVentures",
            subject: "URGENT: Production outage — API gateway returning 503s",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 47),
            source: .outlook,
            priority: .urgent,
            summary: "The payments API gateway has been returning 503s for 40 min. Engineering is on call but needs your incident approval to roll back.",
            tags: ["Action Needed", "Incident"]
        ),

        // MEDIUM — Gmail
        Email(
            id: UUID(),
            sender: "Priya Nair — Stripe",
            subject: "Invoice #4821 — $12,400 payment due in 3 days",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 90),
            source: .gmail,
            priority: .medium,
            summary: "Stripe invoice for your November SaaS subscription. Auto-pay is enabled but billing details have changed — confirm before Friday.",
            tags: ["Finance"]
        ),

        // MEDIUM — Gmail
        Email(
            id: UUID(),
            sender: "James Liu — Calendly",
            subject: "Team standup rescheduled — now 3:00 PM today",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 130),
            source: .gmail,
            priority: .medium,
            summary: "The 10 AM standup has moved to 3 PM due to a scheduling conflict. No agenda changes — same participants.",
            tags: ["Meeting"]
        ),

        // MEDIUM — Outlook
        Email(
            id: UUID(),
            sender: "Niketa Narayana — People Ops",
            subject: "Secret Santa 2026 — pick your match by Friday",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 200),
            source: .outlook,
            priority: .medium,
            summary: "You have been assigned a Secret Santa match. Log into the portal to see your person and budget cap ($40).",
            tags: ["Action Needed"]
        ),

        // LOW — Gmail
        Email(
            id: UUID(),
            sender: "Lena Hoffmann — Substack",
            subject: "Your weekly digest: 5 stories you might have missed",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 60 * 5),
            source: .gmail,
            priority: .low,
            summary: "Curated weekly reads across product, design, and engineering. No action required.",
            tags: ["Info Only"]
        ),

        // LOW — Outlook
        Email(
            id: UUID(),
            sender: "Tyler Brooks — HR",
            subject: "Company all-hands slides — Thursday 4 PM",
            body: "",
            receivedAt: Date().addingTimeInterval(-60 * 60 * 8),
            source: .outlook,
            priority: .low,
            summary: "Slides for Thursday's all-hands are attached. Review optional — leadership will present. RSVP not required.",
            tags: ["Info Only"]
        ),
    ]
}
