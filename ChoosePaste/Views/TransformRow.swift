import SwiftUI

struct TransformRow: View {
    let icon: String
    let label: String
    let shortcut: String
    let isSelected: Bool
    let isFlashing: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Icon box (20x20, 4px radius)
            Text(icon)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 20, height: 20)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)

            // Transform label
            Text(label)
                .font(.system(size: 13))

            Spacer()

            // Keyboard shortcut
            Text(shortcut)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(rowBackground)
        .cornerRadius(4)
    }

    private var rowBackground: some View {
        Group {
            if isFlashing {
                Color.green.opacity(0.3)
            } else if isSelected {
                Color.accentColor.opacity(0.2)
            } else {
                Color.clear
            }
        }
    }
}
