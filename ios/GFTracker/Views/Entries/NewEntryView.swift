import SwiftUI

struct NewEntryView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    let category: TrackerCategory
    let store: EntriesStore

    @State private var note = ""
    @State private var image: UIImage?
    @State private var isSaving = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotoPickerField(image: $image, placeholder: "Agrega una foto")
                }

                Section("Descripción") {
                    TextField("¿Cuál fue? ¿Dónde? ¿Con quién?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > 500 { note = String(newValue.prefix(500)) }
                        }
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }
            }
            .navigationTitle(category.title)
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
                            .disabled(image == nil && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
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
