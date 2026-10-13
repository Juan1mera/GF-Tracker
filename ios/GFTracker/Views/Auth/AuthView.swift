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
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.pink.gradient)
                    Text("GF Tracker")
                        .font(.largeTitle.bold())
                    Text("Registren juntos las cosas que hacen")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 48)

                Picker("Modo", selection: $isRegister) {
                    Text("Entrar").tag(false)
                    Text("Crear cuenta").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if isRegister {
                        TextField("Tu nombre", text: $name)
                            .textContentType(.name)
                            .fieldStyle()
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
                    Text(errorText).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                if let infoText {
                    Text(infoText).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

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
                    .font(.footnote)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
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
