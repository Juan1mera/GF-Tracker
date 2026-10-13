import Foundation
import FirebaseFirestore

/// users/{uid}
struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String?
    var email: String?
    var coupleId: String?
    var partnerUid: String?
    var inviteCode: String?

    var name: String { displayName ?? "Sin nombre" }
}

/// couples/{coupleId}/categories/{categoryId}
/// (Se llama TrackerCategory porque `Category` choca con un tipo de Objective-C.)
struct TrackerCategory: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var emoji: String?
    var photoURL: String?
    /// Color del boleto (índice de `TicketStock`). Opcional para categorías anteriores.
    var stock: Int?
    var ownerUid: String
    var entryCount: Int
    @ServerTimestamp var createdAt: Timestamp?
    var lastEntryAt: Timestamp?

    init(name: String, emoji: String?, photoURL: String?, stock: Int?, ownerUid: String) {
        self.name = name
        self.emoji = emoji
        self.photoURL = photoURL
        self.stock = stock
        self.ownerUid = ownerUid
        self.entryCount = 0
    }

    var title: String {
        if let emoji, !emoji.isEmpty { return "\(emoji) \(name)" }
        return name
    }

    static func == (lhs: TrackerCategory, rhs: TrackerCategory) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// couples/{coupleId}/categories/{categoryId}/entries/{entryId}
struct TrackerEntry: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var note: String
    var photoURL: String?
    var createdBy: String
    @ServerTimestamp var createdAt: Timestamp?

    init(note: String, photoURL: String?, createdBy: String) {
        self.note = note
        self.photoURL = photoURL
        self.createdBy = createdBy
    }

    /// Mientras el servidor no confirma la escritura, createdAt es nil: usamos "ahora".
    var date: Date { createdAt?.dateValue() ?? Date() }

    static func == (lhs: TrackerEntry, rhs: TrackerEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
