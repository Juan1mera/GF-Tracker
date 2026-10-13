import SwiftUI

/// Uno genera un código de 6 caracteres y el otro lo escribe para quedar vinculados.
/// El código se muestra como un boleto: la otra mitad la tiene tu pareja.
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
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vincula a tu pareja")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Theme.ink)
                        Text("Melita es para dos. Uno comparte su boleto y el otro escribe el código; desde ahí cada quien ve la cuenta del otro.")
                            .foregroundStyle(Theme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    step(number: 1, title: "Comparte tu boleto") {
                        if let myCode {
                            inviteTicket(code: myCode)
                            HStack {
                                ShareLink(item: "Únete a mí en Melita con este código: \(myCode)") {
                                    Label("Compartir", systemImage: "square.and.arrow.up")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)

                                Button {
                                    Task { await generate() }
                                } label: {
                                    Label("Otro código", systemImage: "arrow.clockwise")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        } else {
                            Button {
                                Task { await generate() }
                            } label: {
                                Text("Generar mi código").bold().frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }

                    step(number: 2, title: "¿Te pasaron un código?") {
                        TextField("ABC123", text: $codeInput)
                            .font(.folio(34, relativeTo: .title))
                            .kerning(6)
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
                            HStack {
                                if isWorking { ProgressView().tint(.white) }
                                Text("Vincular").bold()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(codeInput.count != 6 || isWorking)
                    }

                    if let errorText {
                        Text(errorText).font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .groundBackground()
            .navigationTitle("Hola, \(session.profile?.name ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salir") { Task { await session.signOut() } }
                }
            }
        }
    }

    private func step<Content: View>(number: Int, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.folio(20, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Theme.tint, in: Circle())
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            content()
        }
    }

    /// El código impreso en un boleto horizontal, con su vigencia en el talón.
    private func inviteTicket(code: String) -> some View {
        let stock = TicketStock.maiz
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Código de pareja")
                    .font(.caption.weight(.semibold))
                    .opacity(0.8)
                Text(code)
                    .font(.folio(46, relativeTo: .largeTitle))
                    .kerning(6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)

            Perforation(axis: .horizontal, color: stock.ink.opacity(0.4))

            VStack(spacing: 0) {
                Text("48")
                    .font(.folio(34, relativeTo: .title))
                Text("horas")
                    .font(.caption2.weight(.semibold))
                    .opacity(0.8)
            }
            .frame(width: 80)
        }
        .frame(height: 104)
        .foregroundStyle(stock.ink)
        .background(stock.paper)
        .clipShape(TicketShape(axis: .horizontal, stubLength: 81, notchRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tu código es \(code.map(String.init).joined(separator: " ")). Válido por 48 horas.")
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
