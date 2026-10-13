import SwiftUI

extension View {
    /// Campo de texto sobre superficie, con esquinas de boleto.
    func fieldStyle() -> some View {
        padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Fondo de pantalla de la app.
    func groundBackground() -> some View {
        background(Theme.ground.ignoresSafeArea())
    }
}

/// Tira de marcador: celdas separadas por perforación, números en folio.
struct ScoreStrip: View {
    struct Cell: Identifiable {
        let value: Int
        let label: String
        var highlighted = false
        var id: String { label }
    }

    let cells: [Cell]
    var paper: Color = Theme.surface
    var ink: Color = Theme.ink
    var secondaryInk: Color = Theme.inkSecondary
    var perforation: Color = Theme.perforation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.element.id) { index, cell in
                if index > 0 {
                    Perforation(axis: .horizontal, color: perforation)
                        .padding(.vertical, -6)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(cell.value, format: .number)
                        .font(.folio(32, relativeTo: .title))
                        .monospacedDigit()
                        .foregroundStyle(cell.highlighted ? Theme.tint : ink)
                        .contentTransition(.numericText(value: Double(cell.value)))
                    Text(cell.label)
                        .font(.caption)
                        .foregroundStyle(secondaryInk)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)
            }
        }
        .background(paper, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .animation(.snappy, value: cells.map(\.value))
    }
}

/// Imagen remota. Sin foto: papel plano del boleto con su emoji (nunca degradados).
struct RemoteImage: View {
    let url: String?
    var placeholderEmoji: String? = nil
    var paper: Color = Theme.perforation
    var contentMode: ContentMode = .fill

    var body: some View {
        if let url, let parsed = URL(string: url) {
            AsyncImage(url: parsed, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                default:
                    ZStack {
                        paper.opacity(0.35)
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
            paper
            if let placeholderEmoji, !placeholderEmoji.isEmpty {
                Text(placeholderEmoji).font(.system(size: 40))
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
