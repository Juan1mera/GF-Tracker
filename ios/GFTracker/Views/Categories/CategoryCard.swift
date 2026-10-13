import SwiftUI

struct CategoryCard: View {
    let category: TrackerCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 120)
                .overlay { RemoteImage(url: category.photoURL, placeholderEmoji: category.emoji) }
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(category.entryCount)")
                        .font(.title2.bold())
                        .foregroundStyle(.pink)
                    Text(category.entryCount == 1 ? "registro" : "registros")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(lastEntryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var lastEntryText: String {
        guard let last = category.lastEntryAt?.dateValue() else { return "Sin registros aún" }
        return "Último: " + last.formatted(.relative(presentation: .named))
    }
}
