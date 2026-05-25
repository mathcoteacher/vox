import SwiftUI

enum VoxiOSPalette {
    static let paper = Color(red: 0.969, green: 0.965, blue: 0.949)
    static let ink = Color(red: 0.078, green: 0.082, blue: 0.094)
    static let muted = Color(red: 0.431, green: 0.451, blue: 0.490)
    static let signal = Color(red: 1.0, green: 0.345, blue: 0.067)
    static let card = Color.white.opacity(0.72)
    static let line = Color.black.opacity(0.08)
}

struct VoxCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(VoxiOSPalette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(VoxiOSPalette.line, lineWidth: 1)
                    )
            )
    }
}

struct StatePill: View {
    let text: String
    let isActive: Bool

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(isActive ? Color.white : VoxiOSPalette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? VoxiOSPalette.signal : Color.white.opacity(0.9))
            )
    }
}

struct RecordOrbButton: View {
    let isRecording: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isRecording ? VoxiOSPalette.signal.opacity(0.35) : Color.white,
                                VoxiOSPalette.paper,
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 90
                        )
                    )
                    .frame(width: 168, height: 168)

                Circle()
                    .stroke(isRecording ? VoxiOSPalette.signal : VoxiOSPalette.ink, lineWidth: 2)
                    .frame(width: 140, height: 140)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(isRecording ? VoxiOSPalette.signal : VoxiOSPalette.ink)
            }
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}
