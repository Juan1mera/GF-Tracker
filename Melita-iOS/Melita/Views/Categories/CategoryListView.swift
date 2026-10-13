import SwiftUI

/// Los boletos de una persona (tú o tu pareja), con el marcador entre los dos arriba.
struct CategoryListView: View {
    @Environment(SessionStore.self) private var session
    @Environment(CategoriesStore.self) private var store

    let title: String
    let ownerUid: String?
    let isMine: Bool

    @State private var showNewCategory = false
    @State private var capturePath: [TrackerCategory] = [] // CAPTURE-HOOK

    private let columns = [GridItem(.adaptive(minimum: 158), spacing: 12)]

    private var partnerName: String { session.partner?.name ?? "tu pareja" }

    private func total(for uid: String?) -> Int {
        store.categories(ownedBy: uid).reduce(0) { $0 + $1.entryCount }
    }

    var body: some View {
        NavigationStack(path: $capturePath) { // CAPTURE-HOOK
            let items = store.categories(ownedBy: ownerUid)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    scoreboard(items: items)

                    if store.isLoaded && items.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { category in
                                NavigationLink(value: category) {
                                    CategoryCard(category: category)
                                }
                                .buttonStyle(TicketButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .groundBackground()
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
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Nueva categoría")
                    }
                }
            }
            .onChange(of: items.count) { _, _ in // CAPTURE-HOOK
                let env = ProcessInfo.processInfo.environment
                if isMine, env["DEMO_SCREEN"] == "detail", capturePath.isEmpty, let first = items.first(where: { $0.name == "Chocolates" }) { capturePath = [first] }
                if isMine, env["DEMO_SCREEN"] == "newcat" { showNewCategory = true }
            }
            .sheet(isPresented: $showNewCategory) {
                NewCategoryView()
                    .environment(session)
                    .environment(store)
            }
        }
    }

    // MARK: - Marcador

    private func scoreboard(items: [TrackerCategory]) -> some View {
        let mine = total(for: session.uid)
        let theirs = total(for: session.profile?.partnerUid)
        let activeToday = items.filter(\.touchedToday).count

        return VStack(alignment: .leading, spacing: 12) {
            Text(scoreSentence(mine: mine, theirs: theirs))
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ScoreStrip(cells: [
                .init(value: mine, label: "Tú", highlighted: mine > theirs),
                .init(value: theirs, label: session.partner?.name ?? "Pareja", highlighted: theirs > mine),
                .init(value: activeToday, label: "Activas hoy"),
            ])
        }
    }

    private func scoreSentence(mine: Int, theirs: Int) -> String {
        if mine == 0 && theirs == 0 {
            return isMine ? "Cada registro arranca un boleto. Empieza tú." : "Todavía nadie ha arrancado un boleto."
        }
        if isMine {
            if mine > theirs { return "Vas \(mine) a \(theirs) contra \(partnerName)." }
            if mine < theirs { return "\(partnerName) te gana \(theirs) a \(mine)." }
            return "Empate a \(mine) con \(partnerName)."
        } else {
            if theirs > mine { return "\(partnerName) va \(theirs) a \(mine) contra ti." }
            if theirs < mine { return "Le ganas \(mine) a \(theirs)." }
            return "Empate a \(mine)."
        }
    }

    // MARK: - Vacío

    private var emptyState: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text(isMine ? "Tu primer boleto" : "\(partnerName) aún no tiene boletos")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(isMine
                     ? "Crea una categoría, por ejemplo «Chocolates 🍫», y cada vez que te comas uno arranca un boleto con foto."
                     : "Te avisaremos cuando cree su primera categoría.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            if isMine {
                Button {
                    showNewCategory = true
                } label: {
                    Text("Crear categoría").bold().frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            TicketShape(stubLength: 0, notchRadius: 0)
                .strokeBorderDashed(color: Theme.perforation)
        }
        .padding(.top, 8)
    }
}

/// Presión táctil del boleto: se hunde un poco, sin rebote.
struct TicketButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

private extension Shape {
    func strokeBorderDashed(color: Color) -> some View {
        stroke(color, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
    }
}
