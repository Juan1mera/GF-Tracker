import SwiftUI

struct MainTabView: View {
    @Environment(SessionStore.self) private var session
    let coupleId: String

    @State private var store: CategoriesStore?

    var body: some View {
        Group {
            if let store {
                TabView {
                    CategoryListView(
                        title: "Lo mío",
                        ownerUid: session.uid,
                        isMine: true
                    )
                    .tabItem { Label("Lo mío", systemImage: "heart.fill") }

                    CategoryListView(
                        title: session.partner?.name ?? "Mi pareja",
                        ownerUid: session.profile?.partnerUid,
                        isMine: false
                    )
                    .tabItem { Label(session.partner?.name ?? "Pareja", systemImage: "heart.circle") }

                    SettingsView()
                        .tabItem { Label("Ajustes", systemImage: "gearshape") }
                }
                .environment(store)
            } else {
                ProgressView()
            }
        }
        .task(id: coupleId) {
            store = CategoriesStore(coupleId: coupleId)
            await PushService.shared.requestAuthorization()
        }
    }
}
