import SwiftUI

struct EntryRow: View {
    let entry: TrackerEntry
    @State private var showPhoto = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if entry.photoURL != nil {
                Color.clear
                    .frame(width: 64, height: 64)
                    .overlay { RemoteImage(url: entry.photoURL) }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture { showPhoto = true }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.note.isEmpty ? "Sin descripción" : entry.note)
                    .foregroundStyle(entry.note.isEmpty ? .secondary : .primary)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .fullScreenCover(isPresented: $showPhoto) {
            PhotoViewer(url: entry.photoURL, caption: entry.note)
        }
    }
}

struct PhotoViewer: View {
    let url: String?
    let caption: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                RemoteImage(url: url, contentMode: .fit)
                Spacer()
                if !caption.isEmpty {
                    Text(caption)
                        .foregroundStyle(.white)
                        .padding()
                }
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }
}
