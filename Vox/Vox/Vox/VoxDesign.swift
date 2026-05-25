import SwiftUI

// MARK: - Swiss Modernist Design System

enum VoxColors {
    static let paper = Color(red: 0.961, green: 0.961, blue: 0.953)       // #F5F5F3
    static let black = Color.black                                         // #000000
    static let orange = Color(red: 1.0, green: 0.31, blue: 0.0)           // #FF4F00
    static let divider = Color(red: 0.886, green: 0.886, blue: 0.878)     // #E2E2E0
    static let muted = Color(red: 0.627, green: 0.627, blue: 0.627)       // #A0A0A0
    static let fadedText = Color(red: 0.8, green: 0.8, blue: 0.8)         // For streaming text
}

enum VoxTypography {
    // Labels: 10px, ALL CAPS, wide letter-spacing, muted gray
    static func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(2.5)
            .foregroundColor(VoxColors.muted)
    }

    // Section headers: Bold, tight tracking
    static func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .bold))
            .tracking(-0.5)
            .foregroundColor(VoxColors.black)
    }

    // Title: Black weight, very tight tracking
    static func title(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 36, weight: .black))
            .tracking(-1)
            .foregroundColor(VoxColors.black)
    }

    // Body bold
    static func bodyBold(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .tracking(-0.3)
            .foregroundColor(VoxColors.black)
    }

    // Transcript text: Large, bold
    static func transcript(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold))
            .tracking(-0.5)
            .foregroundColor(VoxColors.black)
    }

    // Faded transcript (streaming)
    static func transcriptFaded(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold))
            .tracking(-0.5)
            .foregroundColor(VoxColors.fadedText)
    }

    // History item title
    static func historyTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .bold))
            .tracking(-0.3)
            .foregroundColor(VoxColors.black)
    }

    // Small timestamp
    static func timestamp(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(1)
            .foregroundColor(VoxColors.muted)
    }

    // Button text
    static func button(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundColor(VoxColors.black)
    }
}

// MARK: - Dividers

struct HeavyDivider: View {
    var body: some View {
        Rectangle()
            .fill(VoxColors.black)
            .frame(height: 2)
    }
}

struct LightDivider: View {
    var body: some View {
        Rectangle()
            .fill(VoxColors.divider)
            .frame(height: 1)
    }
}

// MARK: - Record Button

struct SwissRecordButton: View {
    let isRecording: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(isRecording ? VoxColors.orange : VoxColors.black, lineWidth: 1.5)
                    .frame(width: 120, height: 120)

                // Inner dot
                Circle()
                    .fill(isRecording ? VoxColors.orange : VoxColors.black)
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Orange Cursor

struct OrangeCursor: View {
    var body: some View {
        Rectangle()
            .fill(VoxColors.orange)
            .frame(width: 3, height: 28)
    }
}

// MARK: - Text Button (Swiss style)

struct SwissTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(VoxColors.black)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2.5)
                .foregroundColor(VoxColors.muted)
            content
        }
    }
}
