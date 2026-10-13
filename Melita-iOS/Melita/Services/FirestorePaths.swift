import Foundation
import FirebaseFirestore

enum FirestorePaths {
    static var db: Firestore { Firestore.firestore() }

    static func user(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    static func categories(_ coupleId: String) -> CollectionReference {
        db.collection("couples").document(coupleId).collection("categories")
    }

    static func entries(_ coupleId: String, _ categoryId: String) -> CollectionReference {
        categories(coupleId).document(categoryId).collection("entries")
    }

    // Rutas en Firebase Storage
    static func categoryCoverPath(coupleId: String, categoryId: String) -> String {
        "couples/\(coupleId)/categories/\(categoryId)/cover.jpg"
    }

    static func entryPhotoPath(coupleId: String, categoryId: String, entryId: String) -> String {
        "couples/\(coupleId)/categories/\(categoryId)/entries/\(entryId).jpg"
    }
}

enum AppError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}
