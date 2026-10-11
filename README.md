# PokéJ — Pokémon TCG Scanner & Sammlungsverwaltung (iOS)

iOS-App zur Verwaltung einer Pokémon-Sammelkartensammlung: Karten mit der
Kamera (iPad/iPhone) erfassen, automatisch identifizieren, der Bibliothek
hinzufügen, den Zustand einschätzen und Cardmarket-Preise anzeigen.

> **Status:** Phase 1 in Arbeit. App-Code (SwiftUI + SwiftData + Bibliothek)
> ist geschrieben, aber **noch nicht kompiliert/getestet** – die Verifikation
> erfolgt über den GitHub-Actions-CI-Workflow auf macOS. Siehe `ROADMAP.md`.

---

## Zielbild

1. Karten fotografieren und automatisch erkennen.
2. Karten über Name, Set, Nummer und Bildähnlichkeit identifizieren.
3. Sprachvarianten (de/en/fr/it/ja, soweit verfügbar) und Druck/Holo-Varianten
   unterscheiden.
4. Karten in einer persönlichen Bibliothek verwalten (mehrere Exemplare je
   Zustand).
5. Zustand anhand von Vorder-/Rückseitenbildern **schätzen** (keine
   Grading-Behauptung).
6. Aktuelle Cardmarket-Preise anzeigen, Herkunft und Aktualität kennzeichnen.
7. Sammlungswert berechnen und (später) Wertentwicklung speichern.

## Technischer Stack (geplant)

| Bereich | Technologie |
|---|---|
| UI | SwiftUI (universell: iPhone + iPad), Deployment-Target iOS 17+ |
| Persistenz | SwiftData |
| Kamera | AVFoundation |
| OCR / CV | Apple Vision (`VNRecognizeTextRequest`, `VNDetectRectanglesRequest`), Core Image |
| Optional CV | OpenCV (nur bei belegtem Bedarf) |
| Kartendaten | TCGdex REST API v2 (MIT-lizenziert, kein Key) |
| Preise | Cardmarket-Preise **über TCGdex** (`pricing.cardmarket`) |
| Zukünftiges ML | Core ML / Create ML (nach gelabelten Daten) |
| Backend (später) | Supabase (optional, erst Phase 5) |

## Wichtige Hinweise / Einschränkungen

- **Keine lokale macOS-Umgebung:** Entwicklung und Build erfolgen nicht auf dem
  iPad. Xcode/`xcodebuild` laufen nur auf macOS. Builds müssen über einen
  **Cloud-Mac** oder einen **GitHub-Actions-macOS-Runner** erfolgen. Details in
  `SETUP.md`. Kamera/Vision lassen sich nur auf einem **echten Gerät** testen.
- **Preise:** Es wird **nicht** die offizielle Cardmarket-API genutzt (nur für
  professionelle Verkäufer). Preise stammen aus der TCGdex-Feld
  `pricing.cardmarket`. Sie sind produktbezogen und **nicht** sprach-, zustands-
  oder exemplargenau. Siehe `DATA_SOURCES.md`.
- **Kartenbilder:** Daten sind MIT-lizenziert, die **Bilder** unterliegen dem
  Urheberrecht von The Pokémon Company. Rechtliche Bewertung der Darstellung
  steht aus (siehe Risiken in `ARCHITECTURE.md`).

## Projektstruktur (Ziel)

```
App/            SwiftUI-App-Shell
Features/       Scanner, Library, CardDetails, ConditionAssessment, PriceTracking, Dashboard
Domain/         Entities + UseCases
Data/           Services (CardData, Pricing, ImageProcessing) + Persistence (SwiftData)
Resources/      Seed-Daten, Assets, Lokalisierung
Tests/          Unit- und Integrationstests
Documentation/  (Doku liegt vorerst im Wurzelverzeichnis)
```

## Dokumentation

- `GETTING_STARTED.md` — **Schritt-für-Schritt: Code auf GitHub + erster Build**
- `ARCHITECTURE.md` — Architektur, Datenmodell, Entscheidungen, Risiken
- `ROADMAP.md` — Phasen und Meilensteine
- `DATA_SOURCES.md` — TCGdex, Cardmarket, Lizenzen, Rechte
- `SETUP.md` — Entwicklungsumgebung, Build ohne Mac, Zugangsdaten
- `TESTING.md` — Teststrategie und Testkarten-Set

## Kosten (Kurzfassung)

- **Kostenlos:** TCGdex (Daten + Preise), Apple Vision/Core Image, SwiftData,
  OpenCV, Supabase Free Tier, GitHub-Actions-macOS-Runner (public repo).
- **Kostenpflichtig, erforderlich:** Apple Developer Program (99 €/Jahr),
  Testgerät (iPad/iPhone), **Mac-Zugang** (Cloud-Mac-Abo oder Mac mini).
- **Optional:** Supabase Pro, kostenpflichtige CI.

Vollständige Aufstellung in `SETUP.md`.

## Lizenz

Eigener Code: noch festzulegen. Genutzte Fremddaten: TCGdex-Datenbank unter MIT.
Kartenbilder/-inhalte © The Pokémon Company (Details in `DATA_SOURCES.md`).
