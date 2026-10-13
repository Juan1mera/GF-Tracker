import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var session

    @State private var name = ""
    @State private var confirmUnlink = false
    @State private var errorText: String?

    private var nameChanged: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed != session.profile?.displayName
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                Section {
                    HStack(spacing: 14) {
                        MelitaMark().frame(width: 64)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(session.profile?.name ?? "Tú") + \(session.partner?.name ?? "…")")
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            Text("Llevan la cuenta juntos")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Tu perfil") {
                    TextField("Nombre", text: $name)
                    if nameChanged {
                        Button("Guardar nombre") { Task { await saveName() } }
                    }
                    LabeledContent("Correo", value: session.profile?.email ?? "—")
                }

                Section("Pareja") {
                    LabeledContent("Vinculado con", value: session.partner?.name ?? "…")
                    Button("Desvincular", role: .destructive) { confirmUnlink = true }
                }

                Section {
                    Button("Activar notificaciones") {
                        Task { await PushService.shared.requestAuthorization() }
                    }
                    Button("Abrir ajustes del iPhone") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Notificaciones")
                } footer: {
                    Text("Te avisamos cada vez que tu pareja arranca un boleto o crea una categoría.")
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        Task { await session.signOut() }
                    }
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .groundBackground()
            .navigationTitle("Ajustes")
            .onAppear { name = session.profile?.displayName ?? "" }
            .confirmationDialog("¿Desvincular a tu pareja?", isPresented: $confirmUnlink, titleVisibility: .visible) {
                Button("Desvincular", role: .destructive) {
                    Task { await unlink() }
                }
            } message: {
                Text("Ya no podrán ver los registros del otro. Los datos no se borran.")
            }
        }
    }

    private func saveName() async {
        do {
            try await session.updateDisplayName(name.trimmingCharacters(in: .whitespaces))
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func unlink() async {
        do {
            try await session.unlinkCouple()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
