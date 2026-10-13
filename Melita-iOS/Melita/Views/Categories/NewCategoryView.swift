import SwiftUI

struct NewCategoryView: View {
    @Environment(SessionStore.self) private var session
    @Environment(CategoriesStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = ""
    @State private var stock: TicketStock = TicketStock.allCases.randomElement() ?? .bermellon
    @State private var image: UIImage?
    @State private var isSaving = false
    @State private var errorText: String?

    private let suggestions = ["🍫", "☕️", "🍺", "🍕", "🏃‍♀️", "💧", "📚", "💤", "💊", "🛍️", "🎮", "😘"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                // Vista previa en vivo del boleto.
                Section {
                    TicketCard(
                        stock: stock,
                        emoji: emoji,
                        name: trimmedName.isEmpty ? "Tu categoría" : trimmedName,
                        localImage: image,
                        count: 0,
                        caption: "Nuevo",
                        stamped: false
                    )
                    .frame(width: 176)
                    .frame(maxWidth: .infinity)
                    .animation(.snappy, value: stock)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)

                Section("Nombre") {
                    TextField("Ej. Chocolates", text: $name)
                        .textInputAutocapitalization(.sentences)
                }
                .listRowBackground(Theme.surface)

                Section("Color del boleto") {
                    HStack(spacing: 0) {
                        ForEach(TicketStock.allCases) { item in
                            Button {
                                stock = item
                            } label: {
                                Circle()
                                    .fill(item.paper)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if stock == item {
                                            Image(systemName: "checkmark")
                                                .font(.footnote.weight(.heavy))
                                                .foregroundStyle(item.ink)
                                        }
                                    }
                                    .padding(4)
                                    .overlay(Circle().strokeBorder(stock == item ? item.paper : .clear, lineWidth: 2))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.name)
                            .accessibilityAddTraits(stock == item ? .isSelected : [])
                        }
                    }
                }
                .listRowBackground(Theme.surface)

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
                                            Circle().fill(emoji == item ? stock.paper.opacity(0.35) : Theme.ground)
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
                .listRowBackground(Theme.surface)

                Section("Portada (opcional)") {
                    PhotoPickerField(image: $image, placeholder: "Foto de la categoría")
                }
                .listRowBackground(Theme.surface)

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                        .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .groundBackground()
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
                stock: stock.rawValue,
                image: image,
                ownerUid: uid
            )
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
