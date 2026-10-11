# Setup & Entwicklungsumgebung

## 1. Aktuelle Umgebung (geprüft)

| Werkzeug | Status |
|---|---|
| Windows 10 (10.0.19045), i7-6820HQ, 15,3 GB RAM | ✅ |
| VS Code 1.141.0 | ✅ |
| Node v26.8.1 / npm 11.19.0 | ✅ |
| winget 1.29.380 | ✅ |
| git 2.55.0 | ✅ (installiert) |
| iPad (bevorzugt) und iPhone zum Testen | ✅ |
| **Mac / macOS / Xcode / Swift-Toolchain** | ❌ |
| Budget | **kein Budget → nur kostenlose Wege** |

## 2. Die harte Randbedingung

iOS-Apps lassen sich **nur auf macOS** kompilieren, signieren und archivieren
(Xcode, `xcodebuild`, iOS-SDK existieren ausschließlich für macOS). Ein iPad
kann **nicht** bauen — es ist ausschließlich **Testgerät**.

Da kein Mac vorhanden ist **und kein Budget** zur Verfügung steht, ist der
einzige tragfähige Weg:

### Gewählter Weg — GitHub-Actions-macOS-Runner (kostenlos) + Sideloading

1. **Bauen & Testen in der Cloud:** Code auf Windows schreiben → `git push` →
   GitHub-Actions-macOS-Runner kompiliert und führt Unit-Tests aus.
   - **Öffentliches Repo:** kostenlos und ohne Minutenlimit (Standard-Runner).
   - **Privates Repo:** kleines monatliches Aktionsminuten-Budget; macOS zählt
     mit hohem Multiplikator (~10×), praktisch nur wenige Builds/Monat.
   - ⚠️ Trade-off: öffentliches Repo = Quellcode öffentlich sichtbar.
2. **Projektdatei ohne Xcode:** **XcodeGen** erzeugt das `.xcodeproj` in CI aus
   einer `project.yml` (kein Mac zum Erzeugen nötig).
3. **Auf dem iPad installieren (kostenlos):** Unsigned-`.ipa` aus dem CI-Lauf
   per **Sideloadly** (USB, Windows) oder **AltStore/AltServer** mit **freier
   Apple ID** aufs iPad laden. Das ist zulässig und kostenlos, aber:
   - Provisioning-Profil läuft **alle 7 Tage ab** → wöchentlich neu signieren.
   - Max. **3 Apps** pro freier Apple ID, max. **3 Geräte**.
   - **Kein** TestFlight, **kein** App Store ohne bezahltes Developer-Programm.

**Nicht wählbar:** Cloud-Mac-Abo, Mac mini, Apple Developer Program (99 €/Jahr)
— alle kostenpflichtig und damit ausgeschlossen.

## 3. Benötigte Zugangsdaten (kostenlos)

| Zweck | Zugang | Kosten |
|---|---|---|
| Kartendaten/-preise | **kein** Key (TCGdex) | 0 € |
| Cardmarket | **kein** Zugang nötig (Preise über TCGdex) | 0 € |
| Code-Hosting + CI | GitHub-Konto (öffentliches Repo) | 0 € |
| Geräteinstallation | kostenlose **Apple ID** (Personal Team) | 0 € |
| Sideload-Tool | Sideloadly oder AltServer (Windows) | 0 € |
| Backend (Phase 5) | Supabase Free Tier (optional) | 0 € |

**Sicherheit:** Private Keys/Zertifikate **niemals** committen. In CI als
Secrets (Base64) ablegen. Für die freie Gerätesignierung wird **keine**
CI-Signierung benötigt (unsigniert bauen, lokal per Sideload signieren).

## 4. Lokales Setup auf Windows

```powershell
# git (bereits installiert)
git --version

# Sideloadly installieren (für Geräteinstallation, kostenlos)
winget install --id Sideloadly.Sideloadly -e
# AltStore-Alternative: https://altstore.io (AltServer für Windows)
```

## 5. CI-Workflow (Ziel, kostenlos)

```yaml
# .github/workflows/ci.yml (Entwurf – wird in Phase 1 angelegt)
name: CI
on: [push, pull_request]
jobs:
  build-test:
    runs-on: macos-14        # kostenloser Standard-Runner
    steps:
      - uses: actions/checkout@v4
      - run: brew install xcodegen
      - run: xcodegen generate
      - run: xcodebuild build -scheme PokeJ -destination 'generic/platform=iOS Simulator'
      - run: xcodebuild test  -scheme PokeJ -destination 'platform=iOS Simulator,name=iPad (10th generation)'
```

## 6. Geräteinstallation ohne Developer-Programm

1. Lokal ein **unsigniertes** `.ipa`/`.app` aus dem CI erzeugen (Artifact).
2. iPad per USB anschließen, in Sideloadly die Apple ID eintragen.
3. App aufs iPad installieren; Profil ist 7 Tage gültig → wöchentlich neu laden.
4. Kameratests laufen auf dem echten iPad (der Simulator hat keine Kamera).

## 7. Kostenübersicht

| Posten | Kosten | Kategorie |
|---|---|---|
| TCGdex API | 0 € | frei |
| Apple Vision / Core Image / SwiftData | 0 € | frei |
| OpenCV / Tesseract | 0 € | frei (optional) |
| GitHub-Actions-macOS (public repo) | 0 € | frei |
| Sideloadly / AltStore + freie Apple ID | 0 € | frei |
| Supabase Free Tier | 0 € | frei (optional) |
| Testgerät iPad/iPhone | vorhanden | vorhanden |
| Apple Developer Program | 99 €/Jahr | **nicht möglich (Budget)** |
| Cloud-Mac / Mac mini | >0 € | **nicht möglich (Budget)** |
| Rechtliche Prüfung Bildrechte | offen | ungeklärt |

## 8. Festgelegte & offene Entscheidungen

- ✅ Deployment-Target: **iOS 17+** (ermöglicht SwiftData).
- ✅ Build-Weg: **GitHub-Actions-CI + Sideloading (kostenlos)**.
- ⬜ Bundle-ID festlegen (Vorschlag: `local.pokej.app`).
- ⬜ Repository öffentlich oder privat? (öffentlich = kostenlos/unbegrenzt).
