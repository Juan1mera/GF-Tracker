import UIKit
import Observation
import FirebaseFirestore

/// Escucha en tiempo real todas las categorías de la pareja (las tuyas y las de tu pareja).
@MainActor
@Observable
final class CategoriesStore {
    let coupleId: String
    private(set) var categories: [TrackerCategory] = []
    private(set) var isLoaded = false
    var errorMessage: String?

    @ObservationIgnored private var listener: ListenerRegistration?

    init(coupleId: String) {
        self.coupleId = coupleId
        listener = FirestorePaths.categories(coupleId)
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.categories = snapshot?.documents.compactMap { try? $0.data(as: TrackerCategory.self) } ?? []
                self.isLoaded = true
            }
    }

    deinit {
        listener?.remove()
    }

    func categories(ownedBy uid: String?) -> [TrackerCategory] {
        guard let uid else { return [] }
        return categories.filter { $0.ownerUid == uid }
    }

    func createCategory(name: String, emoji: String?, stock: Int, image: UIImage?, ownerUid: String) async throws {
        let ref = FirestorePaths.categories(coupleId).document()
        var photoURL: String?
        if let image {
            let path = FirestorePaths.categoryCoverPath(coupleId: coupleId, categoryId: ref.documentID)
            photoURL = try await StorageService.uploadJPEG(image, to: path, maxDimension: 1200).absoluteString
        }
        let category = TrackerCategory(name: name, emoji: emoji, photoURL: photoURL, stock: stock, ownerUid: ownerUid)
        let data = try Firestore.Encoder().encode(category)
        try await ref.setData(data)
    }

    /// Borra la categoría. La Cloud Function `onCategoryDeleted` borra sus registros y fotos.
    func deleteCategory(_ category: TrackerCategory) async throws {
        guard let id = category.id else { return }
        try await FirestorePaths.categories(coupleId).document(id).delete()
    }
}
