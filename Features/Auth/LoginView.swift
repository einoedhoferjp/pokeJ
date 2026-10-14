import SwiftUI
import UIKit

/// Anmeldebildschirm mit lokalem Probe-Account.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthStore

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showPassword = false

    private enum Field: Hashable { case user, pass }
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
                    loginCard
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

    private var loginCard: some View {
        VStack(spacing: 16) {
            field(icon: "person.fill") {
                TextField("Benutzername", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
                    .focused($focused, equals: .user)
                    .onSubmit { focused = .pass }
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
                .textContentType(.password)
                .submitLabel(.go)
                .focused($focused, equals: .pass)
                .onSubmit { submit() }
            }

            Toggle("Passwort anzeigen", isOn: $showPassword)
                .font(.footnote)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                submit()
            } label: {
                Label("Anmelden", systemImage: "arrow.right.circle.fill")
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
        if auth.login(username: username, password: password) {
            errorMessage = nil
        } else {
            errorMessage = "Benutzername oder Passwort ist falsch."
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
}
