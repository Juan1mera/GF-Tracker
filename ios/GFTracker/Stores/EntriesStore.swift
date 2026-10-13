import UIKit
import Observation
import FirebaseFirestore

/// Registros de una categoría, en tiempo real (más recientes primero).
@MainActor
@Observable
final class EntriesStore {
    let coupleId: String
    let categoryId: String
    private(set) var entries: [TrackerEntry] = []
    private(set) var isLoaded = false
    var errorMessage: String?

    @ObservationIgnored private var listener: ListenerRegistration?

    init(coupleId: String, categoryId: String) {
        self.coupleId = coupleId
        self.categoryId = categoryId
        listener = FirestorePaths.entries(coupleId, categoryId)
            .order(by: "createdAt", descending: true)
            .limit(to: 500)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.entries = snapshot?.documents.compactMap { try? $0.data(as: TrackerEntry.self) } ?? []
                self.isLoaded = true
            }
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Estadísticas

    private func count(sameAs granularity: Calendar.Component) -> Int {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: granularity) }.count
    }

    var todayCount: Int { count(sameAs: .day) }
    var weekCount: Int { count(sameAs: .weekOfYear) }
    var monthCount: Int { count(sameAs: .month) }

    // MARK: - Acciones

    func addEntry(note: String, image: UIImage?, createdBy uid: String) async throws {
        let ref = FirestorePaths.entries(coupleId, categoryId).document()
        var photoURL: String?
        if let image {
            let path = FirestorePaths.entryPhotoPath(coupleId: coupleId, categoryId: categoryId, entryId: ref.documentID)
            photoURL = try await StorageService.uploadJPEG(image, to: path).absoluteString
        }
        let data = try Firestore.Encoder().encode(TrackerEntry(note: note, photoURL: photoURL, createdBy: uid))
        try await ref.setData(data)
    }

    /// La Cloud Function `onEntryDeleted` descuenta el contador y borra la foto.
    func delete(_ entry: TrackerEntry) async throws {
        guard let id = entry.id else { return }
        try await FirestorePaths.entries(coupleId, categoryId).document(id).delete()
    }
}
