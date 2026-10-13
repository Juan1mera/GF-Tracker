import SwiftUI

struct CategoryDetailView: View {
    @Environment(SessionStore.self) private var session
    @Environment(CategoriesStore.self) private var categoriesStore
    @Environment(\.dismiss) private var dismiss

    let category: TrackerCategory
    let canEdit: Bool

    @State private var store: EntriesStore?
    @State private var showNewEntry = false
    @State private var confirmDelete = false
    @State private var errorText: String?

    /// Versión más reciente de la categoría (el contador lo actualiza la Cloud Function).
    private var live: TrackerCategory {
        categoriesStore.categories.first { $0.id == category.id } ?? category
    }

    var body: some View {
        List {
            Section {
                header
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("Registros") {
                if let store {
                    if store.isLoaded && store.entries.isEmpty {
                        Text(canEdit ? "Toca + para agregar el primero." : "Todavía no hay registros.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.entries) { entry in
                        EntryRow(entry: entry)
                            .deleteDisabled(!canEdit)
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { store.entries[$0] }
                        Task {
                            for entry in toDelete { try? await store.delete(entry) }
                        }
                    }
                } else {
                    ProgressView()
                }
            }

            if let errorText {
                Text(errorText).foregroundStyle(.red)
            }
        }
        .navigationTitle(live.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                    .accessibilityLabel("Nuevo registro")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Borrar categoría", systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            if let store {
                NewEntryView(category: live, store: store)
                    .environment(session)
            }
        }
        .confirmationDialog("¿Borrar “\(live.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Borrar con todos sus registros", role: .destructive) {
                Task { await deleteCategory() }
            }
        } message: {
            Text("Esto no se puede deshacer.")
        }
        .task {
            if store == nil, let id = category.id {
                store = EntriesStore(coupleId: categoriesStore.coupleId, categoryId: id)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 200)
                .overlay { RemoteImage(url: live.photoURL, placeholderEmoji: live.emoji) }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 10) {
                StatPill(value: max(live.entryCount, store?.entries.count ?? 0), label: "Total")
                StatPill(value: store?.todayCount ?? 0, label: "Hoy")
                StatPill(value: store?.weekCount ?? 0, label: "Semana")
                StatPill(value: store?.monthCount ?? 0, label: "Mes")
            }
        }
        .padding(.vertical, 8)
    }

    private func deleteCategory() async {
        do {
            try await categoriesStore.deleteCategory(live)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
