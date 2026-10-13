import SwiftUI

struct NewCategoryView: View {
    @Environment(SessionStore.self) private var session
    @Environment(CategoriesStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = ""
    @State private var image: UIImage?
    @State private var isSaving = false
    @State private var errorText: String?

    private let suggestions = ["🍫", "☕️", "🍺", "🍕", "🏃‍♀️", "💧", "📚", "💤", "💊", "🛍️", "🎮", "😘"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotoPickerField(image: $image, placeholder: "Foto de la categoría")
                }

                Section("Nombre") {
                    TextField("Ej. Chocolates", text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Emoji") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { item in
                                Button {
                                    emoji = (emoji == item) ? "" : item
                                } label: {
                                    Text(item)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle().fill(emoji == item ? Color.pink.opacity(0.25) : Color(.tertiarySystemFill))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TextField("O escribe otro emoji", text: $emoji)
                        .onChange(of: emoji) { _, newValue in
                            if newValue.count > 1 { emoji = String(newValue.suffix(1)) }
                        }
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Nueva categoría")
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
                        Button("Crear") { Task { await save() } }
                            .bold()
                            .disabled(trimmedName.isEmpty)
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
            try await store.createCategory(
                name: String(trimmedName.prefix(40)),
                emoji: emoji.isEmpty ? nil : emoji,
                image: image,
                ownerUid: uid
            )
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
