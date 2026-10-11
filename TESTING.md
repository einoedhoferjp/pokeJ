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
- **Phase 3:** Variante→Preis-Zuordnung, Kennzahlen, Sammlungswert, veraltete
  Daten, Offline-Verhalten.
- **Phase 4:** Bildqualitätsprüfung, Zentrierung, Zustandsschätzung +
  Unsicherheit, manuelle Korrektur.
- **Phase 5:** Synchronisierung (Konfliktfälle, kein Datenverlust).

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
  xcodebuild test -scheme PokeJ -destination 'platform=iOS Simulator,name=iPad (10th generation)'
  ```
- Bis ein Build-Weg steht: **keine Tests ausgeführt** (Phase 0).
