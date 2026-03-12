//
//  PriorityBadge.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

import SwiftUI

struct PriorityBadge: View {
    let priority: Priority
    
    var color: Color {
        switch priority {
        case .urgent: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    var body: some View {
        Text(priority.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
