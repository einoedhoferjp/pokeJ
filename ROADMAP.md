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

**Offen vor Phase 1:** Build-Weg festlegen (Cloud-Mac oder GitHub-Actions-CI).

---

## Phase 1 — Minimal funktionsfähige App ⬜

Ziel: eine offline nutzbare App, die die Sammlung bereits sinnvoll verwaltet.

- ⬜ SwiftUI-Projektgerüst (universell, iPad zuerst), iOS 17+.
- ⬜ SwiftData-Modell (Card, CardVariant, CollectionItem, …).
- ⬜ `CardDataProvider`/`PriceProvider` als Protokoll + `MockCardDataProvider`.
- ⬜ Seed-Datensatz (klein, offline).
- ⬜ Bibliotheksansicht (Raster) mit Suche, Filter, Sortierung.
- ⬜ Karte manuell hinzufügen/bearbeiten/löschen (Sprache, Variante, Zustand).
- ⬜ Kartendetailansicht (ohne Preise).
- ⬜ Basis-Unit-Tests (Datenmodell, Repositories).
- ⬜ Build über den festgelegten Weg (CI) verifiziert.

**Definition of Done:** App startet, Sammlung bleibt nach Neustart erhalten,
manuelles Anlegen mehrerer Zustände derselben Karte funktioniert.

---

## Phase 2 — Scanner ⬜

- ⬜ AVFoundation-Kameraansicht (iPad).
- ⬜ Kartenrechteck erkennen + perspektivisch entzerren.
- ⬜ Vision-OCR (Name, Nummer, HP).
- ⬜ Live-Anbindung `TCGdexProvider`.
- ⬜ Kandidatenliste + Bewertung + Statusanzeige.
- ⬜ Bestätigung und Speichern in die Sammlung.
- ⬜ Tests mit realen Karten (siehe `TESTING.md`).

**Definition of Done:** Einzelkarten-Scan liefert zuverlässig Kandidaten mit
nachvollziehbarem Status; keine stille Fehlspeicherung.

---

## Phase 3 — Cardmarket-Preise ⬜

- ⬜ Zuordnung Variante → `pricing.cardmarket`.
- ⬜ `PriceSnapshot`-Speicherung + Aktualisierung.
- ⬜ Anzeige in Karten-/Detail-/Bibliotheksansicht mit Kennzahl + Zeitstempel.
- ⬜ Sammlungswert + Kennzeichnung fehlender/veralteter Preise.
- ⬜ Offline: letzter Stand mit „veraltet"-Hinweis.
- ⬜ Verlaufsdaten (PriceSnapshot-Historie).

**Definition of Done:** Preise korrekt gekennzeichnet; Sammlungswert weist
fehlende Daten ehrlich aus.

---

## Phase 4 — Zustandsbewertung ⬜

- ⬜ Aufnahme Vorder-/Rückseite.
- ⬜ Bildqualitätsprüfung (Schärfe, Beleuchtung, Perspektive).
- ⬜ Zentrierungsanalyse (Randbreiten).
- ⬜ Erste Merkmalsanalyse (Kanten/Ecken Whiteing soweit technisch sinnvoll).
- ⬜ Manuell korrigierbare Zustandsvorschau + Konfidenz.
- ⬜ Tests mit bekannten Beispielen.
- ⬜ Konzept Datensammlung für späteres Core-ML-Modell.

---

## Phase 5 — Erweiterungen ⬜

- ⬜ Supabase-Synchronisierung (optional).
- ⬜ Preisverlauf-Diagramme.
- ⬜ Verbesserte Bilderkennung / eigenes Core-ML-Modell.
- ⬜ Stapelscan.
- ⬜ Export / Backup.
- ⬜ Weitere Sprachen der App.
- ⬜ App-Store-Vorbereitung.

---

## Meilensteine

| Meilenstein | Phase | Kriterium |
|---|---|---|
| M0 Planung | 0 | Architektur + Modell + Roadmap freigegeben |
| M1 Nutzbare App | 1 | Sammlung offline verwaltbar, CI-Build grün |
| M2 Scan | 2 | Karte scannen → bestätigen → speichern |
| M3 Preise | 3 | Cardmarket-Preise korrekt gekennzeichnet |
| M4 Zustand | 4 | Zustand schätzbar + korrigierbar |
| M5 Cloud/ML | 5 | Sync/ML/Export nach Bedarf |
