# Architektur

## 1. Überblick

Die App wird als **native, offline-first SwiftUI-App** gebaut. Externe
Datenquellen (TCGdex für Stammdaten und Preise) werden hinter Protokollen
gekapselt, damit die Quelle austauschbar ist und die App ohne Netz nutzbar
bleibt.

## 2. Schichtenmodell

```
┌─────────────────────────────────────────────────────────┐
│ App / Features  (SwiftUI)                                │
│  Dashboard · Scanner · Library · CardDetails ·           │
│  ConditionAssessment · PriceTracking                     │
├─────────────────────────────────────────────────────────┤
│ Domain  (Entities + UseCases, keine I/O-Details)         │
│  IdentifyCard · AddToCollection · RefreshPrices ·        │
│  AssessCondition · ComputeCollectionValue                │
├─────────────────────────────────────────────────────────┤
│ Data / Services                                          │
│  CardDataProvider  → TCGdexProvider                      │
│  PriceProvider     → TCGdexPricingProvider               │
│  ImageProcessing   → CardRectifier · OCRService(Vision)  │
│                       · ImageQualityChecker              │
├─────────────────────────────────────────────────────────┤
│ Persistence  (SwiftData + Repositories + Cache)          │
└─────────────────────────────────────────────────────────┘
```

**Prinzipien**
- Protocol-first: `CardDataProvider`, `PriceProvider` sind Protokolle. Die
  konkrete Implementierung (TCGdex, Mock, später andere) ist austauschbar.
- Repository-Pattern über SwiftData; Domain kennt SwiftData nicht direkt.
- Keine Secrets im Client. TCGdex benötigt keinen Key.
- Fehler werden als typisierte Fehler an die UI gereicht; Preisfehler dürfen
  die Bibliothek nie blockieren.

## 3. Verzeichnisstruktur (Ziel)

```
App/                 App-Shell, DI-Container, Navigation
Features/
  Scanner/           Kamera, Rectify, OCR, Kandidatenliste
  Library/           Raster, Suche, Filter, Sortierung
  CardDetails/       Stammdaten, Varianten, Preise, Exemplare
  ConditionAssessment/  Vorder/Rück, Merkmale, Korrektur
  PriceTracking/     PriceSnapshot, Sammlungswert, Verlauf
  Dashboard/         Kennzahlen, letzte Karten, veraltete Preise
Domain/
  Entities/
  UseCases/
Data/
  Services/CardData/
  Services/Pricing/
  Services/ImageProcessing/
  Persistence/       SwiftData-Modelle, Repositories, Cache
Resources/           Seed-Daten, Assets, Localizable.strings
Tests/
```

## 4. Datenmodell

### Entitäten

**Card** (Stammdaten)
- `id` (intern, UUID)
- `externalId` (TCGdex-ID, z. B. `swsh3-136`)
- `name`, `setId`, `setName`, `localId` (Kartennummer)
- `rarity`, `illustrator`
- `imageURL`
- `updatedAt` (aus TCGdex `updated`)

**CardVariant** (Sprache + Druck)
- `id` (intern)
- `cardId` → Card
- `language` (enum: de, en, fr, it, es, ja, …)
- `printing` (enum: normal, reverse, holo, firstEdition, promo)
- `cardmarketProductId` (optional, sobald verfügbar/zuordenbar)

**CollectionItem** (ein physisches Exemplar)
- `id` (intern)
- `variantId` → CardVariant
- `quantity` (Standard 1; >1 nur für identische Bündel)
- `confirmedCondition` (enum)
- `estimatedCondition` (enum, optional)
- `purchasePrice` (optional), `purchaseDate` (optional)
- `notes`
- `createdAt`

**PriceSnapshot**
- `id`, `cardmarketProductId`
- `metric` (enum: avg, low, trend, avg1, avg7, avg30, avgHolo, …)
- `amount`, `currency`
- `fetchedAt`, `source` (z. B. `tcgdex`)
- `matchQuality` (enum: exact, productOnly, uncertain)

**ScanRecord**
- `id`, `timestamp`
- `rawOCR` (erfasste Textfelder)
- `candidates` (Liste vorgeschlagener Varianten + Score)
- `chosenVariantId` (optional)
- `confidence` (optional)
- `status` (enum: recognized, likely, multiple, noMatch, error)

**ConditionAssessment**
- `id`, `collectionItemId` → CollectionItem
- `detectedDefects` (Ecken/Kanten/Oberfläche/Zentrierung)
- `estimatedCondition`, `confirmedCondition`
- `assessedAt`
- `imageReferences` (optional)

### Beziehungen

```
Card 1 ──< CardVariant 1 ──< CollectionItem 1 ──< ConditionAssessment
                       │
                       └──< PriceSnapshot   (über cardmarketProductId)
ScanRecord ──(optional)──> CardVariant
```

### Entscheidung: Exemplar vs. Menge

Ein `CollectionItem` repraesentiert **ein physisches Exemplar**, nicht eine
Menge. Begründung: Das Projektziel verlangt ausdrücklich *unterschiedliche
Zustände derselben Karte*. Würde ein Datensatz eine Menge abbilden, müssten
Zustand, Kaufpreis und Notizen pro Zustandsgruppe dupliziert werden. Das
`quantity`-Feld bleibt für echte identische Bündel erhalten. Damit ist beides
möglich, ohne das Modell zu verkomplizieren.

### Zustandsklassen (vorläufig)

`nearMint, excellent, good, lightPlayed, played, poor` + `uncertain`.
Das Mapping auf die tatsächlichen Cardmarket-Zustandsklassen wird **geprüft**,
nicht erfunden, und erst bei der Preisanzeige final festgelegt.

## 5. Datenquellen-Kapselung

```swift
protocol CardDataProvider {
    func searchCards(query: CardQuery) async throws -> [CardBrief]
    func card(externalId: String, language: Language) async throws -> Card
    func sets(language: Language) async throws -> [SetBrief]
}

protocol PriceProvider {
    func price(for variant: CardVariant) async throws -> PriceSnapshot
}
```

- Phase 1: `MockCardDataProvider` + Seed-Datensatz (voll offline).
- Phase 2: `TCGdexProvider` gegen `https://api.tcgdex.net/v2/{lang}`.
- Phase 3: `TCGdexPricingProvider` liest `pricing.cardmarket` aus dem selben
  Card-Objekt.

## 6. Identifikation (geplant)

Mehrstufig, nie nur über den Namen:
1. Kartenrechteck erkennen + perspektivisch entzerren (Vision / Core Image).
2. OCR: Name, Kartennummer (`localId`/Gesamtzahl), HP, ggf. Set-Symbol.
3. Kandidatensuche über TCGdex (Name + Nummer + Sprache).
4. Bewertung über Set, Nummer, Seltenheit, Illustrator, Varianten.
5. Optional Bildähnlichkeit (Perceptual Hash) als Tie-Breaker.
6. UI zeigt wahrscheinlichsten Treffer **und** Alternativen; bei Unsicherheit
   ist eine manuelle Bestätigung zwingend. Nie stillschweigend speichern.

## 7. Offline-Fähigkeit

- SwiftData ist die führende lokale Quelle; die App bleibt ohne Netz nutzbar.
- Kartenstammdaten und Referenzbild-URLs werden gecacht.
- Zuletzt bekannte Preise bleiben sichtbar, werden aber als **veraltet**
  markiert (Zeitstempel + Warnung).
- Fehlerbehandlung: Netzfehler dürfen die Bibliothek nie gefährden.

## 8. Bekannte technische Risiken

| # | Risiko | Auswirkung | Gegenmaßnahme |
|---|---|---|---|
| 1 | Kein Mac vorhanden | Build/Test blockiert | Cloud-Mac oder GitHub-Actions-CI (SETUP.md) |
| 2 | Cardmarket-API nicht zugänglich | keine Preise direkt | Preise über TCGdex; Quelle kennzeichnen |
| 3 | TCGdex-Preis/Varianten-Fehler | falsche Preise | `matchQuality`, Warnhinweise, `variants_detailed` beobachten |
| 4 | Preise ohne Sprache/Zustand | Ungenauigkeit | UI kennzeichnet produktbezogenen Preis |
| 5 | Kartenbild-Rechte | rechtlich | Bewertung offen; nur Referenzen, kein Vertrieb |
| 6 | OCR bei alten/JP-Karten | Fehltreffer | manuelle Bestätigung, Kandidatenliste |
| 7 | Keine gelabelten Zustandsdaten | keine ML-Bewertung | erst Basis-CV, dann Datensammlung |
| 8 | Einzelquelle TCGdex | Ausfall/Fehler | austauschbare Provider-Schicht |
| 9 | git nicht installiert | keine Versionierung | git nachinstallieren |

## 9. Offene Entscheidungen

1. **Build-Weg** (Cloud-Mac vs. GitHub-Actions-CI) — blockierend für Phase 1.
2. Deployment-Target endgültig auf **iOS 17+** festlegen (SwiftData).
3. Bundle-ID / Team-ID / Signing-Strategie.
4. Umfang Phase 1 (Umfang des Seed-Datensatzes).
5. Supabase erst Phase 5 bestätigen.
