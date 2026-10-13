import SwiftUI

/// Cuadrícula de categorías de una persona (tú o tu pareja).
struct CategoryListView: View {
    @Environment(SessionStore.self) private var session
    @Environment(CategoriesStore.self) private var store

    let title: String
    let ownerUid: String?
    let isMine: Bool

    @State private var showNewCategory = false

    private let columns = [GridItem(.adaptive(minimum: 155), spacing: 16)]

    var body: some View {
        NavigationStack {
            let items = store.categories(ownedBy: ownerUid)
            ScrollView {
                if store.isLoaded && items.isEmpty {
                    EmptyStateView(
                        systemImage: isMine ? "square.grid.2x2" : "hourglass",
                        title: isMine ? "Aún no tienes categorías" : "Tu pareja aún no tiene categorías",
                        message: isMine
                            ? "Crea una, por ejemplo “Chocolates 🍫”, y cada vez que comas uno agrégalo con foto."
                            : "Cuando cree una, te llegará una notificación."
                    )
                    .padding(.top, 80)

                    if isMine {
                        Button {
                            showNewCategory = true
                        } label: {
                            Label("Crear categoría", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { category in
                        NavigationLink(value: category) {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationDestination(for: TrackerCategory.self) { category in
                CategoryDetailView(category: category, canEdit: isMine)
            }
            .toolbar {
                if isMine {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showNewCategory = true
                        } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                        .accessibilityLabel("Nueva categoría")
                    }
                }
            }
            .sheet(isPresented: $showNewCategory) {
                NewCategoryView()
                    .environment(session)
                    .environment(store)
            }
        }
    }
}
