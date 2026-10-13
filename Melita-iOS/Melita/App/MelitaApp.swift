import SwiftUI
import FirebaseAuth // CAPTURE-HOOK

@main
struct MelitaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session: SessionStore

    init() {
        // Firebase debe configurarse antes de crear cualquier store.
        FirebaseBootstrap.configure()
        _session = State(initialValue: SessionStore())
        // CAPTURE-HOOK
        let env = ProcessInfo.processInfo.environment
        if let email = env["DEMO_EMAIL"], let pw = env["DEMO_PW"] {
            Task { try? await Auth.auth().signIn(withEmail: email, password: pw) }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(Theme.tint)
        }
    }
}
