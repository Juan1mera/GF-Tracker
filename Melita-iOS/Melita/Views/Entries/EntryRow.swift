import SwiftUI

/// Un registro como boleto arrancado: folio Nº, nota, fecha y la foto como comprobante.
struct EntryRow: View {
    let entry: TrackerEntry
    let serial: Int
    let stock: TicketStock
    @State private var showPhoto = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(spacing: -2) {
                Text("Nº")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(stock.ink.opacity(0.8))
                Text(serial, format: .number.grouping(.never))
                    .font(.folio(24, relativeTo: .title3))
                    .monospacedDigit()
                    .foregroundStyle(stock.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 52, height: 52)
            .background(stock.paper, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.note.isEmpty ? "Sin descripción" : entry.note)
                    .foregroundStyle(entry.note.isEmpty ? Theme.inkSecondary : Theme.ink)
                    .lineLimit(3)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)

            if entry.photoURL != nil {
                Button {
                    showPhoto = true
                } label: {
                    RemoteImage(url: entry.photoURL, paper: stock.paper)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ver foto del boleto \(serial)")
            }
        }
        .padding(.vertical, 4)
        .fullScreenCover(isPresented: $showPhoto) {
            PhotoViewer(url: entry.photoURL, caption: entry.note, serial: serial)
        }
    }
}

struct PhotoViewer: View {
    let url: String?
    let caption: String
    var serial: Int? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                RemoteImage(url: url, paper: .black, contentMode: .fit)
                Spacer()
                if serial != nil || !caption.isEmpty {
                    VStack(spacing: 4) {
                        if let serial {
                            Text("Nº \(serial)")
                                .font(.folio(28, relativeTo: .title2))
                                .foregroundStyle(TicketStock.maiz.paper)
                        }
                        if !caption.isEmpty {
                            Text(caption)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                }
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Cerrar")
            .padding()
        }
    }
}
