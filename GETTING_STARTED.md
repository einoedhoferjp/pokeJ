# Schritt-für-Schritt-Anleitung: Vom Code zum ersten Build

Ziel: Das lokale Projekt auf GitHub hochladen und den ersten echten
Build-/Test-Lauf („grüne CI") erhalten. Das ist der erste Schritt, der den
Swift-Code tatsächlich verifiziert.

> Aktuell bereits erledigt: Git installiert, Projekt lokal committet
> (3 Commits, Branch `main`).

---

## Voraussetzungen

- **GitHub-Konto** (kostenlos): https://github.com/signup
- **Apple ID** (kostenlos) – erst später für die Installation auf dem iPad nötig.
- Nichts weiteres. Kein Mac, keine Kreditkarte.

---

## Schritt 1 – Privates GitHub-Repository anlegen

**Weg über die Webseite (empfohlen, kein Zusatzprogramm):**

1. https://github.com/new öffnen (eingeloggt).
2. **Repository name:** `pokeJ`
3. **Visibility:** **Private** auswählen.
4. **Wichtig:** *Kein* „Add a README", *keine* `.gitignore`, *keine* License
   anhaken – diese Dateien existieren bereits lokal.
5. Auf **Create repository** klicken.
6. Auf der nächsten Seite die **HTTPS-URL** kopieren, sie sieht so aus:
   `https://github.com/DEIN-NAME/pokeJ.git`

---

## Schritt 2 – Lokales Projekt mit GitHub verbinden

Im Projektordner `C:\Users\berl\Desktop\pokeJ` ein Terminal/PowerShell öffnen
und nacheinander ausführen:

```powershell
# 1) Verbindung zum neuen Repository herstellen (DEIN-NAME ersetzen)
git remote add origin https://github.com/DEIN-NAME/pokeJ.git

# 2) Prüfen, dass das Remote korrekt gesetzt ist
git remote -v

# 3) Branch "main" hochladen und als Upstream setzen
git push -u origin main
```

**Anmeldung:** Beim ersten Push öffnet Git für Windows ein Browserfenster
(Git Credential Manager). Dort bei GitHub einloggen und autorisieren.

- Falls nach Benutzername/Passwort gefragt wird: **Passwort = kein GitHub-Passwort**,
  sondern ein **Personal Access Token**. Erstellen unter:
  GitHub → *Settings* → *Developer settings* → *Personal access tokens* →
  *Tokens (classic)* → *Generate new token* → Scope **`repo`** anhaken →
  Token kopieren und als Passwort einfügen.

Nach dem Push erscheint der Code im GitHub-Repository.

---

## Schritt 3 – CI-Lauf beobachten

1. Im Repository auf den Reiter **Actions** gehen.
2. Dort läuft automatisch der Workflow **„Build & Test (iOS Simulator)"**
   (gestartet durch den Push auf `main`).
3. Den laufenden Eintrag anklicken und den Job **`build-test`** öffnen.
4. Der Lauf dauert ca. **10–20 Minuten** (erster Lauf inkl. `brew install
   xcodegen` und vollständigem Build).

**Hinweis Minutenbudget:** Das Repo ist privat, macOS-Runner verbrauchen das
monatliche Freikontingent. Deshalb: **einmal pushen und abwarten**, nicht
zwischendurch mehrfach pushen.

---

## Schritt 4 – Ergebnis interpretieren

- **Grüner Haken ✅** = Projekt generiert, Build erfolgreich, Unit-Tests grün.
  → Phase 1 ist damit **verifiziert**. Weiter mit Phase 2.
- **Roter Haken ❌** = Build- oder Testfehler. Das ist beim ersten Lauf normal.
  So gehst du vor:
  1. Den fehlgeschlagenen Schritt anklicken (z. B. „Build").
  2. Die **Logausgabe** bis zur ersten Zeile mit `error:` lesen.
  3. Den **Logausschnitt** (oder die vollständige Fehlermeldung) an mich
     weitergeben – ich behebe den Fehler und wir pushen erneut.

---

## Schritt 5 – App aufs iPad installieren

Ausführliche Anleitung (inkl. **AltStore** und **3uTools** als Alternativen zu
Sideloadly sowie Problemlösung): siehe **`INSTALL.md`**. Kurzfassung:

Der Workflow **`.github/workflows/ipa.yml`** baut ein **unsigniertes `.ipa`**.
So kommst du auf das Gerät:

1. Im Repository auf **Actions** → Workflow **„IPA"** → **Run workflow**
   (Branch `main`) klicken. Der Lauf braucht ca. 10–15 Minuten.
2. Nach dem Lauf beim Job-Ergebnis das Artefakt **`PokeJ-unsigned-ipa`**
   herunterladen und entpacken → `PokeJ.ipa`.
3. **Sideloadly** auf Windows installieren (kostenlos):
   ```powershell
   winget install --id Sideloadly.Sideloadly -e
   ```
4. iPad per USB anschließen, Sideloadly starten, `PokeJ.ipa` auswählen, deine
   **freie Apple ID** eintragen und **Start** drücken. Sideloadly signiert das
   unsignierte `.ipa` dabei selbst.
5. Auf dem iPad unter *Einstellungen → Allgemein → VPN & Geräteverwaltung* dem
   Entwicklerprofil vertrauen.
6. Das Profil ist **7 Tage** gültig → wöchentlich neu sideloaden.

Für Kameratests das **echte iPad** verwenden (der Simulator hat keine Kamera).

---

## Kurz-Checkliste

- [ ] GitHub-Konto vorhanden
- [ ] Privates Repository `pokeJ` angelegt (ohne README/gitignore/license)
- [ ] `git remote add origin …` ausgeführt
- [ ] `git push -u origin main` erfolgreich
- [ ] Actions-Lauf gestartet und Ergebnis abgewartet
- [ ] Ergebnis an mich melden (grün = weiter, rot = Logausschnitt senden)
- [ ] (Optional) Workflow **IPA** starten, Artefakt herunterladen, per Sideloadly
      aufs iPad laden
