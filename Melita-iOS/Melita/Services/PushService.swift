import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

/// Guarda el token FCM del dispositivo en users/{uid}.fcmTokens para que la
/// Cloud Function pueda notificar a la pareja.
@MainActor
final class PushService {
    static let shared = PushService()

    private(set) var fcmToken: String?
    private var lastSynced: String?

    private init() {}

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            UIApplication.shared.registerForRemoteNotifications()
        }
        try? await center.setBadgeCount(0)
    }

    func updateToken(_ token: String?) {
        fcmToken = token
        Task { await syncToken() }
    }

    /// Se llama cuando cambia el token o cuando el perfil del usuario ya existe.
    func syncToken() async {
        guard let uid = Auth.auth().currentUser?.uid, let token = fcmToken else { return }
        let key = "\(uid)|\(token)"
        guard key != lastSynced else { return }
        do {
            try await FirestorePaths.user(uid).updateData(["fcmTokens": FieldValue.arrayUnion([token])])
            lastSynced = key
        } catch {
            // El perfil aún no existe; SessionStore volverá a llamar cuando se cree.
        }
    }

    /// Al cerrar sesión, este iPhone deja de recibir notificaciones de esa cuenta.
    func removeTokenForCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid, let token = fcmToken else { return }
        try? await FirestorePaths.user(uid).updateData(["fcmTokens": FieldValue.arrayRemove([token])])
        lastSynced = nil
    }
}
