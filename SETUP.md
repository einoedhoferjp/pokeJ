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
| Code-Hosting + CI | GitHub-Konto (Repo **privat**) | 0 € |
| Geräteinstallation | kostenlose **Apple ID** (Personal Team) | 0 € |
| Sideload-Tool | Sideloadly oder AltServer (Windows) | 0 € |
| Backend (Phase 5) | Supabase Free Tier (optional) | 0 € |

**Sicherheit:** Private Keys/Zertifikate **niemals** committen. In CI als
Secrets (Base64) ablegen. Für die freie Gerätesignierung wird **keine**
CI-Signierung benötigt (unsigniert bauen, lokal per Sideload signieren).

### 3.1 App-Login (Demo)

Die App hat einen **lokalen** Login ohne Server. Die Passwörter sind nur als
gesalzene SHA-256-Hashes im Code (`AuthService`) hinterlegt.

| Benutzername | Passwort | Rolle |
|---|---|---|
| `admin` | `admin` | Administrator |
| `pokefan` | `pikachu` | Pokéfan |
| `test` | `test` | Testkonto |
| `sammler` | `glueckspilz` | Sammler |

> **Hinweis:** Das ist ein **Demo-Schutz**, keine echte Zugriffssicherheit. Für
> Mehrbenutzer/Cloud (Phase 5) wird auf Supabase-Auth umgestellt.

## 4. Lokales Setup auf Windows

```powershell
# git (bereits installiert)
git --version

# Sideloadly installieren (für Geräteinstallation, kostenlos)
winget install --id Sideloadly.Sideloadly -e
# AltStore-Alternative: https://altstore.io (AltServer für Windows)
```

## 5. CI-Workflows

- `.github/workflows/ci.yml`: baut und testet bei jedem Push auf `main`
  (`xcodebuild test`, Simulator **iPhone 16**).
- `.github/workflows/ipa.yml`: erzeugt ein **unsigniertes `.ipa`** als Artefakt.
  Start entweder manuell (GitHub → **Actions → IPA → Run workflow**) oder
  automatisch bei einem Tag `v*`. Das `.ipa` ist zum Sideloaden gedacht (siehe
  Abschnitt 6).

```yaml
# .github/workflows/ci.yml (gekürzt)
name: CI
on: [push, pull_request]
jobs:
  build-test:
    runs-on: macos-14        # kostenloser Standard-Runner
    steps:
      - uses: actions/checkout@v4
      - run: brew install xcodegen
      - run: xcodegen generate
      - run: xcodebuild build -scheme PokeJ -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
      - run: xcodebuild test  -scheme PokeJ -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' CODE_SIGNING_ALLOWED=NO
```

## 6. Geräteinstallation ohne Developer-Programm (Sideloadly)

> Vollständige Schritt-für-Schritt-Anleitung (auch mit **AltStore** und
> **3uTools** als Alternativen zu Sideloadly): siehe **`INSTALL.md`**.

1. Auf GitHub den Workflow **IPA** starten (Actions → *IPA* → **Run workflow**)
   oder einen Tag `v*` pushen.
2. Nach dem Lauf das Artefakt **`PokeJ-unsigned-ipa`** herunterladen und
   entpacken → `PokeJ.ipa`.
3. **Sideloadly** starten (`sideloadly.io`, Windows-Build) und das iPad per USB
   anschließen.
4. In Sideloadly `PokeJ.ipa` auswählen und die **freie Apple-ID** eintragen
   (Apple-ID + App-spezifisches Passwort). Sideloadly signiert das unsignierte
   `.ipa` selbst.
5. **Signieren/Installieren** starten. Auf dem iPad ggf. unter
   *Einstellungen → Allgemein → VPN & Geräteverwaltung* dem Entwicklerprofil
   vertrauen.
6. Profil läuft **nach 7 Tagen ab** → wöchentlich neu sideloaden (gestrige
   Artifacts können wiederverwendet werden).
7. **Kameratests** laufen nur auf dem echten iPad (der Simulator hat keine
   Kamera). Preise erfordern eine Internetverbindung (TCGdex).


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
- ✅ Bundle-ID: `local.pokej.app`.
- ✅ Repository: **privat** (begrenztes monatliches macOS-Minutenbudget).
- ⚠️ Bei privatem Repo ist das macOS-Minutenbudget knapp → CI sparsam
  einsetzen (nicht bei jedem Zwischen-Commit).

## 9. Phase 1 – Nächste Schritte zum ersten Build

1. **Privates GitHub-Repository** anlegen und dieses Verzeichnis pushen:
   ```powershell
   git remote add origin https://github.com/<user>/pokeJ.git
   git push -u origin main
   ```
2. Der Workflow `.github/workflows/ci.yml` läuft bei Push auf `main` und
   generiert das Projekt via XcodeGen, baut und testet auf einem macOS-Runner.
3. **Ergebnis prüfen:** Der Lauf ist die erste echte Verifikation von Build und
   Tests. Bis dahin gilt der Code als **nicht kompiliert/getestet**.
4. Optional zur Installation aufs iPad: Artifact/build herunterladen und per
   **Sideloadly** mit freier Apple ID installieren (7-Tage-Profil).

### Lokales Vorab-Setup (Windows)

```powershell
winget install --id Git.Git -e --source winget     # bereits erledigt
# Sideloadly (optional, für Geräteinstallation):
winget install --id Sideloadly.Sideloadly -e
```
