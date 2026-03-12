//
//  Colors.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 12/3/2026.
//

import SwiftUI

extension Color {
    // Design system colours from prototype
    static let mmBg       = Color(hex: "0e0e0f")
    static let mmSurface  = Color(hex: "161618")
    static let mmSurface2 = Color(hex: "1e1e21")
    static let mmBorder   = Color.white.opacity(0.07)
    static let mmText     = Color(hex: "e8e6e0")
    static let mmMuted    = Color(hex: "6b6a68")
    static let mmAccent   = Color(hex: "d4a853")
    static let mmUrgent   = Color(hex: "e05c5c")
    static let mmMedium   = Color(hex: "d4a853")
    static let mmLow      = Color(hex: "5ba08a")
    static let mmGmail    = Color(hex: "ea4335")
    static let mmOutlook  = Color(hex: "0078d4")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

extension Priority {
    var color: Color {
        switch self {
        case .urgent: return .mmUrgent
        case .medium: return .mmMedium
        case .low:    return .mmLow
        }
    }

    // Avatar background + foreground tints from the HTML prototype
    var avatarBg: Color {
        switch self {
        case .urgent: return Color.mmUrgent.opacity(0.15)
        case .medium: return Color.mmAccent.opacity(0.12)
        case .low:    return Color.mmLow.opacity(0.10)
        }
    }

    var avatarFg: Color {
        switch self {
        case .urgent: return Color(hex: "e87878")
        case .medium: return Color(hex: "d4a853")
        case .low:    return Color(hex: "7ec4b0")
        }
    }
}
