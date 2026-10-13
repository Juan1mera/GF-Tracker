import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

/// Estado global: quién inició sesión, su perfil, su pareja y en qué fase está la app.
@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case loading
        case signedOut
        case needsPartner
        case ready(coupleId: String)
    }

    private(set) var phase: Phase = .loading
    private(set) var profile: AppUser?
    private(set) var partner: AppUser?
    var errorMessage: String?

    var uid: String? { Auth.auth().currentUser?.uid }

    @ObservationIgnored private var authHandle: AuthStateDidChangeListenerHandle?
    @ObservationIgnored private var profileListener: ListenerRegistration?
    @ObservationIgnored private var partnerListener: ListenerRegistration?
    @ObservationIgnored private var listeningPartnerUid: String?
    @ObservationIgnored private var pendingDisplayName: String?
    private let functions = Functions.functions(region: AppConfig.functionsRegion)

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let uid = user?.uid
            let email = user?.email
            Task { @MainActor in
                self?.handleAuthChange(uid: uid, email: email)
            }
        }
    }

    // MARK: - Escucha de perfil

    private func handleAuthChange(uid: String?, email: String?) {
        profileListener?.remove()
        profileListener = nil
        stopPartnerListener()
        profile = nil

        guard let uid else {
            phase = .signedOut
            return
        }
        phase = .loading

        profileListener = FirestorePaths.user(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                if self.uid != nil { self.errorMessage = error.localizedDescription }
                return
            }
            guard let snapshot else { return }

            // Primer inicio de sesión: creamos el perfil.
            if !snapshot.exists || snapshot.get("displayName") == nil {
                let name = self.pendingDisplayName
                    ?? email?.components(separatedBy: "@").first
                    ?? "Yo"
                FirestorePaths.user(uid).setData(["displayName": name, "email": email ?? ""], merge: true)
                return
            }

            do {
                self.apply(try snapshot.data(as: AppUser.self))
            } catch {
                self.errorMessage = "No se pudo leer tu perfil: \(error.localizedDescription)"
            }
        }
    }

    private func apply(_ user: AppUser) {
        profile = user
        if let coupleId = user.coupleId, let partnerUid = user.partnerUid {
            listenToPartner(partnerUid)
            phase = .ready(coupleId: coupleId)
        } else {
            stopPartnerListener()
            phase = .needsPartner
        }
        Task { await PushService.shared.syncToken() }
    }

    private func listenToPartner(_ partnerUid: String) {
        guard listeningPartnerUid != partnerUid else { return }
        stopPartnerListener()
        listeningPartnerUid = partnerUid
        partnerListener = FirestorePaths.user(partnerUid).addSnapshotListener { [weak self] snapshot, _ in
            self?.partner = try? snapshot?.data(as: AppUser.self)
        }
    }

    private func stopPartnerListener() {
        partnerListener?.remove()
        partnerListener = nil
        listeningPartnerUid = nil
        partner = nil
    }

    // MARK: - Autenticación

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(name: String, email: String, password: String) async throws {
        pendingDisplayName = name
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let change = result.user.createProfileChangeRequest()
        change.displayName = name
        try? await change.commitChanges()
        try await FirestorePaths.user(result.user.uid).setData(["displayName": name, "email": email], merge: true)
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() async {
        await PushService.shared.removeTokenForCurrentUser()
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateDisplayName(_ name: String) async throws {
        guard let uid else { return }
        try await FirestorePaths.user(uid).updateData(["displayName": name])
    }

    // MARK: - Pareja (Cloud Functions)

    func createInvite() async throws -> String {
        let result = try await functions.httpsCallable("createInvite").call()
        guard let data = result.data as? [String: Any], let code = data["code"] as? String else {
            throw AppError.message("Respuesta inesperada del servidor.")
        }
        return code
    }

    func joinCouple(code: String) async throws {
        _ = try await functions.httpsCallable("joinCouple").call(["code": code])
    }

    func unlinkCouple() async throws {
        _ = try await functions.httpsCallable("unlinkCouple").call()
    }
}
