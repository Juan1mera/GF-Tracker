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

    private var total: Int { max(live.entryCount, store?.entries.count ?? 0) }

    var body: some View {
        List {
            Section {
                header
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                if let store {
                    if store.isLoaded && store.entries.isEmpty {
                        Text(canEdit ? "Aún no arrancas ningún boleto aquí." : "Todavía no hay registros.")
                            .foregroundStyle(Theme.inkSecondary)
                            .listRowBackground(Theme.surface)
                    }
                    ForEach(Array(store.entries.enumerated()), id: \.element.id) { index, entry in
                        EntryRow(entry: entry, serial: total - index, stock: live.ticketStock)
                            .deleteDisabled(!canEdit)
                            .listRowBackground(Theme.surface)
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { store.entries[$0] }
                        Task {
                            for entry in toDelete { try? await store.delete(entry) }
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            } header: {
                Text("Boletos")
            }

            if let errorText {
                Text(errorText)
                    .foregroundStyle(.red)
                    .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .groundBackground()
        .navigationTitle(live.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Borrar categoría", systemImage: "trash", role: .destructive) {
                            confirmDelete = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Más opciones")
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            if let store {
                NewEntryView(category: live, serial: total + 1, store: store)
                    .environment(session)
            }
        }
        .confirmationDialog("¿Borrar «\(live.name)»?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Borrar con todos sus boletos", role: .destructive) {
                Task { await deleteCategory() }
            }
        } message: {
            Text("Esto no se puede deshacer.")
        }
        .sensoryFeedback(.success, trigger: total)
        .task {
            if store == nil, let id = category.id {
                store = EntriesStore(coupleId: categoriesStore.coupleId, categoryId: id)
            }
            if ProcessInfo.processInfo.environment["DEMO_SHEET"] == "entry" { showNewEntry = true } // CAPTURE-HOOK
        }
    }

    // MARK: - Encabezado

    private var header: some View {
        let stock = live.ticketStock
        return VStack(spacing: 12) {
            // Boleto horizontal: cuerpo con portada, talón con el total.
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        Text(live.emoji?.isEmpty == false ? live.emoji! : "🎟️")
                            .font(.system(size: 34))
                        Spacer()
                        if live.photoURL != nil {
                            // Portada como comprobante; el sello HOY cae encima.
                            RemoteImage(url: live.photoURL, placeholderEmoji: live.emoji, paper: stock.paper)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(alignment: .bottomLeading) {
                                    if live.touchedToday {
                                        Stamp(text: "HOY", color: stock.ink)
                                            .background(stock.paper, in: RoundedRectangle(cornerRadius: 4))
                                            .offset(x: -14, y: 6)
                                    }
                                }
                        } else if live.touchedToday {
                            Stamp(text: "HOY", color: stock.ink)
                        }
                    }
                    Spacer(minLength: 0)
                    Text(live.name)
                        .font(.title2.bold())
                        .lineLimit(2)
                    Text(lastEntryText)
                        .font(.footnote.weight(.medium))
                        .opacity(0.85)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Perforation(axis: .horizontal, color: stock.ink.opacity(0.45))

                VStack(spacing: 0) {
                    Text(total, format: .number)
                        .font(.folio(64, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText(value: Double(total)))
                    Text(total == 1 ? "boleto" : "boletos")
                        .font(.caption.weight(.semibold))
                        .opacity(0.85)
                }
                .frame(width: 112)
                .padding(.vertical, 16)
            }
            .frame(height: 176)
            .foregroundStyle(stock.ink)
            .background(stock.paper)
            .clipShape(TicketShape(axis: .horizontal, stubLength: 113, notchRadius: 10))
            .animation(.snappy, value: total)
            .accessibilityElement(children: .combine)

            ScoreStrip(cells: [
                .init(value: store?.todayCount ?? 0, label: "Hoy"),
                .init(value: store?.weekCount ?? 0, label: "Semana"),
                .init(value: store?.monthCount ?? 0, label: "Mes"),
            ])

            if canEdit {
                Button {
                    showNewEntry = true
                } label: {
                    Label("Arrancar boleto Nº \(total + 1)", systemImage: "plus")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var lastEntryText: String {
        guard let last = live.lastEntryAt?.dateValue() else { return "Sin boletos todavía" }
        return "Último " + last.formatted(.relative(presentation: .named))
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
