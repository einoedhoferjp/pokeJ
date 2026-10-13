# Teststrategie

Grundsatz: Es werden **keine erfundenen Testergebnisse** dokumentiert. Nicht
ausführbare Tests werden ausdrücklich als **nicht ausgeführt** gekennzeichnet.

## 1. Testebenen

| Ebene | Umfang | Werkzeug |
|---|---|---|
| Unit | Entities, Repositories, UseCases (z. B. Sammlungswert, Filter) | XCTest |
| Integration | SwiftData-Persistenz, Provider-Mapping (mit Mock-JSON) | XCTest |
| Snapshot/UI | Kernansichten, Zustands-/Variantenauswahl | XCUITest (später) |
| Bild/OCR | Erkennung an Testbildern | XCTest + fixe Testbilder |

## 2. Testschwerpunkte je Phase

- **Phase 1:** Datenmodell, Persistenz, manuelles Anlegen, mehrere Zustände
  derselben Karte, Suche/Filter/Sortierung.
- **Phase 2:** OCR-Felderkennung, Kandidatenranking, kein stilles Falschspeichern.
  In CI abgedeckt (ohne Netzwerk/Gerät): `CardTextParserTests`,
  `CardMatcherTests`, `IdentifyCardUseCaseTests`, `TCGdexProviderTests`
  (Stub-HTTPClient), `ScanProcessorTests` (Stub-Recognizer),
  `CardImagePreprocessorTests` (reine Koordinatenlogik).
- **Phase 3:** Variante→Preis-Zuordnung, Kennzahlen, Sammlungswert, veraltete
  Daten, Offline-Verhalten. In CI abgedeckt: `TCGdexPriceProviderTests`
  (reales JSON-Fixture), `CollectionValueCalculatorTests`, `PriceFreshnessTests`,
  `PriceResolverTests`, `RefreshPricesUseCaseTests`, `PriceServiceTests`
  (In-Memory-SwiftData).
- **Phase 3.5:** Login (gesalzene SHA-256-Hashes, Sitzungspersistenz),
  Duplikat-Zusammenfassung. In CI abgedeckt: `AuthServiceTests`
  (Hash-Vektor + Probe-Accounts + `AuthStore` mit eigener `UserDefaults`-Suite),
  `CollectionRepositoryTests` (u. a. `existingItem`/Varianten-Wiederverwendung).
- **Phase 4:** Bildqualitätsprüfung, Zentrierung, Zustandsschätzung +
  Unsicherheit, manuelle Korrektur. In CI abgedeckt: `ConditionHeuristicsTests`,
  `ConditionAssessorTests` (synthetische Testbilder).
- **Phase 5:** Synchronisierung (Konfliktfälle, kein Datenverlust), Export/Backup,
  Import. In CI abgedeckt: `CollectionImportTests` (JSON-Round-Trip
  Export→Import, additive Zusammenführung identischer Exemplare, Überspringen
  unbekannter Werte). Preisverlauf-Chart und Datei-Export selbst erfordern die
  App/UI.

## 3. Testkarten-Set (anzulegen)

Repräsentative Karten mit bekannten Erwartungswerten (Ground Truth):

- [ ] Deutsche Karte (Standard-Set)
- [ ] Englische Karte
- [ ] Japanische Karte
- [ ] Französische und italienische Karte
- [ ] Ältere Karte (vor BW) mit ungewöhnlichem Layout
- [ ] Neuere Karte (aktuelles Set)
- [ ] Holo-Karte
- [ ] Reverse-Holo-Karte
- [ ] Alternative Artwork / Special Illustration Rare
- [ ] Promo-Karte
- [ ] Karte mit sichtbaren Beschädigungen (Ecken/Kanten/Kratzer)
- [ ] Foto unter schwieriger Beleuchtung / mit Reflexion
- [ ] Foto mit perspektivischer Verzerrung
- [ ] Unscharfes Foto

Für jede Karte werden hinterlegt: bekannte Card-ID, Sprache, Variante,
Kartennummer und (falls zutreffend) der erwartete Preis-Datensatz.

## 4. Bekannte Grenzen der Erkennung

- Reflexionen auf Holo-Oberflächen stören OCR und Merkmalsanalyse.
- Alte/japanische Karten: uneinheitliche Layouts, kleine Schrift.
- Varianten-Trennung (normal/reverse/holo) allein aus einem Foto schwer.
- Preise über TCGdex: bekannte Varianten-/ID-Fehler (siehe `DATA_SOURCES.md`).
- Zustandsschätzung ohne gelabelten Datensatz nur grob und unsicher.

## 5. Ausführung

- Tests laufen nicht auf Windows (kein Swift). Sie laufen im **CI-macOS-Runner**
  oder auf einem Cloud-Mac:
  ```bash
  xcodebuild test -scheme PokeJ -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' CODE_SIGNING_ALLOWED=NO
  ```
- Der CI-Lauf (`.github/workflows/ci.yml`) ist für Phase 1 und 2 **grün**:
  Build kompiliert, alle Unit-Tests bestehen.
- Kamera-, Vision- und Netzwerkpfade werden in CI **nicht** ausgeführt
  (Simulator ohne Kamera, kein Live-Zugriff) – sie sind über Protokolle und
  Stubs abgedeckt bzw. erfordern einen Test auf dem echten iPad.

## 6. Gerätetest auf dem iPad (vorbereitet)

Die App bringt unter **Konto-Menü → Diagnose → Gerätetest** eine Diagnoseansicht
mit, die die geräteabhängigen Funktionen explizit prüft und nichts erfindet:

- **Kamera-Scan:** meldet, ob `VNDocumentCameraViewController` unterstützt wird
  (auf dem iPad „verfügbar", im Simulator „nicht verfügbar").
- **OCR-Sprachen:** listet die von Vision unterstützten Sprachen (Anzahl).
- **Offline-Katalog:** Anzahl Sets/Karten sowie Quelle und Erzeugungsdatum.
- **Live-Anbindung:** zwei Prüfknöpfe für Katalogsuche und Preise, die eine
  echte TCGdex-Anfrage auslösen und Erfolg (mit Anzahl/Treffer) oder die
  konkrete Fehlermeldung anzeigen.

Checkliste für den Durchlauf auf dem Gerät:

- [ ] App installiert und gestartet (Sideloading, 7-Tage-Profil).
- [ ] Anmeldung mit Probenkonto funktioniert; Sitzung bleibt nach Neustart.
- [ ] `Gerätetest` zeigt „Kamera-Scan: verfügbar" und eine OCR-Sprachliste > 0.
- [ ] „Katalogsuche" und „Preise" unter Live-Anbindung laufen erfolgreich.
- [ ] Karte scannen → Kandidaten → bestätigen → speichern (siehe Testkarten-Set).
- [ ] Belohnungs-Snackbar „+50 Punkte" erscheint nach dem Bestätigen.
- [ ] Preis im Katalogdetail laden **und** aktualisieren (Zeitstempel ändert sich).
- [ ] Sammlung bleibt nach App-Neustart erhalten.

> Diese Liste ist eine **Vorbereitung**; die Häkchen werden erst nach tatsächlicher
> Durchführung auf dem Gerät gesetzt (keine erfundenen Ergebnisse).

