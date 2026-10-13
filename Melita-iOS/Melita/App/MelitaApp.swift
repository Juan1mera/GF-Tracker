import SwiftUI

@main
struct MelitaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session: SessionStore

    init() {
        // Firebase debe configurarse antes de crear cualquier store.
        FirebaseBootstrap.configure()
        _session = State(initialValue: SessionStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(.pink)
        }
    }
}
