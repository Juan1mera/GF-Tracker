import SwiftUI
import PhotosUI

/// Vista previa + botones para tomar foto con la cámara o elegir de la galería.
struct PhotoPickerField: View {
    @Binding var image: UIImage?
    var placeholder: String = "Foto"

    @State private var pickerItem: PhotosPickerItem?
    @State private var showLibrary = false
    @State private var showCamera = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(spacing: 12) {
            Color.clear
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .overlay {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Color(.tertiarySystemFill)
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill").font(.largeTitle)
                                Text(placeholder).font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Estilo .bordered para que cada botón funcione por separado dentro de un Form.
            HStack {
                if cameraAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Cámara", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    showLibrary = true
                } label: {
                    Label("Galería", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)

                if image != nil {
                    Button(role: .destructive) {
                        image = nil
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
        .photosPicker(isPresented: $showLibrary, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let picked = UIImage(data: data) {
                    image = picked
                }
                pickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $image)
                .ignoresSafeArea()
        }
    }
}
