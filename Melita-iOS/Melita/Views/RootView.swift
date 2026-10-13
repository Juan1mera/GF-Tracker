import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ProgressView("Cargando…")
            case .signedOut:
                AuthView()
            case .needsPartner:
                LinkPartnerView()
            case .ready(let coupleId):
                MainTabView(coupleId: coupleId)
                    .id(coupleId)
            }
        }
        .animation(.default, value: session.phase)
        .alert(
            "Algo salió mal",
            isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { if !$0 { session.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(session.errorMessage ?? "")
        }
    }
}
