import SwiftUI

struct NewEntryView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    let category: TrackerCategory
    /// Folio que recibirá este boleto.
    let serial: Int
    let store: EntriesStore

    @State private var note = ""
    @State private var image: UIImage?
    @State private var isSaving = false
    @State private var errorText: String?

    private var canSave: Bool {
        image != nil || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    serialHeader
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    PhotoPickerField(image: $image, placeholder: "La foto es el comprobante")
                }
                .listRowBackground(Theme.surface)

                Section("Nota") {
                    TextField("¿Cuál fue? ¿Dónde? ¿Con quién?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > 500 { note = String(newValue.prefix(500)) }
                        }
                }
                .listRowBackground(Theme.surface)

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                        .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .groundBackground()
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Guardar") { Task { await save() } }
                            .bold()
                            .disabled(!canSave)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    /// Talón con el folio que se va a arrancar.
    private var serialHeader: some View {
        let stock = category.ticketStock
        return HStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(category.emoji?.isEmpty == false ? category.emoji! : "🎟️")
                    .font(.title)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Boleto nuevo")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.85)
                    Text(category.name)
                        .font(.headline)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            Perforation(axis: .horizontal, color: stock.ink.opacity(0.45))

            Text("Nº \(serial)")
                .font(.folio(34, relativeTo: .title))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 104)
        }
        .frame(height: 76)
        .foregroundStyle(stock.ink)
        .background(stock.paper)
        .clipShape(TicketShape(axis: .horizontal, stubLength: 105))
        .accessibilityElement(children: .combine)
    }

    private func save() async {
        guard let uid = session.uid else { return }
        isSaving = true
        errorText = nil
        defer { isSaving = false }
        do {
            try await store.addEntry(
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                image: image,
                createdBy: uid
            )
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
