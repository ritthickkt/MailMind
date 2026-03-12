import Foundation
//
//  Email.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

struct Email: Identifiable {
    let id: UUID
    let sender: String
    let subject: String
    let body: String
    let receivedAt: Date
    let source: EmailSource //gmail or outlook
    let priority: Priority //urgent, medium or low
    let summary: String //filled in by Clade later
    let tags: [String] //"Action Needed", "Contract", etc.
}

enum EmailSource {
    case gmail, outlook
}

enum Priority: String {
    case urgent, medium, low
}

