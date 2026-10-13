import SwiftUI

struct AuthView: View {
    @Environment(SessionStore.self) private var session

    @State private var isRegister = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorText: String?
    @State private var infoText: String?

    private var canSubmit: Bool {
        let base = email.contains("@") && password.count >= 6
        return isRegister ? base && !name.trimmingCharacters(in: .whitespaces).isEmpty : base
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 18) {
                    MelitaMark()
                        .frame(width: 132)
                        .padding(.leading, -6)
                    Text("melita")
                        .font(.folio(64, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, -10)
                    Text("Lleven la cuenta de las pequeñas cosas, juntos. Cada registro arranca un boleto y tu pareja lo ve al instante.")
                        .font(.body)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    Picker("Modo", selection: $isRegister.animation(.snappy)) {
                        Text("Entrar").tag(false)
                        Text("Crear cuenta").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    if isRegister {
                        TextField("Tu nombre", text: $name)
                            .textContentType(.name)
                            .fieldStyle()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    TextField("Correo", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fieldStyle()
                    SecureField("Contraseña (mínimo 6)", text: $password)
                        .textContentType(isRegister ? .newPassword : .password)
                        .fieldStyle()
                }

                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }
                if let infoText {
                    Text(infoText).font(.footnote).foregroundStyle(Theme.inkSecondary)
                }

                VStack(spacing: 14) {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isWorking { ProgressView().tint(.white) }
                            Text(isRegister ? "Crear cuenta" : "Entrar").bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canSubmit || isWorking)

                    if !isRegister {
                        Button("¿Olvidaste tu contraseña?") {
                            Task { await resetPassword() }
                        }
                        .font(.footnote.weight(.semibold))
                        .frame(minHeight: 44)
                    }
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .groundBackground()
    }

    private func submit() async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        let cleanEmail = email.trimmingCharacters(in: .whitespaces)
        do {
            if isRegister {
                try await session.signUp(name: name.trimmingCharacters(in: .whitespaces), email: cleanEmail, password: password)
            } else {
                try await session.signIn(email: cleanEmail, password: password)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func resetPassword() async {
        guard email.contains("@") else {
            errorText = "Escribe tu correo arriba primero."
            return
        }
        do {
            try await session.sendPasswordReset(email: email.trimmingCharacters(in: .whitespaces))
            infoText = "Te enviamos un correo para restablecer la contraseña."
        } catch {
            errorText = error.localizedDescription
        }
    }
}
