import SwiftUI

struct MainTabView: View {
    @Environment(SessionStore.self) private var session
    let coupleId: String

    @State private var store: CategoriesStore?
    @State private var captureTab = Int(ProcessInfo.processInfo.environment["DEMO_TAB"] ?? "0") ?? 0 // CAPTURE-HOOK

    var body: some View {
        Group {
            if let store {
                TabView(selection: $captureTab) { // CAPTURE-HOOK
                    CategoryListView(
                        title: "Lo mío",
                        ownerUid: session.uid,
                        isMine: true
                    )
                    .tabItem { Label("Lo mío", systemImage: "ticket.fill") }.tag(0)

                    CategoryListView(
                        title: session.partner?.name ?? "Mi pareja",
                        ownerUid: session.profile?.partnerUid,
                        isMine: false
                    )
                    .tabItem { Label(session.partner?.name ?? "Pareja", systemImage: "heart.fill") }.tag(1)

                    SettingsView()
                        .tabItem { Label("Ajustes", systemImage: "gearshape") }.tag(2)
                }
                .environment(store)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .groundBackground()
            }
        }
        .task(id: coupleId) {
            store = CategoriesStore(coupleId: coupleId)
            if ProcessInfo.processInfo.environment["DEMO_EMAIL"] == nil { await PushService.shared.requestAuthorization() } // CAPTURE-HOOK
        }
    }
}
