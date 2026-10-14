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
            AppTheme.brandGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    authCard
                    if mode == .login { demoHintCard }
                }
                .padding(24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            BrandLogo(size: 92)
            Text("PokéJ")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Kartenscanner & Sammlung")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var authCard: some View {
        VStack(spacing: 16) {
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

            if mode == .register {
                Text("Deine Sammlung und Punkte werden lokal für dieses Konto gespeichert.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.gold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                submit()
            } label: {
                Label(mode == .login ? "Anmelden" : "Konto erstellen", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 22, y: 12)
        .card3D(maxTilt: 6, pressedScale: 1.01)
    }

    private var demoHintCard: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(AuthService.demoHint, id: \.username) { hint in
                    HStack {
                        Text(hint.username)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(hint.password)
                            .monospaced()
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Demo-Konten", systemImage: "person.2.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func field<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22)
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.surfaceStroke, lineWidth: 1))
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
