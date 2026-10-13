import SwiftUI

extension View {
    /// Estilo de campo de texto redondeado.
    func fieldStyle() -> some View {
        padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct StatPill: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(.pink)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

/// Imagen remota con placeholder (gradiente + emoji).
struct RemoteImage: View {
    let url: String?
    var placeholderEmoji: String? = nil
    var contentMode: ContentMode = .fill

    var body: some View {
        if let url, let parsed = URL(string: url) {
            AsyncImage(url: parsed, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                default:
                    ZStack {
                        Color(.tertiarySystemFill)
                        ProgressView()
                    }
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [.pink.opacity(0.35), .purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(placeholderEmoji ?? "✨")
                .font(.system(size: 40))
        }
    }
}
