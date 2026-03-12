//
//  DailyBriefView.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 12/3/2026.
//

import SwiftUI

struct DailyBriefView: View {
    let brief: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text("✦")
                    .foregroundStyle(Color.mmAccent)
                    .font(.system(size: 10))
                Text("AI DAILY BRIEF")
                    .font(.system(size: 9, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.mmAccent)
                    .kerning(1.5)
                Spacer()
            }

            Text(brief)
                .font(.system(size: 13, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.mmText.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmAccent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.mmAccent.opacity(0.15), lineWidth: 1)
        )
    }
}
