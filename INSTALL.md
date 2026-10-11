# Installationsanleitung: App auf das iPad bringen

Ziel: Die fertige App auf einem echten iPad installieren — **ohne Mac** und
**ohne Apple Developer Program (99 €/Jahr)**.

> Warum nicht einfach antippen? iOS hat **keinen eingebauten `.ipa`-Installer**.
> Die Datei in „Dateien" lässt sich nicht direkt öffnen. Es braucht immer ein
> Werkzeug, das die App mit einer (kostenlosen) Apple-ID **signiert** und
> **installiert**.

---

## 0. Voraussetzungen

| Sache | Details |
|---|---|
| Windows-PC | Windows 10 oder neuer (zum Signieren) |
| iPad | verbunden per **USB-Kabel**, entsperrt |
| Apple ID | **kostenlos** (z. B. die normale iCloud-Apple-ID) |
| `.ipa`-Datei | `PokeJ.ipa` aus dem GitHub-Artefakt (siehe unten) |

**Grenzen der kostenlosen Apple-ID**
- Signatur läuft **nach 7 Tagen ab** → wöchentlich erneuern.
- Max. **3 eigene Apps** gleichzeitig.
- **Kein** TestFlight, **kein** App Store.

> Auf **iOS 26.3** gibt es keinen reinen On-Device-Weg (TrollStore nur bis
> iOS 17.0). Es muss ein PC-Werkzeug sein. Empfohlen: **AltStore** (Variante A).

---

## Schritt 1 — Die `.ipa` herunterladen

1. Im Browser öffnen: `https://github.com/einoedhoferjp/pokeJ`
2. Reiter **Actions** → links Workflow **IPA** anklicken.
3. Den **grünen** Lauf oben öffnen → ganz unten Abschnitt **Artifacts**.
4. **`PokeJ-unsigned-ipa`** herunterladen (kommt als `.zip`).
5. Rechtsklick → **Alle extrahieren** → darin liegt **`PokeJ.ipa`**.

Merkhilfe: Artefakte laufen nach **90 Tagen** ab. Für ein frisches `.ipa` den
Workflow **IPA → Run workflow** einfach neu starten.

---

## Variante A (empfohlen) — AltStore / AltServer

Signiert über einen kleinen Server auf deinem PC; kein Sideloadly nötig.

### A1. Apple-Komponenten installieren
Wichtig: **von apple.com**, **nicht** aus dem Microsoft Store.
- iTunes: `https://www.apple.com/itunes/`
- iCloud für Windows: `https://support.apple.com/de-de/106189`

Starte iTunes einmal und melde dich mit deiner Apple ID an.

### A2. AltServer starten
1. **AltServer für Windows** von `https://altstore.io` herunterladen.
2. Installieren und starten. Er läuft im **Infobereich** (unten rechts,
   ggf. hinter dem `^`-Pfeil).

### A3. iPad verbinden
1. iPad per USB anschließen und **entsperren**.
2. Am iPad bei „Diesem Computer vertrauen?" → **Vertrauen**.
3. (Empfohlen) In iTunes unter „Zusammenfassung" → „**Über WLAN
   synchronisieren**" aktivieren, damit spätere Aktualisierungen ohne Kabel
   gehen.

### A4. AltStore auf das iPad installieren
1. AltServer-Symbol im Infobereich anklicken → **Install AltStore** →
   dein **iPad** wählen.
2. **Apple ID** und Passwort eingeben.
   - Bei **Zwei-Faktor-Authentifizierung** schickt Apple einen **6-stelligen
     Code** ans iPad/iPhone → hier eintragen.
3. Warten, bis „Installation complete" erscheint.

### A5. Entwicklerprofil vertrauen
Am iPad: *Einstellungen → Allgemein → **VPN & Geräteverwaltung** →*
unter „Entwickler-App" den Eintrag mit deiner Apple ID antippen →
**„… vertrauen"**.

### A6. Die `.ipa` installieren
1. Sicherstellen, dass **AltServer auf dem PC läuft** und iPad + PC im
   **selben WLAN** sind.
2. Am iPad **AltStore** öffnen.
3. Reiter **My Apps** → **`+`** (oben links) → die Datei **`PokeJ.ipa`**
   auswählen (die `.ipa` muss auf dem iPad in „Dateien" liegen — die aus
   Schritt 1 dorthin kopieren, z. B. per „Dateien" / AirDrop / OneDrive).
4. AltStore schickt die Datei an AltServer, **signiert** und **installiert**
   sie. Danach erscheint **PokéJ** auf dem Home-Bildschirm.

---

## Variante B — Sideloadly

1. **iTunes** von apple.com installieren (siehe A1).
2. **Sideloadly** von `https://sideloadly.io` herunterladen und starten.
3. iPad per USB anschließen, entsperren, „Vertrauen".
4. In Sideloadly die **`.ipa`** in das Fenster ziehen.
5. **Apple ID** eintragen, ggf. **6-stelligen Code** eingeben.
6. **Start** → warten → am iPad das **Entwicklerprofil vertrauen** (wie A5).

---

## Variante C — 3uTools

1. **3uTools** von `https://www.3u.com` installieren.
2. iPad anschließen und im Programm erkennen lassen.
3. **Toolbox → IPA Signature** → `PokeJ.ipa` hinzufügen.
4. **Apple ID** eintragen → **signieren** → **installieren**.
5. Entwicklerprofil vertrauen (wie A5).

---

## Schritt 2 — Erster Start & Test

1. **PokéJ** auf dem iPad starten.
2. Beim ersten Start ggf. Kamera-Zugriff erlauben.
3. Kurz durchtesten:
   - Bibliothek lädt (Sammlungswert-Kopf sichtbar).
   - „Scannen" öffnet die Kamera (nur auf echtem Gerät).
   - „Preise aktualisieren" braucht **Internet** (TCGdex).

---

## Nach 7 Tagen — Signatur erneuern

Mit AltStore:
1. PC an, **AltServer läuft**, iPad im selben WLAN (oder per USB).
2. Am iPad **AltStore** öffnen → **My Apps** → **Refresh All**.
   (Alternativ: einfach die `.ipa` erneut über A6 installieren.)

Mit Sideloadly: die `.ipa` erneut über Variante B installieren.

---

## Problemlösung

| Problem | Lösung |
|---|---|
| AltServer erkennt das iPad nicht | Kabel wechseln, iPad entsperren + „Vertrauen", AltServer/iTunes neu starten. „Apple Mobile Device"-Dienst prüfen. |
| „Untrusted Developer" / App startet nicht | Profil unter *VPN & Geräteverwaltung* **vertrauen** (A5). |
| Installation bricht ab / Code-Fehler | iCloud/iTunes **von apple.com** (nicht Microsoft Store) verwenden. |
| App startet, verschwindet nach ein paar Tagen | 7-Tage-Ablauf → **Refresh** (oben). |
| AltStore lässt sich auf iOS 26.3 nicht installieren | Neuere AltStore-Version von altstore.io nutzen; sonst **Variante B (Sideloadly)** oder **C (3uTools)**. |
| „Dieser Account ist nicht berechtigt" | Max. 3 Apps pro freier Apple ID — eine andere App entfernen. |

---

## Checkliste

- [ ] `.ipa` aus dem IPA-Artefakt heruntergeladen und entpackt
- [ ] iTunes + iCloud **von apple.com** installiert und angemeldet
- [ ] AltServer läuft (oder Sideloadly/3uTools geöffnet)
- [ ] iPad per USB verbunden und vertraut
- [ ] Entwicklerprofil am iPad **vertraut**
- [ ] PokéJ erscheint auf dem Home-Bildschirm und startet
- [ ] Kamera- und Preis-Test durchgeführt
- [ ] Erinnerung: in **7 Tagen** erneuern
