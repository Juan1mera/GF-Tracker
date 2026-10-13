import SwiftUI

/// Una categoría dibujada como boleto: cuerpo con emoji y nombre, talón con el conteo.
struct CategoryCard: View {
    let category: TrackerCategory

    var body: some View {
        TicketCard(
            stock: category.ticketStock,
            emoji: category.emoji,
            name: category.name,
            photoURL: category.photoURL,
            count: category.entryCount,
            caption: lastEntryText,
            stamped: category.touchedToday
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.name), \(category.entryCount) \(category.entryCount == 1 ? "registro" : "registros"). \(lastEntryText)")
    }

    private var lastEntryText: String {
        guard let last = category.lastEntryAt?.dateValue() else { return "Sin registros" }
        return last.formatted(.relative(presentation: .named))
    }
}

/// Boleto vertical reutilizable (también lo usa la vista previa de "Nueva categoría").
struct TicketCard: View {
    let stock: TicketStock
    let emoji: String?
    let name: String
    var photoURL: String? = nil
    var localImage: UIImage? = nil
    let count: Int
    let caption: String
    var stamped = false

    private let stubLength: CGFloat = 70

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cuerpo
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    receipt
                    Spacer(minLength: 4)
                    if stamped {
                        Stamp(text: "HOY", color: stock.ink)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
                Text(name.isEmpty ? "Sin nombre" : name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)

            Perforation(color: stock.ink.opacity(0.45))

            // Talón
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(count, format: .number)
                    .font(.folio(46, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: Double(count)))
                Spacer(minLength: 0)
                Text(caption)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .opacity(0.85)
            }
            .padding(.horizontal, 12)
            .frame(height: stubLength - 2)
        }
        .foregroundStyle(stock.ink)
        .background(stock.paper)
        .clipShape(TicketShape(stubLength: stubLength))
        .contentShape(TicketShape(stubLength: stubLength))
    }

    /// Foto de portada como "comprobante"; si no hay, el emoji.
    @ViewBuilder
    private var receipt: some View {
        if localImage != nil || photoURL != nil {
            Group {
                if let localImage {
                    Image(uiImage: localImage).resizable().scaledToFill()
                } else {
                    RemoteImage(url: photoURL, placeholderEmoji: emoji, paper: stock.paper)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(stock.ink.opacity(0.25), lineWidth: 1)
            )
        } else {
            Text(emoji?.isEmpty == false ? emoji! : "🎟️")
                .font(.system(size: 30))
                .frame(height: 44, alignment: .topLeading)
        }
    }
}
