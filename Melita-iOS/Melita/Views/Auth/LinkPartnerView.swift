import SwiftUI

/// Uno genera un código de 6 caracteres y el otro lo escribe para quedar vinculados.
struct LinkPartnerView: View {
    @Environment(SessionStore.self) private var session

    @State private var generatedCode: String?
    @State private var codeInput = ""
    @State private var isWorking = false
    @State private var errorText: String?

    private var myCode: String? { generatedCode ?? session.profile?.inviteCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.pink.gradient)
                        Text("Vincula a tu pareja")
                            .font(.title.bold())
                        Text("Uno genera un código y el otro lo escribe. Así cada quien ve los registros del otro.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    GroupBox {
                        VStack(spacing: 12) {
                            if let myCode {
                                Text(myCode)
                                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                                    .kerning(6)
                                    .textSelection(.enabled)
                                ShareLink(item: "Únete a mí en Melita con este código: \(myCode)") {
                                    Label("Compartir código", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.borderedProminent)
                                Text("Válido por 48 horas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Generar otro") { Task { await generate() } }
                                    .font(.footnote)
                            } else {
                                Button {
                                    Task { await generate() }
                                } label: {
                                    Label("Generar mi código", systemImage: "wand.and.stars")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } label: {
                        Label("Comparte tu código", systemImage: "1.circle.fill")
                    }

                    GroupBox {
                        VStack(spacing: 12) {
                            TextField("ABC123", text: $codeInput)
                                .font(.title2.monospaced())
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .fieldStyle()
                                .onChange(of: codeInput) { _, newValue in
                                    let clean = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                                    if clean != newValue { codeInput = clean }
                                }
                            Button {
                                Task { await join() }
                            } label: {
                                Text("Vincular").bold().frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(codeInput.count != 6 || isWorking)
                        }
                    } label: {
                        Label("¿Te pasaron un código?", systemImage: "2.circle.fill")
                    }

                    if isWorking { ProgressView() }
                    if let errorText {
                        Text(errorText).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Hola, \(session.profile?.name ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salir") { Task { await session.signOut() } }
                }
            }
        }
    }

    private func generate() async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        do {
            generatedCode = try await session.createInvite()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func join() async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        do {
            try await session.joinCouple(code: codeInput)
            // El listener del perfil detecta el coupleId y cambia de pantalla solo.
        } catch {
            errorText = error.localizedDescription
        }
    }
}
