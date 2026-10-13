# Roadmap

Jede Phase gilt erst als abgeschlossen, wenn die Kernfunktionen **getestet** und
**dokumentiert** sind. Es werden keine erfundenen Testergebnisse dokumentiert.

Legende: ✅ erledigt · 🚧 in Arbeit · ⬜ offen

---

## Phase 0 — Technische Prüfung & Planung ✅

- ✅ Entwicklungsumgebung geprüft (Windows, kein Mac, kein Xcode/git/Swift).
- ✅ TCGdex-API + Lizenz recherchiert.
- ✅ Cardmarket-API-Zugang geprüft (nur professionelle Verkäufer).
- ✅ Open-Source-Optionen OCR/CV bewertet (Vision, Core Image, OpenCV, Tesseract).
- ✅ Architekturvorschlag (`ARCHITECTURE.md`).
- ✅ Datenmodell (`ARCHITECTURE.md` §4).
- ✅ Roadmap (dieses Dokument), Kosten, Zugangsdaten (`SETUP.md`).
- ✅ Risikoanalyse (`ARCHITECTURE.md` §8).

**Entschieden:** Build-Weg = GitHub-Actions-CI (kostenlos) + Sideloading aufs
iPad; Deployment-Target = iOS 17+; Datenquelle = TCGdex.

---

## Phase 1 — Minimal funktionsfähige App ✅

Ziel: eine offline nutzbare App, die die Sammlung bereits sinnvoll verwaltet.

- ✅ SwiftUI-Projektgerüst (universell, iPad zuerst), iOS 17+ (`project.yml`).
- ✅ SwiftData-Modell (Card, CardVariant, CollectionItem, PriceSnapshot,
  ScanRecord, ConditionAssessment).
- ✅ `CardDataProvider`/`PriceProvider` als Protokoll + `MockCardDataProvider`.
- ✅ Seed-Datensatz (klein, offline, idempotent).
- ✅ Bibliotheksansicht (Raster) mit Suche, Filter, Sortierung.
- ✅ Karte manuell hinzufügen/bearbeiten/löschen (Sprache, Variante, Zustand).
- ✅ Kartendetailansicht (ohne Preise, mit Platzhalter-Hinweis).
- ✅ Basis-Unit-Tests (Datenmodell, Filter, Mock-Provider).
- ✅ Build über CI verifiziert (GitHub-Actions-Workflow, grün: Build + Tests).
- ⬜ Installation auf dem iPad per Sideloading (7-Tage-Profil).

**Definition of Done:** App startet, Sammlung bleibt nach Neustart erhalten,
manuelles Anlegen mehrerer Zustände derselben Karte funktioniert.

> **Status:** Der CI-Lauf auf dem macOS-Runner ist **grün** (Build kompiliert,
> alle Unit-Tests bestehen). Die manuelle Installation auf dem iPad steht noch
> aus.

---

## Phase 2 — Scanner 🚧

- ✅ Kamera-Scan über `VNDocumentCameraViewController` (VisionKit) statt rohem
  AVFoundation – übernimmt Aufnahme und Perspektivkorrektur.
- ✅ Kartenrechteck erkennen + perspektivisch entzerren (Dokumentenscanner +
  CoreImage `CIPerspectiveCorrection` in `CardImagePreprocessor`).
- ✅ Vision-OCR (Name, Nummer, KP) – `TextRecognizing`/`VisionTextRecognizer`,
  vollständig auf dem Gerät.
- ✅ Live-Anbindung `TCGdexProvider` inkl. Suche, Karte, Sets, Set-Namen-Cache.
- ✅ Kandidatenliste + Bewertung + Statusanzeige (`CardMatcher`,
  `IdentifyCardUseCase`, `ScannerView`).
- ✅ Bestätigung und Speichern in die Sammlung (vorausgefüllter
  Hinzufügen-Dialog, `ScanRecord`-Protokollierung).
- ✅ Unit-Tests mit Stub-HTTPClient und Stub-Recognizer (CI-grün).
- ⬜ Tests mit realen Karten auf dem Gerät (siehe `TESTING.md`).

**Definition of Done:** Einzelkarten-Scan liefert zuverlässig Kandidaten mit
nachvollziehbarem Status; keine stille Fehlspeicherung.

> **Status:** Die Implementierung ist committet und die Unit-Tests sind im CI
> **grün**. Die Erkennungsqualität mit echten Karten und Kamerabildern ist noch
> **nicht** verifiziert – das erfordert einen Test auf dem iPad.


---

## Phase 3 — Cardmarket-Preise ✅

- ✅ Zuordnung Variante → `pricing.cardmarket` (`TCGdexPriceProvider`,
  Foil/Non-Foil-Mapping über die Holo-Kennzahlen).
- ✅ `PriceSnapshot`-Speicherung + Aktualisierung (`PriceRepository` mit
  „save-if-changed", `PriceService`, „Preise aktualisieren" in der Bibliothek).
- ✅ Anzeige in Detail- und Bibliotheksansicht mit Kennzahl + Zeitstempel
  (`PriceSectionView`, Sammlungswert-Kopf).
- ✅ Sammlungswert + Kennzeichnung fehlender/veralteter Preise
  (`CollectionValueCalculator`, `PriceFreshness`).
- ✅ Offline: letzter Stand mit „veraltet"-Hinweis (Badge + relative Zeit).
- ✅ Verlaufsdaten (Historie: neuer Datensatz nur bei Preisänderung).
- ✅ Unit-Tests mit Stub-HTTPClient/StubPriceProvider + In-Memory-SwiftData
  (reales TCGdex-JSON als Fixture).

**Definition of Done:** Preise korrekt gekennzeichnet; Sammlungswert weist
fehlende Daten ehrlich aus.

> **Status:** Die Implementierung ist committet und die Unit-Tests sind im CI
> **grün**. Die Preisdaten selbst wurden noch **nicht** mit einem echten
> TCGdex-Live-Abruf in der App verifiziert – das erfordert einen Lauf auf dem
> iPad/Gerät.


---

## Phase 3.5 — Login, Offline-Katalog & Feinschliff 🚧

Nachfreigabe des Nutzers; baut auf Phase 1–3 auf.

- ✅ Lokaler Login (Probe-Accounts, gesalzene SHA-256-Hashes, Sitzung über
  `UserDefaults`) – `AuthService`, `AuthStore`, `LoginView`, `RootView`.
- ✅ App-Wurzel schaltet zwischen Login und `TabView` („Sammlung", „Sets").
- ✅ Offline-Gesamtkatalog (155 Sets / 20483 Karten aus TCGdex, `Resources/
  PokemonCatalog.json`) mit Set-Browser, Kartensuche, Detailansicht inkl.
  Live-Preis (`SetBrowserView`, `CatalogCardDetailView`, `PokemonCatalog`).
- ✅ Design-Theming (Pokémon-Rot/Gold, Verläufe, Karten-Radius) und
  Button-Effekte/Haptik (`AppTheme`, `ButtonStyles`).
- ✅ Scanner-QoL: 3-s-Nachlauf, Statushilfen, deutlich sichtbarer Erfolg.
- ✅ Speichern-Härtung: Fehlerdialog statt stillem `try?`; optionales
  Zusammenfassen identischer Karten; Gesamtzahl im Bibliothekskopf.
- ✅ Preise im Katalogdetail laden **und aktualisieren** (Toolbar + Button,
  Zeitstempel/Notiz).
- ✅ Belohnungs-Snackbar „+50 Punkte" nach dem Bestätigen eines Scans
  (`RewardBanner`, eingebunden in `RootView` und `ScannerView`).
- ✅ Gerätetest-Ansicht `DeviceDiagnosticsView` (Kamera/OCR-Verfügbarkeit,
  Offline-Katalog-Statistik, Live-Anbindung Katalog + Preise).
- ✅ CI-Verifikation (Build + 92 Unit-Tests grün, 0 Fehlschläge).
- ⬜ Gerätetest auf dem iPad (Kamera, Vision-OCR, Live-Preise) – Vorbereitung
  siehe `TESTING.md` §6.

> **Status:** Implementierung committet und im CI **grün**; der Gerätetest auf
> dem iPad steht noch aus. Zutreffende Probe-Zugangsdaten siehe `SETUP.md`.

---

## Phase 4 — Zustandsbewertung ✅

- ✅ Aufnahme Vorder-/Rückseite (PhotosPicker)
- ✅ Bildqualitätsprüfung (Schärfe, Beleuchtung, Reflexion) – Heuristik
- ✅ Zentrierungsanalyse (Randbreite/-gleichmäßigkeit)
- ✅ Merkmalsanalyse (Ecken/Kanten/Weißung) – konservativ
- ✅ Manuell korrigierbare Zustandsvorschau + Konfidenz
- ✅ Tests mit synthetischen Bildern (CI)
- ✅ Konzept Datensammlung für späteres Core-ML-Modell (Markierung „keine ML-Schätzung")

## Phase 5 — Erweiterungen 🚧

- ✅ Preisverlauf-Diagramme (Chart, gespeicherte Preisstände)
- ✅ Export / Backup (JSON + CSV) aus Bibliothek
- ✅ Import (Backup wiederherstellen) – additiv, nie zerstörend; erkennt
  identische Exemplare und erhöht die Anzahl; überspringt unbekannte Werte.
- ✅ Stapelscan (mehrere Karten nacheinander, mit Pause)
- ✅ Fiktive Packs & Punkte-Wirtschaft (Kaufen/Öffnen aus Offline-Katalog)
- ⬜ Verbesserte Bilderkennung / eigenes Core-ML-Modell
- ⬜ Supabase-Synchronisierung (optional, erst bei Bedarf)
- ⬜ Weitere Sprachen der App
- ⬜ App-Store-Vorbereitung

---

## Meilensteine

| Meilenstein | Phase | Kriterium |
|---|---|---|
| M0 Planung | 0 | Architektur + Modell + Roadmap freigegeben |
| M1 Nutzbare App | 1 | Sammlung offline verwaltbar, CI-Build grün |
| M2 Scan | 2 | Karte scannen → bestätigen → speichern |
| M3 Preise | 3 | Cardmarket-Preise korrekt gekennzeichnet |
| M3.5 Login/Katalog | 3.5 | Login + Offline-Gesamtkatalog nutzbar |
| M4 Zustand | 4 | Zustand schätzbar + korrigierbar |
| M5 Cloud/ML | 5 | Sync/ML/Export nach Bedarf |
