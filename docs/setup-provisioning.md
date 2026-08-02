# Setup & Provisionierung – vom Karton zum laufenden System

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Getting started»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/getting-started.html)).

Diese Referenz deckt alles ab, **bevor** die übrigen Referenzen greifen: Boot-Medium,
Netzteilwahl, Peripherie, Headless-Provisionierung und der erste Start. Sie ist die
Grundlage für den Pre-Flight-Check in `SKILL.md`.

## Inhaltsverzeichnis
1. [Gerätefamilien](#gerätefamilien)
2. [Boot-Medium](#boot-medium)
3. [Netzteil](#netzteil)
4. [Peripherie](#peripherie)
5. [Netzwerk-Ausstattung nach Modell](#netzwerk-ausstattung-nach-modell)
6. [Headless-Provisionierung](#headless-provisionierung)
7. [Network Install](#network-install)
8. [Erster Start & Troubleshooting](#erster-start--troubleshooting)
9. [Herunterfahren](#herunterfahren)
10. [Klassensatz und Flottenbetrieb](#klassensatz-und-flottenbetrieb)

---

## Gerätefamilien

| Familie | Beschreibung | Von diesem Skill abgedeckt |
|---------|--------------|----------------------------|
| **Flagship-SBC** (Pi 4, Pi 5) | Klassische Einplatinenrechner | ✅ vollständig |
| **Raspberry Pi Zero** | Kleiner, weniger USB, geringerer Verbrauch | teilweise – Besonderheiten unten |
| **Keyboard-Computer** (400, 500, 500+) | Rechner im Tastaturgehäuse | teilweise |
| **Compute Module** | System-on-Module für Industrie und Embedded | ❌ |
| **Raspberry Pi Pico** | Mikrocontroller (RP2040 / RP2350), **kein Linux** | ❌ |

➜ **Wichtig für die Projektplanung:** Der Pico ist ein Mikrocontroller, kein
Einplatinenrechner. Wenn ein Projekt an der Umgebungstemperatur des Pi 5 scheitert
(0–70 °C, siehe `mechanical.md`) oder deterministisches Timing braucht, ist ein Pico als
Aussenknoten oft die richtige Antwort – nicht ein weiterer Pi.

---

## Boot-Medium

### Grösse nach OS-Variante

| OS | Empfohlene Mindestgrösse |
|----|--------------------------|
| Raspberry Pi OS (Desktop + Basissoftware) | **32 GB** |
| Raspberry Pi OS Full (Desktop + empfohlene Anwendungen) | **32 GB** |
| Raspberry Pi OS Lite (nur Kommandozeile, für Headless) | **8 GB** |

Für Edge-AI-Projekte grosszügiger rechnen: Ollama-Modelle, HEF-Dateien und Bilddaten
sprengen 32 GB schnell. Empfehlungen dazu in `component-catalog.md`.

### Grenzen

| Grenze | Wert |
|--------|------|
| Maximale Kartengrösse | **< 2 TB** (Beschränkung des Master Boot Record) |
| Boot-Partition auf älteren Geräten | **≤ 256 GB** bei Pi Zero, erstem Flagship-Pi und frühen Pi 2 mit BCM2836 |

### Einlegen

- Karte mit dem **Label vom Board weg** einschieben.
- **Pi 3 und neuer sowie alle Zero-Modelle:** Karte gleitet ohne Klick hinein, zum
  Entnehmen vorsichtig herausziehen.
- **Ältere Modelle:** Karte zum Entriegeln erst hineindrücken.

### Alternative Boot-Medien

Neuere Modelle booten auch von USB-Massenspeicher, über Netzwerk (PXE) oder von **NVMe
über PCIe** – für NVMe siehe `pcie.md`.

⚠️ **Die Reihenfolge muss umgestellt werden.** Ab Werk sucht der Bootloader zuerst die
SD-Karte. Wer von NVMe oder USB starten will, setzt in `raspi-config` unter
`6 Advanced Options` → `A4 Boot Order` die Option `B2 NVMe/USB Boot`. Sonst bootet das
Gerät bei eingelegter Karte weiterhin von dieser – und niemand merkt, dass die SSD gar
nicht genutzt wird. Details in `configuration.md`.

---

## Netzteil

| Modell | Empfohlen | Offizielles Netzteil |
|--------|-----------|----------------------|
| Raspberry Pi 500+ | 5 V / 5 A | 27 W USB-C |
| **Raspberry Pi 5**, Pi 500 | **5 V / 5 A** | 27 W USB-C |
| Raspberry Pi 4B, Pi 400 | 5 V / 3 A | 15 W USB-C |
| Raspberry Pi 3 (alle) | 5 V / 2,5 A | 12,5 W Micro-USB |
| Raspberry Pi 2B | 5 V / 2,5 A | 12,5 W Micro-USB |
| Raspberry Pi 1 (alle) | 5 V / 2,5 A | 12,5 W Micro-USB |
| Raspberry Pi Zero (alle) | 5 V / 2,5 A | 12,5 W Micro-USB |

### Zwei Angaben, die oft fehlen

> ⚠️ **Pi 5 an 5 V / 3 A:** Das Board läuft, aber die **Peripherieversorgung wird auf
> 600 mA begrenzt**. Ein 15-W-Netzteil vom Pi 4 ist damit kein vollwertiger Ersatz – es
> erklärt Symptome wie «USB-SSD wird nicht erkannt» oder «Kamera fällt aus», ohne dass
> Unterspannung gemeldet wird.

> ⚠️ **Die Spannungsangaben gelten am Stecker, nicht am Netzteil.** Spannungsabfall im
> Kabel einrechnen, besonders bei abnehmbaren Kabeln. Ein dünnes oder langes USB-C-Kabel
> ist eine häufige und schwer zu findende Fehlerquelle.

### Nachprüfen statt vermuten (Pi 5)

Die Firmware legt ab, was das Netzteil ausgehandelt hat:

```bash
# Maximalstrom in mA
od -v -An -t x1 /proc/device-tree/chosen/power/max_current | tr -d ' '

# 0 = Peripherie auf die niedrige Grenze gedeckelt
od -v -An -t x1 /proc/device-tree/chosen/power/usb_max_current_enable | tr -d ' '
```

➜ Damit lässt sich der 600-mA-Fall **beweisen**, statt ihn zu vermuten. Weitere
Firmware-Werte in `configuration.md`.

Die Begrenzung lässt sich unter `raspi-config` → *Performance Options* aufheben – aber
**erst das Netzteil richtig wählen, dann allenfalls die Grenze anheben**. Zu wenig Leistung
plus aufgehobene Grenze bedeutet laut Dokumentation Instabilität, Abstürze oder
Datenverlust.

### Einschaltverhalten

Der Pi startet, **sobald Spannung anliegt** – ausser die EEPROM-Einstellungen des Pi 5
sind so geändert, dass er auf den Power-Button wartet.

---

## Peripherie

### USB-Ports sinnvoll belegen

Tastatur und Maus an die **USB-2.0-Ports (schwarz)**, damit die **USB-3.0-Ports (blau)**
für schnelle Geräte frei bleiben – SSD, Kamera, Capture-Hardware.

### Display

| Modell | Ausgänge |
|--------|----------|
| Pi 5, 400, 500, 500+ | 2× Micro-HDMI |
| Pi 4B | 2× Micro-HDMI + 3,5-mm-TRRS (Audio und Composite) |
| Pi 3, 2B, 1 | HDMI + 3,5-mm-TRRS |
| Zero (alle) | Mini-HDMI |

- **Primären Monitor immer an `HDMI0`** anschliessen.
- Pi 4 und neuer: beide HDMI-Ausgänge bis 4K, Bildrate modellabhängig.
- 🔴 **Kein Raspberry Pi unterstützt Video über USB-C** (kein DisplayPort Alt Mode).
  Der USB-C-Port ist ausschliesslich Stromversorgung. Das ist eine der häufigsten
  Fehlannahmen beim Pi 5.

### Audio

- HDMI, USB und Bluetooth funktionieren auf allen Modellen mit der jeweiligen Ausstattung.
- Der **3,5-mm-TRRS-Anschluss existiert nur bei Pi 1 bis 4** und liefert **Line-Pegel,
  keinen Lautsprecherpegel** – ein Verstärker ist nötig.
- **Der Pi 5 hat keinen Klinkenanschluss.** Für Audio am Pi 5: USB, I2S oder HDMI
  (siehe `component-catalog.md`).

### Raspberry Pi Zero – Besonderheiten

- Micro-USB statt USB-A → **Micro-USB-OTG-Adapter** nötig.
- Der Port `PWR IN` ist **nur** für Strom, Geräte an die mit `USB` beschrifteten Ports.
- **Ein Zero versorgt Tastatur und Maus nicht gleichzeitig** (ausser die Tastatur hat ein
  Touchpad) → **aktiven USB-Hub** verwenden.
- ⚠️ **USB-Geräte erst vor dem Booten anstecken.** Anstecken im laufenden Betrieb kann
  die Spannung so weit einbrechen lassen, dass die CPU neu startet.

---

## Netzwerk-Ausstattung nach Modell

| Modell | WLAN | Ethernet |
|--------|------|----------|
| Pi 3B+ und neuer | Dual-Band (2,4/5 GHz) | ja – 300 Mb/s bei 3B+, Gigabit ab 4B |
| Pi 3B | nur 2,4 GHz | ja |
| Pi 3A+ | Dual-Band | nein |
| Pi 1B, 1B+, 2B | nein | ja |
| Keyboard-Computer (400, 500, 500+) | Dual-Band | Gigabit |
| Zero W, Zero 2 W | nur 2,4 GHz | nein |
| CM5, CM4 | Dual-Band (optional) | Gigabit |
| CM3+ und älter | nein | optional |

Fehlende Schnittstellen lassen sich per USB nachrüsten (USB-Ethernet, USB-WLAN).

⚠️ **Nicht jedes Modell kann 5 GHz.** Bei Zero W, Zero 2 W und Pi 3B scheitert die
Verbindung an einem reinen 5-GHz-Netz – ein häufiger Fehler bei Schul-WLANs.

---

## Headless-Provisionierung

Der Regelfall für Sensorik-, Kamera- und Edge-AI-Projekte.

### Was beim ersten Start verfügbar ist

| Zugang | Beim **ersten** Boot | Danach |
|--------|----------------------|--------|
| **SSH** | ✅ | ✅ |
| **Raspberry Pi Connect** | ✅ | ✅ |
| **VNC** | ❌ | ✅ (nur mit Desktop-Image) |

➜ **Mindestens eines von SSH oder Raspberry Pi Connect muss im Imager konfiguriert
werden**, sonst ist ein headless aufgesetzter Pi nach dem Start nicht erreichbar.

⚠️ **VNC ist mit den Lite-Varianten nicht kompatibel.**

### Im Imager vorkonfigurieren

- Hostname (nur Buchstaben, Ziffern, Bindestriche)
- Lokalisierung – setzt zugleich die **WLAN-Regulierungsdomäne**
- Benutzername und Passwort
- WLAN-SSID und Passwort, bei Bedarf «Hidden SSID»
- Fernzugriff: SSH mit Passwort **oder Public Key**
- Raspberry Pi Connect (Auth-Key; persönliche Keys laufen nach **6 Stunden** ab)

**Benutzername:** muss mit einem Buchstaben beginnen, nur Kleinbuchstaben, Ziffern,
Unterstriche und Bindestriche, maximal **31 Zeichen**.

### Erreichbarkeit im Netz

Der Pi meldet seinen Hostnamen per **mDNS**:

```bash
ssh benutzer@hostname.local
# alternativ: hostname.lan
```

> ⚠️ **mDNS setzt voraus, dass das Netz Multicast weiterleitet.** Viele Gast- und
> Schul-WLANs unterbinden das (Client Isolation); dort hilft nur die IP-Adresse oder eine
> DHCP-Reservation am Router. Wege, das Gerät zu finden: `remote-access.md`.

### 🔴 `wpa_supplicant.conf` funktioniert nicht mehr

Ältere Anleitungen empfehlen, eine `wpa_supplicant.conf` in die Boot-Partition zu legen.
**Ab Raspberry Pi OS Bookworm gibt es diese Funktion nicht mehr.** WLAN wird über den
Imager oder später über NetworkManager (`nmcli`) konfiguriert – passend zur Regel in
`SKILL.md`, `nmcli` statt `dhcpcd` zu verwenden.

### SSH von Hand einrichten

Falls der Imager nicht genutzt wurde – auf der Partition `bootfs`:

1. Leere Datei `ssh` anlegen.
2. Datei `userconf.txt` mit einer Zeile anlegen:
   `<benutzername>:<verschluesseltes-passwort>`

```bash
# Passwort-Hash erzeugen
openssl passwd -6
```

⚠️ **Auf macOS** ist die Standardimplementierung **LibreSSL**, die `-6` nicht kennt.
Mit `openssl version` prüfen, notfalls `brew install openssl` und den OpenSSL-Binary
explizit aufrufen.

---

## Network Install

Installiert das OS ohne zweiten Rechner und ohne Kartenleser direkt vom Pi aus.

**Voraussetzungen:**
- Nur **Pi 4B, Pi 5** und die Keyboard-Computer (400, 500, 500+)
- Monitor und Tastatur direkt am Pi
- **Kabelgebundene** Internetverbindung
- Leeres, nicht bootfähiges Speichermedium – sonst bootet der Pi normal

**Start:** leeres Medium einlegen **oder** beim Einschalten die **Shift-Taste** halten.

Bei älterem Bootloader ist vorher ein Bootloader-Update nötig.

---

## Erster Start & Troubleshooting

### Die 5-Minuten-Regel

Bootet der Pi **nicht innerhalb von 5 Minuten**, den Status-LED prüfen. Blinkt sie, geben
die **LED-Blinkcodes** die Ursache an – vollständige Tabelle im
`debugging-playbook.md`, Abschnitt 20.

⚠️ **Auf dem Pi 5 gibt es nur noch eine zweifarbige LED**, und sie blinkt **nur bei
microSD-Zugriff**. Bei einem System auf NVMe bleibt sie ruhig grün – das ist kein Fehler.

### Vorgehen, wenn die LED nicht weiterhilft

1. Wurde von einem **anderen Medium als der SD-Karte** gebootet? Zum Test mit SD-Karte
   starten.
2. SD-Karte **neu beschreiben** – dabei den **Verify-Schritt vollständig durchlaufen
   lassen**, nicht überspringen.
3. Mit dem Imager den **Bootloader neu flashen**, danach das OS erneut schreiben.

### Reihenfolge beim Aufbau

Die Dokumentation nennt eine feste Reihenfolge, die sich als Fehlervermeidung bewährt:

1. Boot-Medium mit OS vorbereiten
2. Boot-Medium einsetzen
3. Peripherie anschliessen
4. **Zuletzt** Strom anschliessen

➜ Das passt zur Isolationsmethode des Skills: erst alles vorbereiten, dann einmal
einschalten – nicht im laufenden Betrieb umstecken.

---

## Herunterfahren

| Aktion | Kommandozeile |
|--------|---------------|
| Herunterfahren | `sudo poweroff` |
| Neu starten | `sudo reboot` |
| Abmelden (Konsole) | `logout` |

**Tastenkürzel:**
- **Pi 5, 500, 500+:** Power-Button **einmal** drücken → Menü; **doppelt** drücken →
  sofort herunterfahren
- **Pi 400:** `Fn` + `F10`

⚠️ Vor dem Trennen der Stromversorgung immer sauber herunterfahren – sonst droht
Dateisystemkorruption auf der SD-Karte.

➜ Was «heruntergefahren» beim Pi 5 elektrisch bedeutet, steht in `pcie.md` unter
**Power States**: Nach `sudo halt` bleiben im Standardfall alle Rails aktiv.

---

## Klassensatz und Flottenbetrieb

Für mehrere identische Geräte – der typische Fall im Unterricht:

1. **Einmal im Imager konfigurieren**, dann für jedes Gerät nur Hostname und ggf.
   Benutzername anpassen. Alle übrigen Einstellungen bleiben erhalten.
2. **SSH mit Public Key** statt Passwort – ein Schlüssel für den ganzen Satz spart das
   Passwort-Handling und ist sicherer.
3. **Hostnamen systematisch vergeben** (`pi-01`, `pi-02`, …). Über mDNS sind die Geräte
   dann ohne IP-Liste erreichbar. 🔴 **Zwingend vor dem ersten Netzkontakt:** Jedes frische
   System heisst `raspberrypi`, und mehrere Geräte mit diesem Namen im selben Netz
   beantworten `raspberrypi.local` unvorhersehbar – ein Befehl landet dann auf dem falschen
   Gerät. Der Fehler tritt bei einem einzelnen Pi nie auf und beim zweiten sofort
   (`remote-access.md`).
4. **OS Lite verwenden**, wo kein Desktop gebraucht wird: 8 GB statt 32 GB, schnellerer
   Start, weniger Angriffsfläche. Achtung: **kein VNC**.
5. **WLAN-Regulierungsdomäne** über die Lokalisierung korrekt setzen – sonst schlagen
   Verbindungen in bestimmten Kanälen fehl.
6. **Netzteile mitbestellen.** Ein Klassensatz Pi 5 mit 15-W-Netzteilen läuft, begrenzt
   aber die Peripherie auf 600 mA – und niemand findet den Fehler.
7. **5-GHz-Fähigkeit prüfen**, wenn das Schul-WLAN kein 2,4 GHz anbietet.

---

## Weitere Ressourcen

- [Getting started](https://www.raspberrypi.com/documentation/computers/getting-started.html)
- [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
- [Raspberry Pi Connect](https://www.raspberrypi.com/documentation/services/connect.html)
- [LED-Blinkcodes](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [Raspberry Pi Forum](https://forums.raspberrypi.com/)
