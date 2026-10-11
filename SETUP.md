# Setup & Entwicklungsumgebung

## 1. Aktuelle Umgebung (geprüft)

| Werkzeug | Status |
|---|---|
| Windows 10 (10.0.19045), i7-6820HQ, 15,3 GB RAM | ✅ |
| VS Code 1.141.0 | ✅ |
| Node v26.8.1 / npm 11.19.0 | ✅ |
| winget 1.29.380 | ✅ |
| iPad (bevorzugt) und iPhone zum Testen | ✅ |
| **Mac / macOS / Xcode / Swift-Toolchain** | ❌ |
| git | ❌ (nachinstallieren) |

## 2. Die harte Randbedingung

iOS-Apps lassen sich **nur auf macOS** kompilieren, signieren und archivieren
(Xcode, `xcodebuild`, iOS-SDK existieren ausschließlich für macOS). Ein iPad
kann **nicht** bauen — es ist ausschließlich **Testgerät**.

Da kein Mac vorhanden ist, gibt es zwei tragfähige Wege:

### Weg A — Cloud-Mac (empfohlen zum interaktiven Arbeiten)
Gemieteter Apple-Hardware (z. B. MacStadium, Scaleway, AWS EC2 Mac, ZavCloud)
per VNC/SSH. Vorteile: echtes Xcode, Simulator, Kameratest-Installation.
Kosten: grob 20–200 € je nach Modell/Zeitraum.

### Weg B — GitHub-Actions-macOS-Runner (empfohlen zum Start, kostenlos möglich)
Code auf Windows schreiben → `git push` → macOS-Runner baut/signiert.
Kostenlos bei **öffentlichem** Repository; private Repos verbrauchen
Minutenbudget (macOS-Minuten teurer). Kein interaktives Debuggen.
Tools: **XcodeGen** (Projekt aus `project.yml`), `xcodebuild`, `Fastlane match`.

> **Empfehlung:** Weg B zum Start (0 €) und bei Bedarf sporadisch einen
> Cloud-Mac (Weg A) für interaktives Debugging und Kameratests. Alternativ ein
> **Mac mini M4** (~600–700 € einmalig) als langfristig günstigste Lösung.

## 3. Benötigte Zugangsdaten

| Zweck | Zugang | Pflicht |
|---|---|---|
| Build/Signierung/TestFlight | Apple Developer Program (99 €/Jahr) | für Gerätetest/Verteilung |
| Signierung in CI | Distribution-Zertifikat (.p12) + Provisioning Profile (.mobileprovision) | ja (Weg B) |
| Build-Upload | App-Store-Connect-API-Key (Issuer-ID, Key-ID, .p8) | ja (Weg B) |
| Kartendaten/-preise | **kein** Key (TCGdex) | — |
| Cardmarket | **kein** Zugang nötig (Preise über TCGdex) | — |
| Backend (Phase 5) | Supabase-Projekt + Anon-Key + RLS | optional |

**Sicherheit:** Zertifikate/Keys **niemals** committen. In CI als Secrets
(Base64) ablegen, im Keychain temporär importieren.

## 4. Lokales Setup auf Windows

```powershell
# git installieren (falls nicht vorhanden)
winget install --id Git.Git -e --source winget

# Node ist bereits vorhanden; optionale Helfer:
npm install -g @xcodegen/... # (XcodeGen ist Ruby/native – in CI auf dem Mac)
```

Auf dem **Mac/CI**:
```bash
brew install xcodegen
xcodegen generate      # erzeugt das .xcodeproj aus project.yml
xcodebuild -scheme PokeJ -destination 'generic/platform=iOS' build
```

## 5. Signierung (CI-Kurzüberblick)

1. `.p12` und `.mobileprovision` in GitHub-Secrets (Base64) hinterlegen.
2. Runner: temporären Keychain anlegen, Secrets importieren.
3. `xcodebuild archive` → `-exportArchive` → `.ipa`.
4. Upload nach App Store Connect (API-Key) → TestFlight.

## 6. Kostenübersicht

| Posten | Kosten | Kategorie |
|---|---|---|
| TCGdex API | 0 € | kostenlos |
| Apple Vision / Core Image / SwiftData | 0 € | kostenlos |
| OpenCV / Tesseract | 0 € | kostenlos (optional) |
| GitHub-Actions-macOS (public repo) | 0 € | kostenlos |
| Supabase Free Tier | 0 € | kostenlos (optional) |
| Apple Developer Program | ~99 €/Jahr | erforderlich |
| Testgerät iPad/iPhone | vorhanden | erforderlich |
| Cloud-Mac (on-demand) | ~20–200 €/Monat | optional |
| Mac mini M4 | ~600–700 € einmalig | Option statt Cloud-Mac |
| Supabase Pro | abhängig | optional |
| Rechtliche Prüfung Bildrechte | offen | ungeklärt |

## 7. Offene Einrichtungsentscheidungen

- Build-Weg A vs. B verbindlich wählen.
- Bundle-ID / Team-ID festlegen.
- CI-Service und Signierungsstrategie (Fastlane match?) wählen.
