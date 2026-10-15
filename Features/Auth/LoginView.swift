import SwiftUI
import UIKit

/// Anmelde- und Registrierungsbildschirm für lokale Konten.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthStore

    @State private var mode: Mode = .login
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showPassword = false

    private enum Mode: String, CaseIterable, Identifiable {
        case login, register

        var id: String { rawValue }

        var title: String {
            switch self {
            case .login: return "Anmelden"
            case .register: return "Konto erstellen"
            }
        }
    }

    private enum Field: Hashable { case user, name, pass }
    @FocusState private var focused: Field?

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    authCard
                    if mode == .login { demoHintCard }
                }
                .padding(24)
                .frame(maxWidth: 480)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            BrandLogo(size: 88)
            Text("PokéJ")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(AppTheme.ink)
            Text("Kartenscanner & Sammlung")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 40)
    }

    private var authCard: some View {
        VStack(spacing: 18) {
            Picker("Modus", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in errorMessage = nil }

            field(icon: "person.fill") {
                TextField("Benutzername", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
                    .focused($focused, equals: .user)
                    .onSubmit { focused = mode == .register ? .name : .pass }
            }

            if mode == .register {
                field(icon: "person.text.rectangle") {
                    TextField("Anzeigename (optional)", text: $displayName)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .focused($focused, equals: .name)
                        .onSubmit { focused = .pass }
                }
            }

            field(icon: "lock.fill") {
                Group {
                    if showPassword {
                        TextField("Passwort", text: $password)
                    } else {
                        SecureField("Passwort", text: $password)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(mode == .register ? .newPassword : .password)
                .submitLabel(.go)
                .focused($focused, equals: .pass)
                .onSubmit { submit() }
            }

            Toggle("Passwort anzeigen", isOn: $showPassword)
                .font(.footnote)
                .toggleStyle(ModernToggleStyle())

            if mode == .register {
                Text("Deine Sammlung und Punkte werden lokal für dieses Konto gespeichert.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }

            Button {
                submit()
            } label: {
                Label(mode == .login ? "Anmelden" : "Konto erstellen", systemImage: "arrow.right.circle.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        .card3D(maxTilt: 5, pressedScale: 1.01)
    }

    private var demoHintCard: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(AuthService.demoHint, id: \.username) { hint in
                    HStack {
                        Text(hint.username)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                        Text(hint.password)
                            .monospaced()
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .font(.caption)
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Demo-Konten", systemImage: "person.2.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
    }

    private func field<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 22)
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(AppTheme.elevatedAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
        }
    }

    private func submit() {
        focused = nil
        guard canSubmit else { return }
        switch mode {
        case .login:
            if auth.login(username: username, password: password) {
                errorMessage = nil
            } else {
                errorMessage = "Benutzername oder Passwort ist falsch."
            }
        case .register:
            if let problem = AuthService.registrationError(username: username, password: password) {
                errorMessage = problem
            } else if auth.register(username: username, password: password, displayName: displayName) {
                errorMessage = nil
            } else {
                errorMessage = "Konto konnte nicht erstellt werden."
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
}