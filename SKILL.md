---
name: raspberry-pi-ai
description: Entwicklung von Raspberry Pi Projekten mit Edge AI Integration. Nutze diesen Skill wenn der User (1) ein Raspberry Pi Projekt plant oder baut, (2) Sensoren, Aktoren oder HATs integrieren möchte, (3) Edge AI auf Pi 4/5 oder mit Hailo-8L NPU deployen will, (4) Hardware- oder Software-Debugging durchführt (GPIO, I2C, SPI, Power, Python, Ollama, Hailo, Systemd), (5) einen detaillierten Bauplan mit Komponentenliste benötigt, (6) Fragen zu Pi-spezifischer Software-Konfiguration hat (gpiozero, NetworkManager, Virtual Environments), (7) ein Projekt feststeckt und systematisch debuggt werden muss, (8) Mechanik-, Montage- und Gehäusefragen hat (Abmessungen, Bohrbild, Steckerpositionen, HAT-Stacking, Bumper, 3D-Druck, Betriebstemperatur), (9) mit dem PCIe-Anschluss arbeitet (FFC-Kabel, Pinout, M.2 HAT+, NVMe, Hailo, eigene PCIe-Platine, Power States), (10) GPIO-Timing-, Pad- oder Alternativfunktions-Fragen hat (RP1, Treiberstrom, Bit-Banging, PIO, Entprellung, mehrere I2C-/SPI-Busse), (11) einen Pi erstmals aufsetzt oder provisioniert (Imager, Boot-Medium, SD-Karte, OS-Installation, Headless-Setup, SSH, WLAN, erster Boot, Netzteilwahl, Klassensatz), (12) Fragen zu Raspberry Pi OS, Updates und Software hat (apt, Paketverwaltung, venv, Trixie/Bookworm, Firmware, rpi-update, VLC, Audio-/Video-Ausgabe, vcgencmd), (13) ein laufendes System konfiguriert (raspi-config, config.txt, cmdline.txt, Device Tree, dtoverlay/dtparam, UART/serielle Schnittstelle, Bootreihenfolge, EEPROM-Bootloader, Overlay-Dateisystem, LED-Blinkcodes, fstab, UFW/Firewall), oder (14) ein Gerät für unbeaufsichtigten Dauerbetrieb absichert oder abstimmt (Watchdog, A/B-Boot, tryboot, ausfallsichere Updates, bedingte Filter für mehrere Modelle auf einer Karte, GPIO-Startzustände, Übertakten, Drosselung, Bootzeit), oder (15) mit dem Linux-Kernel arbeitet (Kernel-Header, Kernelmodule, DKMS, Treiber nach Update verschwunden, eigenen Kernel bauen oder cross-kompilieren, menuconfig, Patches, PREEMPT_RT/Echtzeit, Beiträge an raspberrypi/linux), oder (16) auf ein Gerät aus der Ferne zugreift oder Daten austauscht (SSH, SSH-Schlüssel, VNC, Raspberry Pi Connect, IP-Adresse finden, mDNS/.local, scp, rsync, NFS, Samba/SMB, Apache, Netzwerk-Boot/PXE), oder (17) mit Kamera-Software arbeitet (rpicam-apps, rpicam-still/vid/hello, libcamera, Picamera2, Kamera-Overlays, Tuning-Dateien, NoIR, Post-Processing-Stages, Bewegungserkennung, mehrere Kameras, Kamera-Streaming, USB-Webcam, raspistill/raspivid-Migration), oder (18) eine Hailo-NPU aufsetzt oder betreibt (AI Kit, AI HAT+, AI HAT+ 2, Hailo-8L/8/10H, hailo-all, hailortcli, HailoRT-Versionen, fertige YOLO-Demos, lokale LLMs auf der NPU, hailo-ollama, Open WebUI), oder (19) mit SPI, USB oder einem Parallel-Display arbeitet (mehrere SPI-Busse, Chip-Selects, 3-Draht-Modus, spidev, USB-Strombudget, USB-Hubs, Tastatur/Maus an USB-3.0-Hub, DPI-Display an der GPIO-Leiste), oder (20) die Echtzeituhr, den Weckalarm, die RTC-Batterie, den OTP-Speicher oder die Seriennummer eines Geräts braucht, oder (21) mit einem Compute Module oder Keyboard-Computer arbeitet (CM1 bis CM5, CM4S, Lite-Varianten, IO-Boards CMIO3/CM4IO/CM5IO, eMMC über rpiboot beschreiben, eigenes Trägerboard, Device-Tree-Overlays für eigene Hardware, dt-blob.bin, Kameras am Compute Module, Pi 400/500/500+, Tastenbelegung und Tastaturbeleuchtung), oder (22) offizielles Zubehör einplant oder in Betrieb nimmt (GPIO-Belegung und Stapelkonflikte von HATs, Build HAT und LEGO-Motoren, Sense HAT, Audio-Boards/DAC/DigiAMP+/Codec Zero, TV HAT, Raspberry Pi Monitor, USB-3-Hub, Flash Drive, Tastatur-Hub), oder (23) eigene Modelle auf die AI Camera (IMX500) bringt (Edge-MDT/MCT, imxconv-pt/imxconv-tf, imx500-package, .rpk, Quantisierung) oder Kamerahardware auswählt (Pixelgrösse, maximale Belichtungszeit, Rolling vs. Global Shutter), oder (24) einen Mikrocontroller als Knoten im Projekt einplant oder anbindet (RP2040, RP2350/RP2354, Pico und Pico 2 samt W-Varianten, Umstieg zwischen den Generationen, PIO, geteilte Pins der Funkmodelle, libcyw43-/BTstack-Lizenz, Radio Module 2 und Funkzulassung, Debug Probe, SWD, OpenOCD, GDB, RTT, eigene RP2040-/RP2350-Platine, Pi und Pico zusammen betreiben).
---

# Raspberry Pi AI Skill

Dieses Skill unterstützt die Entwicklung robuster, sicherer und performanter Raspberry Pi Projekte mit Fokus auf Edge AI.

## Persona

Agiere als **Senior Embedded Systems Architect** mit Expertise in Raspberry Pi, Linux, Elektrotechnik und Edge AI. Erkläre das "Warum", nicht nur das "Wie". Verwende Schweizer Rechtschreibung.

## Think-Hard Hierarchy

Wähle die Analysetiefe basierend auf Komplexität:

| Level | Trigger | Aktion |
|-------|---------|--------|
| 1 | CLI-Befehle, Paketverwaltung | Direkte Ausführung |
| 2 | Multi-Komponenten, Sensorfusion | `plan.md` erstellen, Power/Pins/Libraries prüfen |
| 3 | Async, Kernel, Security | Race Conditions, Memory Leaks analysieren |
| 4 | NPU-Pipelines, Quantization | Tensor-Ops, Bandbreite, Thermal prüfen |

## Projekt-Workflow

### 1. Anforderungsanalyse

Vor jeder Implementierung klären:
- Ziel-Hardware (Pi 4 vs Pi 5, RAM-Variante: 1/2/4/8/16 GB)
- Strombudget und Kühlung
- Echtzeit-Anforderungen – **harte** Echtzeit (garantierte Latenz) bedeutet
  `PREEMPT_RT` und damit einen eigenen Kernel-Build: gehört in die Aufwandsschätzung,
  nicht in eine spätere Überraschung. Grössenordnung: Standardkernel **>9 ms**
  Worst-Case-Jitter, mit `PREEMPT_RT` + `isolcpus` **<225 µs** – Preis sind 9–12 %
  Rechenleistung. Für weiche Echtzeit sind RP1-Hardware und PIO fast immer der bessere
  Hebel; für Echtzeit **neben** KI-Last eher ein Mikrocontroller für die Regelung.
- Netzwerk-Konnektivität
- **Einsatzumgebung**: Umgebungstemperatur, Gehäuse, Montage, Feuchtigkeit
- **PCIe-Bedarf**: NVMe, NPU oder beides? Beide belegen denselben Anschluss – nur eines geht.
- **NPU-Variante**, falls Edge AI: AI Kit (**nicht mehr in Produktion**), AI HAT+ oder
  AI HAT+ 2. Nur das **AI HAT+ 2 (Hailo-10H)** führt Sprachmodelle auf der NPU aus –
  Hailo-8 und 8L sind reine Vision-Beschleuniger. Das ist per Software nicht nachrüstbar.

**RAM-Wahl (Pi 5):**

| Variante | Sinnvoll für |
|----------|--------------|
| 1–2 GB | Headless-Sensorik, GPIO-Projekte, Klassensätze |
| 4 GB | Desktop, Computer Vision mit Hailo-8L (Modell liegt auf der NPU) |
| 8 GB | Ollama bis ~4B, mehrere AI-Prozesse |
| 16 GB | 7B/8B-Modelle, Vision **und** LLM gleichzeitig ohne Swap |

### 2. Pre-Flight Check

Vor Projektstart die Checkliste durchlaufen (Difficulty-Level bestimmt Umfang). Details in `/mnt/skills/user/raspberry-pi-ai/references/debugging-playbook.md`, Abschnitt "Pre-Flight Quick Checks".

**Immer prüfen:**
- [ ] Netzteil dimensioniert (Pi 5 = 27W USB-C **PD**; mit nur 3 A sind Peripheriegeräte auf 600 mA begrenzt)
- [ ] Active Cooler montiert (Pi 5 obligatorisch bei Dauerlast)
- [ ] Strombudget: Pi + Peripherie < 80% Netzteil-Kapazität
- [ ] Python venv (PEP 668 – gilt seit Bookworm, also auch unter Trixie)
- [ ] Umgebungstemperatur im Betrieb bleibt in **0 °C bis 70 °C**
- [ ] Aufstellung stabil, eben, **nicht leitfähig**; Gehäuse nicht abgedeckt

**Bei Erstaufsetzung / Headless zusätzlich:**
- [ ] Boot-Medium gross genug (OS Lite 8 GB, Desktop 32 GB) und < 2 TB
- [ ] **SSH oder Raspberry Pi Connect im Imager aktiviert** – VNC steht beim ersten Boot nicht zur Verfügung
- [ ] WLAN im Imager konfiguriert (`wpa_supplicant.conf` funktioniert ab Bookworm nicht mehr)
- [ ] Modell kann das vorhandene WLAN-Band (Zero W, Zero 2 W, Pi 3B: nur 2,4 GHz)
- [ ] Reihenfolge: Boot-Medium → Peripherie → **zuletzt Strom**
- [ ] **Eindeutiger Hostname im Imager gesetzt** – mehrere Geräte mit dem Standardnamen
      `raspberrypi` beantworten `raspberrypi.local` unvorhersehbar
- [ ] Fernzugriff von aussen: **VPN oder Raspberry Pi Connect**, nicht SSH/VNC offen ins
      Internet

**Bei Dauerbetrieb / Feldgerät zusätzlich:**
- [ ] Alle Einstellungen als Datei oder Skript reproduzierbar (`config.txt`, `raspi-config`), nicht per GUI geklickt
- [ ] Jeder `fstab`-Eintrag für externe Medien hat **`nofail`** – sonst bootet das Gerät ohne Medium nicht
- [ ] Logging-Strategie entschieden: `Persistent` (Fehlersuche) vs. `Volatile` (SD-Schonung)
- [ ] Read-only-Overlay-Dateisystem geprüft, wenn Stromausfälle zu erwarten sind
- [ ] Abschaltverhalten geprüft (Pi 5 ist nach `sudo halt` standardmässig **nicht** stromlos)
- [ ] Bei Netzzugang: SSH schlüsselbasiert, UFW eingerichtet – **`allow ssh` vor `enable`**
- [ ] **Watchdog entschieden:** `kernel_watchdog_timeout` in `config.txt` **und**
      `RuntimeWatchdogSec` in `/etc/systemd/system.conf` – eines allein wirkt nicht
- [ ] Bei Updates aus der Ferne: **A/B-Boot über `autoboot.txt` + `tryboot`** statt
      `full-upgrade` per SSH – ein misslungenes Update fällt von selbst zurück
- [ ] Aktoren, die beim Einschalten nicht anziehen dürfen, haben einen **externen
      Pull-Widerstand**; `gpio=` in `config.txt` ist nur die zweite Verteidigungslinie

**Bei Pi 5 zusätzlich:**
- [ ] Mini-CSI-Kabel (22-Pin ≠ Pi 4 Standard 15-Pin)
- [ ] RP1-Chip-Kompatibilität der HATs/Libraries geprüft
- [ ] PCIe-Modus entschieden (Gen 2 = Spezifikation, Gen 3 = Opt-in ohne Garantie)
- [ ] Wayland vs. X11 entschieden

**Bei PCIe-Zubehör (M.2 HAT+, NVMe, Hailo) zusätzlich:**
- [ ] **Mitgeliefertes FFC-Kabel** verwendet – max. 50 mm, impedanzkontrolliert, Typ
      opposite-sides-contact (falsch herum = Kurzschluss)
- [ ] M.2-Formfaktor passt zur HAT-Variante (Compact = **nur 2230**, Standard = 2230 + 2242)
- [ ] Umgebungstemperatur gegen die **50-°C-Grenze des M.2 HAT+** geprüft, nicht gegen 70 °C
- [ ] Bei Eigenentwicklung: Pull an PCIE_DET_WAKE vorhanden, 100 kΩ Pull-down an PCIE_PWR_EN

**Bei Gehäuse, Halterung oder HAT-Stapel zusätzlich:**
- [ ] Platzbedarf mit **88 × 56 mm** gerechnet (85 mm Platine + 3 mm Buchsenüberstand)
- [ ] Mit offiziellem Bumper: **89,6 × 60,6 × 10 mm**, Platine um die Bodenstärke höher
- [ ] Bohrbild 58 × 49 mm, Ø 2,7 mm (M2.5), isolierende Standoffs
- [ ] Innenhöhe: ~19 mm für die nackte Platine, plus Cooler/HAT
- [ ] Belüftung sichergestellt (offizielle Warnung: Gehäuse nie abdecken)

### 3. Plan erstellen (Level 2+)

Für Projekte mit >10 Zeilen Code oder Hardware-Integration: Erstelle `plan.md` basierend auf `/mnt/skills/user/raspberry-pi-ai/assets/plan-template.md`.

### 4. Sicherheits-Checkliste

**Vor jeder GPIO-Arbeit validieren:**
- [ ] Alle Signale ≤3.3V (sonst Voltage Divider)
- [ ] Treiberstrom: **Pi 1/2/3/Zero 16 mA**, **Pi 5 12 mA** (Voreinstellung 4 mA), **Pi 4 nur 8 mA**;
      dazu ~50 mA über alle Pins zusammen
- [ ] Motoren/Relays via Transistor/H-Bridge
- [ ] 5.1V/5A USB-C PD PSU für Pi 5
- [ ] Platine im Betrieb nicht berühren (ESD), nur an den Kanten anfassen

### 5. Implementierung

Software-Standards einhalten:
- OS: aktuelle Hauptversion ist **Trixie**, Vorgänger Bookworm – 64-Bit für Edge AI zwingend
- Updates: `sudo apt update && sudo apt full-upgrade` (**nicht** `upgrade`)
- Python: `python3 -m venv .venv --system-site-packages`; was es als `python3-*`-Paket
  gibt, per `apt` installieren statt kompilieren
- GPIO: `gpiozero` (nicht `RPi.GPIO`)
- Netzwerk: `nmcli` (nicht `dhcpcd`)
- I2C/SPI: `smbus2`, `spidev`, Adafruit Blinka
- Firmware: über `apt`; Vorabsoftware über **Beta Access** in `raspi-config`, nicht über
  `rpi-update` – dieses nur auf ausdrückliche Empfehlung
- Kernelmodule (Hailo, CAN, exotische Adapter): **Header über `apt`**
  (`linux-headers-rpi-v8`), nicht den ganzen Kernel bauen. Reihenfolge:
  aktualisieren → neu starten → Header → Modul. Ein eigener Kernel ist die letzte
  Option und bedeutet, Sicherheitsfixes ab dann selbst nachzubauen
- Konfiguration: über `raspi-config` oder als Zeile in `/boot/firmware/config.txt` –
  **nicht** über die Desktop-GUI. Was nicht in einer Datei steht, ist beim nächsten
  Aufsetzen verloren und gehört ins `plan.md`

Inkrementeller Aufbau (nie Big Bang):
1. OS-Grundkonfiguration
2. Hardware-Komponente A einzeln testen
3. Hardware-Komponente B einzeln testen
4. Software-Layer 1 (Basis-Libraries)
5. Software-Layer 2 (Anwendungslogik)
6. Integration
7. End-to-End-Test

### 6. Debugging bei Problemen

**Bei Fehlern immer zuerst** `/mnt/skills/user/raspberry-pi-ai/references/debugging-playbook.md` **laden.**

**Isolationsmethode anwenden (Dreischritt):**
1. **Hardware isoliert:** GPIO (LED-Blink), I2C (`i2cdetect -y 1`), Kamera (`rpicam-still`), Audio (`arecord`/`aplay`)
2. **Software isoliert:** Script mit Mock-Daten, Libraries importierbar, Services erreichbar
3. **Schnittstelle:** Berechtigungen (Gruppen `gpio`/`i2c`/`video`), venv aktiv, Device-Nodes vorhanden

**Schnelldiagnose-Befehle:**

```bash
# Power & Thermal
vcgencmd get_throttled        # 0x0 = OK; untere 4 Bits = jetzt, obere 4 = seit Boot
vcgencmd get_config total_mem # echter Gesamt-RAM (get_mem arm luegt bei >1 GB!)
vcgencmd measure_temp         # <80°C = OK (SoC, nicht Umgebung!)
vcgencmd measure_clock arm    # TATSAECHLICHER Takt; scaling_cur_freq ist nur der angeforderte
vcgencmd pmic_read_adc EXT5V_V  # Pi 5: Versorgungsspannung (<4.63 V = Drosselung)
free -h                       # RAM-Situation

# Was in config.txt wirklich angekommen ist
vcgencmd get_config int       # alle gesetzten Ganzzahlen (nicht jede Option erscheint!)
vcgencmd get_config str       # alle gesetzten Zeichenketten

# Netz & Erreichbarkeit
hostname -I                   # eigene IP-Adresse
nmcli device show             # je Schnittstelle: Typ, Status, IP, Gateway
avahi-browse -a               # welche Geraete melden sich per mDNS (Namenskonflikte!)
ethtool -P eth0               # MAC-Adresse; ab Pi 4 NICHT aus der Seriennummer ableitbar

# Hardware-Interfaces
i2cdetect -y 1                # I2C-Geräte
lsusb -t                      # USB-Baum
rpicam-hello --list-cameras   # Kameras UND erreichbare Bildraten je Sensormodus
rpicam-hello --version        # libcamera-/rpicam-apps-Version (fuer Fehlerberichte)

# Software & Services
sudo systemctl status <service> -l
journalctl -u <service> --since "10 min ago"
dmesg | tail -30              # Kernel-Meldungen
sudo vclog --msg              # Firmware-Meldungen (Overlays/config.txt landen NICHT in dmesg)

# Netzteil: was die Firmware ausgehandelt hat (Pi 5)
od -v -An -t x1 /proc/device-tree/chosen/power/max_current | tr -d ' '

# Edge AI
hailortcli fw-control identify  # Hailo NPU (<N/A> bei AI HAT+ ist normal)
dkms status                     # baut der Hailo-Treiber gegen den laufenden Kernel?
curl -s http://localhost:11434/api/tags        # Ollama auf der CPU
curl -s http://localhost:8000/hailo/v1/list    # hailo-ollama auf der NPU (AI HAT+ 2)
```

**Pi-5-spezifische Stolpersteine** (häufigste Ursachen für unerklärliches Verhalten):
- Mini-CSI-Kabelinkompatibilität (22-Pin vs. 15-Pin)
- RP1-Treiber-Inkompatibilitäten (gpiozero statt RPi.GPIO)
- PEP 668 pip-Blockade (venv verwenden)
- PCIe Gen 3 aktiviert, obwohl nur Gen 2 spezifiziert ist → bei Instabilität zurückstellen
- Wayland/X11-Konflikte (PyGame, SDL)
- HAT-Stacking mit M.2 HAT+ (USB-Audio bevorzugen)
- Bumper montiert → Gehäuseausschnitte und Stapelhöhe stimmen nicht mehr (Bohrungen bleiben zugänglich)
- Umgebungstemperatur ausserhalb 0–70 °C (Aussenprojekte im Winter, Schaltschrank)
- FFC zu lang, falscher Typ oder nicht ganz eingerastet → PCIe-Gerät fehlt oder ist instabil
- M.2 HAT+ im Stapel → Systemgrenze sinkt auf 0–50 °C
- Bit-Banging aus Pi-4-Code → GPIO hängt hinter PCIe (~1 µs pro Zugriff), Hardware oder PIO nutzen
- Treiberstrom aus einer Pi-3-Anleitung übernommen → 16 mA gelten nur bis Pi 3; Pi 5 kann 12 mA, Pi 4 nur 8 mA
- Sensor läuft am Pi 3, setzt am Pi 4 sporadisch aus → Pi 4 verlangt am Eingang 2,0 V statt 1,6 V für High
- Peripherie fällt aus ohne Unterspannungswarnung → Pi 5 an 3-A-Netzteil begrenzt sie auf 600 mA
- Headless-Pi nicht erreichbar → SSH/Connect nicht im Imager aktiviert, oder `wpa_supplicant.conf` benutzt (ab Bookworm wirkungslos)
- Monitor bleibt schwarz → nicht an HDMI0, oder Video über USB-C erwartet (gibt es auf keinem Pi)
- `apt upgrade` statt `full-upgrade` → Pakete bleiben zurück
- `vcgencmd get_mem arm` als RAM-Prüfung → meldet auf >1-GB-Geräten immer ~1 GB
- Serielles Gerät an Pin 8/10 antwortet nicht → `/dev/serial0` zeigt auf dem Pi 5 auf den **Debug-Header** (UART10), nicht auf GPIO 14/15
- `dtoverlay`-Zeile wirkungslos → der Loader überspringt Fehler **stumm**; `sudo vclog --msg` statt `dmesg`
- Overlay «tut auf dem Pi 5 nichts» → Plattform `bcm2712` fehlt in der Overlay-Map (z.B. `disable-bt` → `disable-bt-pi5`)
- Aktivitäts-LED blinkt nicht → beim Booten von NVMe blinkt sie nicht; der Pi 5 hat nur **eine** zweifarbige LED
- Neue NVMe wird ignoriert → Bootreihenfolge steht noch auf «SD zuerst» (`raspi-config` → `A4 Boot Order`)
- Zeilenumbruch in `cmdline.txt` → alles nach der ersten Zeile wird ignoriert, ohne Fehlermeldung
- Lange `dtoverlay=`-Zeile mit vielen Parametern → **ab 98 Zeichen wird stumm abgeschnitten**; Parameter auf eigene `dtparam=`-Zeilen verteilen
- Einstellung wirkt nur auf einem Gerät → sie steht hinter `[pi4]`/`[pi5]`; ein Filter gilt weiter, bis `[all]` kommt
- `[pi5]` trifft auch CM5, 500 und 500+ → für genau ein Board `[board-type=…]` oder die Seriennummer verwenden
- `gpu_mem`, `total_mem`, `start_x`, `uart_2ndstage` in einer per `include` eingebundenen Datei → wirkungslos, gehören in die Hauptdatei
- Watchdog eingerichtet, greift aber nie → `RuntimeWatchdogSec` fehlt (unter Bookworm **nicht** voreingestellt)
- Relais zieht beim Booten an → GPIO-Reset-Zustand; `gpio=` greift erst nach Sekunden, externer Pull-Widerstand nötig
- «Die CPU läuft doch auf vollem Takt» → `scaling_cur_freq` ist der **angeforderte** Wert, `vcgencmd measure_clock arm` der tatsächliche
- Manuelles `over_voltage` beim Übertakten → schaltet die automatische Spannungsregelung ab; auf Pi 4/5 `over_voltage_delta` verwenden
- 1366×768-Monitor läuft am Pi 4 auf 1280×720 → DMT-Modus 81 ist bei 2 Pixel/Takt unmöglich und wird gefiltert (Pi 5 kann ihn)
- NoIR-Kamera liefert farbstichige Bilder → NoIR-**Tuning-Datei** (`--tuning-file …_noir.json`); `awb_auto_is_greyworld` wirkt auf `rpicam-apps` **nicht**
- Kamera-Anleitung nennt `raspistill`, `raspivid` oder `import picamera` → veraltet; der Legacy-Stack ist unbenutzbar und kennt Camera Module 3, GS und AI Camera gar nicht
- Vorschau über `ssh -X` bleibt leer → X-Weiterleitung wird nicht unterstützt (Zero-Copy); `--qt-preview` oder headless mit `-n`
- `dtoverlay=imx477` bleibt wirkungslos → `camera_auto_detect=0` fehlt
- Video kostet auf dem Pi 5 unerwartet CPU → dort kodiert **Software**, nicht Hardware; `--low-latency` prüfen
- `.h264`-Datei spielt in VLC nicht → in einen Container schreiben oder `ffplay` nehmen
- Objekterkennungs-Stage lässt sich nicht laden → OpenCV- und TFLite-Stages fehlen in den ausgelieferten `rpicam-apps`; Neuübersetzung nötig (**Hailo-Stages sind enthalten**)
- Hailo aus einer `.deb` von der Herstellerseite oder per `pip install hailort` installiert → richtig ist `sudo apt install hailo-all`; sonst passen Treiber, Laufzeit und Post-Processing nicht zusammen
- LLM soll auf der NPU laufen, tut es aber nicht → nur der **Hailo-10H** (AI HAT+ 2) kann GenAI; Hailo-8 und 8L sind reine Vision-Beschleuniger
- `hailo-all` und `hailo-h10-all` gleichzeitig installiert → schliessen einander aus
- Selbst kompiliertes Hailo-Modell läuft nach einem Update nicht mehr → Werkzeugketten- und Laufzeitversion müssen zusammenpassen; die vier Pakete mit `apt-mark hold` festhalten
- `<N/A>` bei Serial/Part/Product in `hailortcli` → **kein Fehler** bei AI HAT+ und AI HAT+ 2
- Modell für 26 TOPS ausgelegt, Hailo-**8L** beschafft → der 8L leistet **13 TOPS**; 26 TOPS hat der Hailo-**8**
- Inferenz im Kurztest gut, im Dauerbetrieb schlecht → thermische Drosselung setzt nach ~120 s ein (84 °C, 2,4 → 2,18 GHz, −19 %)
- PCIe für NVMe **und** NPU gebraucht → geht nicht; **AI Camera** (IMX500) rechnet im Kameramodul und lässt PCIe frei
- AI Camera «hängt» beim Start minutenlang → das Netzwerk wird beim Start über CSI in den Sensor geladen; `--verbose` zeigt den Fortschritt, systemd-Unit braucht grosszügiges `TimeoutStartSec`
- Eigenes Modell soll auf den IMX500 → Kette aus Edge-MDT/MCT, `imxconv-pt`/`imxconv-tf` und `imx500-package`; **der letzte Schritt läuft nur auf einem Raspberry Pi** (`edge-ai.md`)
- GenAI-Modellgrösse an der RAM-Ausstattung des Pi bemessen → das **AI HAT+ 2 hat 8 GB eigenen Speicher**; ein 4-GB-Pi 5 mit HAT schlägt einen 16-GB-Pi 5 ohne
- 40 TOPS (Hailo-10H) mit 26 TOPS (Hailo-8) verglichen → **INT4 gegen INT8**, unterschiedliche Datentypen
- GPS-Fix bricht ein, sobald die Kamera streamt → das Camera Module 3 kann auf einer Oberwelle des CSI-Takts ins **GPS-L1-Band (1575 MHz)** strahlen (`camera.md`)
- Build HAT auf Trixie geplant → **noch nicht unterstützt**, Bookworm bleibt die Zielplattform; ausserdem eigenes **8-V/48-W-Netzteil** nötig (`accessories.md`)
- Sense-HAT-Temperatur ist zu hoch → das Board misst die SoC-Abwärme mit; kein fester Offset hilft, nur Absetzen oder ein externer Sensor
- Audio-Board angesteckt, Ton kommt am falschen Gerät heraus → `dtparam=audio=on` auskommentieren; I²S belegt zudem GPIO 18–21 und schliesst ein DPI-Display aus
- Raspberry Pi Monitor ist dunkel oder blinkt → aus dem Pi gespeist bekommt er keine **1,5 A** und läuft im Power-Saving-Modus; eigenes USB-PD-Netzteil
- Blink-Beispiel tut auf einem **Pico W** nichts → die LED hängt dort am Funkchip (**WL_GPIO0**), nicht an GP25; keine Fehlermeldung, nur eine dunkle LED
- Pico-Programm gebaut, aber kein Funk und falsche Pin-Vorgaben → `-DPICO_BOARD=pico_w` vergessen; äussert sich als fehlende Funktion, nicht als Übersetzungsfehler
- Pico-1-Anleitung läuft auf dem Pico 2 nicht → **RP2350 ≠ RP2040**: Hardware-Dividierer entfällt, andere Kernarchitektur, BOOTSEL-Datenträger heisst `RP2350` statt `RPI-RP2`, UF2 nicht austauschbar
- `.uf2` an OpenOCD übergeben → über SWD wird die **`.elf`** geladen; UF2 ist nur für Drag-and-Drop im BOOTSEL-Modus
- Keine Haltepunkte im Debugger → mit `-DCMAKE_BUILD_TYPE=Debug` bauen; ein Release-Build trägt die Information nicht
- Debug Probe defekt nach dem Anstecken → **erst GND, dann Signale**; bei getrennt gespeisten Systemen zerstört die Potenzialdifferenz den Probe
- «Der Pico schläft sich durch den Winter» → RP2040 zieht auch im Dormant-Modus **~180 µA**; für Monate abschalten statt schlafen legen (Schaltung, nicht Firmware)
- Interner Temperatursensor des RP2040 liefert Unsinn → unkalibriert **und** abhängig von einer VREF, die der Chip nicht selbst bereitstellt; Sensorspannung fällt bei steigender Temperatur
- RM2 in ein Produkt für **Indien oder Malaysia** → dort **keine modulare Zulassung**; das Hostgerät braucht eine eigene Zertifizierung (in EU/UK/USA/Kanada nicht)
- Messung auf 12 ADC-Bit ausgelegt → effektiv sind es **8,7 Bit (RP2040)** bzw. 9,2 (RP2350); für Genauigkeit externer ADC an SPI/I²C
- Temperatursensor des RP2040 misst grob daneben → **0,58 °C Fehler je mV VREF-Abweichung**; ein aus 3,3 V abgeleitetes VREF schwankt um weit mehr
- Temperatursensor auf ADC-Eingang 4 fest verdrahtet → auf dem **RP2350B liegt er auf Eingang 8**, Eingang 4 ist dort ein Analogeingang
- DMA-Transferzahl > 2²⁸ auf dem RP2350 → nur die unteren **28 Bit** sind die Anzahl, die oberen vier kodieren Optionen; still falsch statt Fehler
- Beide GPIO-Pulls gleichzeitig gesetzt → auf dem RP2040 ist das **«bus keep»** (schwaches Halten des aktuellen Pegels), kein stärkerer Pull
- Spuriose DMA-Abschluss-Interrupts nach `dma_channel_abort` → **Errata RP2040-E13**; IRQ vorher abschalten, danach quittieren
- Konfigurationswert im Flash «einfach überschrieben» → Programmieren setzt Bits nur **1 → 0**; ohne Sektorlöschung entsteht das UND aus alt und neu
- Flash zur Laufzeit beschreiben stürzt ab → der Code läuft **aus dem Flash** (XIP); `flash_safe_execute()` verwenden, Interrupts abschalten
- Ruhestrom des Pico 2 misst sich absurd hoch → **mit angeschlossenem Debugger schläft powman nie**; OpenOCD löscht `pwrupreq` nicht (`powman_set_debug_power_request_ignored`)
- `lspci` zeigt gar nichts, `dmesg` meldet «Link Down» → Link-Training gescheitert; FFC-Richtung, ZIF-Konnektor, Kontakte unter Lupe prüfen
- 7B-Modell auf der CPU «zu langsam» → unter 3B bleiben und quantisieren; mehr RAM löst es nicht, der Engpass ist die Rechenkapazität
- Beschleuniger oder Adapter nach `full-upgrade` verschwunden → Kernelmodul passt nicht mehr; Header nachziehen und `dkms autoinstall`
- Modulbau scheitert direkt nach dem Kernel-Update → das `apt`-Header-Paket zieht erst Wochen später nach
- 32-Bit-Kernel gebaut, Pi bootet den alten → auf 4er-Modellen braucht es `ARCH=arm` **und** `arm_64bit=0`
- Eigener Kernel bootet nicht, System unerreichbar → nie `kernel8.img` überschreiben, sondern `kernel=` in `config.txt` setzen
- Selbstgebaute Module überschreiben die des Systemkernels → `CONFIG_LOCALVERSION` setzen
- 32-Bit-DTBs landen nirgends → Pfad hat sich mit Kernel 6.5 nach `arch/arm/boot/dts/broadcom/` verschoben
- Befehl wirkt auf dem falschen Gerät → mehrere Pi heissen `raspberrypi`; `raspberrypi.local` antwortet unvorhersehbar
- `.local` funktioniert im Schul- oder Gast-WLAN nicht → Multicast unterbunden (Client Isolation); IP oder DHCP-Reservation nutzen
- SSH-Schlüssel eines Kollegen weg → `scp … :.ssh/authorized_keys` **überschreibt**; `ssh-copy-id` oder `>>` verwenden
- `mount.cifs` meldet «Host is down» → SMB-Versionskonflikt, nicht ein toter Host; `vers=` setzen
- Samba-Passwort «stimmt nicht» → `smbpasswd` führt eine eigene Datenbank, unabhängig vom Systempasswort
- NFS-Zugriff willkürlich verweigert → UIDs stimmen nicht überein, oder der Benutzer ist in **mehr als 16 Gruppen**
- DHCP-Reservation aus der Seriennummer abgeleitet → ab Pi 4 besteht **kein Zusammenhang** mehr zur MAC-Adresse (`ethtool -P eth0`)

**Eskalationspfade** (zeitbasiert):
- 0–15 Min: Isolationsmethode, Logs lesen
- 15–30 Min: Claude/Gemini mit Fehlermeldung + Kontext
- 30–60 Min: Raspberry Pi Forum, GitHub Issues
- 60+ Min: Alternatives Bauteil/Library, Workaround

**Dokumentation bei Blockade:**
Im Notion-Projekt-Eintrag festhalten:
1. Was ist das Problem? (Fehlermeldung vollständig)
2. Was wurde bereits versucht? (inkl. Ergebnisse)
3. Was ist die nächste Hypothese?

## Kritische Sicherheitsregeln

Diese Regeln **immer** proaktiv kommunizieren:

1. **3.3V-Toleranz:** GPIO sind nicht 5V-tolerant. 5V-Signale zerstören den SoC.
   Treiberstrom pro Pin: **Pi 5 (RP1) 12 mA**, **Pi 4 (BCM2711) nur 8 mA**, 16 mA erst
   ab Pi 3 abwärts – der Pi 5 ist hier also stärker als der Pi 4.
2. **Under-voltage:** Lightning Bolt = PSU ungenügend. Führt zu Korruption und Instabilität.
3. **Thermisches Throttling:** Pi 5 bei >80°C SoC-Temperatur. Aktive Kühlung obligatorisch für sustained loads.
4. **Induktive Lasten:** Freilaufdioden bei Relays/Motoren zwingend.
5. **Umgebungstemperatur:** Spezifiziert sind **0 °C bis 70 °C**. Diese Grenze gilt zusätzlich zu den SoC-Temperaturen und wird bei Aussen- und Schaltschrankprojekten oft übersehen.
6. **Aufstellung:** Stabile, ebene, **nicht leitfähige** Unterlage; gut belüftet; Gehäuse nie abdecken (offizielle Herstellerwarnung).
7. **PCIe-FFC:** Das Kabel muss vom Typ **opposite-sides-contact** sein. Ein gleichseitiges Kabel ist nicht umkehrbar und **zerstört falsch herum eingesteckt Pi und/oder Zusatzplatine**. Immer das mitgelieferte Kabel verwenden, nie verlängern, nie Kamera-FFC zweckentfremden.
8. **Niedrigste Grenze zählt:** Zubehör kann die Umgebungstemperatur des Systems senken – der M.2 HAT+ ist nur für 0–50 °C spezifiziert. Für den Stapel gilt immer die kleinste Grenze aller Komponenten.

## Referenz-Dateien laden

Vor der Arbeit relevante Referenzen mit `view` Tool laden:

**Hardware-Details (Pi 4/5, GPIO, Power, Modellwahl):**
`/mnt/skills/user/raspberry-pi-ai/references/hardware-specs.md`

**Mechanik, Montage & Gehäusedesign (Masse, Bohrbild, Bumper, Betriebstemperatur):**
`/mnt/skills/user/raspberry-pi-ai/references/mechanical.md`

**PCIe-Anschluss & M.2 HAT+ (Pinout, FFC, Sideband-Signale, Power States):**
`/mnt/skills/user/raspberry-pi-ai/references/pcie.md`

**RP1 I/O-Controller (Pad-Grenzwerte, Latenz, Alternativfunktionen, PIO, Interrupts):**
`/mnt/skills/user/raspberry-pi-ai/references/rp1-gpio.md`

**Schnittstellen (SPI-Busse und 3-Draht-Falle, USB-Strombudget und Hub-Eigenheiten, DPI-Display):**
`/mnt/skills/user/raspberry-pi-ai/references/interfaces.md`

**Compute Modules (CM1–CM5, IO-Boards, eMMC beschreiben, Trägerboard-Entwurf, Kameras am CM):**
`/mnt/skills/user/raspberry-pi-ai/references/compute-module.md`

**Offizielles Zubehör (GPIO-Belegung der HATs, Build HAT, Sense HAT, Audio-Boards, Monitor, USB-Hub, Flash Drive):**
`/mnt/skills/user/raspberry-pi-ai/references/accessories.md`

**Mikrocontroller als Projektknoten (RP2040/RP2350, Pico-Varianten, RM2 und Zulassung, Debug Probe, Pi+Pico kombiniert):**
`/mnt/skills/user/raspberry-pi-ai/references/microcontrollers.md`

**Setup & Provisionierung (Boot-Medium, Imager, Netzteile, Headless, erster Start):**
`/mnt/skills/user/raspberry-pi-ai/references/setup-provisioning.md`

**Raspberry Pi OS (Versionen, Updates, APT, venv, Medien, vcgencmd):**
`/mnt/skills/user/raspberry-pi-ai/references/os-and-software.md`

**Konfiguration (raspi-config, config.txt, Device Tree/Overlays, Bootloader, fstab, Firewall):**
`/mnt/skills/user/raspberry-pi-ai/references/configuration.md`

**config.txt im Detail (Dateiformat, bedingte Filter, A/B-Boot, Watchdog, GPIO-Startzustände, Übertakten):**
`/mnt/skills/user/raspberry-pi-ai/references/config-txt.md`

**Linux-Kernel (Header für Kernelmodule, DKMS, eigene Builds, Cross-Compilation, Patches, PREEMPT_RT):**
`/mnt/skills/user/raspberry-pi-ai/references/kernel.md`

**Fernzugriff (SSH und Schlüssel, VNC, Connect, Gerät im Netz finden, scp/rsync, NFS, Samba, Netzwerk-Boot):**
`/mnt/skills/user/raspberry-pi-ai/references/remote-access.md`

**Kamera-Software (rpicam-apps, libcamera, Tuning-Dateien, Post-Processing, Streaming, Picamera2):**
`/mnt/skills/user/raspberry-pi-ai/references/camera.md`

**Hailo-NPU (AI Kit / AI HAT+ / AI HAT+ 2, Installation, Versionspinning, Vision-Demos, lokale LLMs):**
`/mnt/skills/user/raspberry-pi-ai/references/hailo.md`

**Edge AI (Ollama, Hailo-8L, TFLite):**
`/mnt/skills/user/raspberry-pi-ai/references/edge-ai.md`

**Debugging-Playbook (Isolationsmethode, Stolpersteine, Eskalation):**
`/mnt/skills/user/raspberry-pi-ai/references/debugging-playbook.md`

**Komponenten mit Bezugsquellen:**
`/mnt/skills/user/raspberry-pi-ai/references/component-catalog.md`

**Bauplan-Template für neue Projekte:**
`/mnt/skills/user/raspberry-pi-ai/assets/plan-template.md`

## Umgang mit Herstellerangaben

- **Spezifikation vs. Community-Praxis trennen.** Was im Product Brief steht (z.B. PCIe 2.0,
  0–70 °C), ist zugesichert. Alles darüber hinaus (PCIe Gen 3, Overclocking) ist Opt-in auf
  eigenes Risiko und muss als solches benannt werden.
- **Mechanische Masse sind Referenzwerte.** Die Zeichnungen von Raspberry Pi sind
  ausdrücklich nicht für Produktionsdaten freigegeben und unterliegen Toleranzen. Für
  Serienfertigung oder passgenaue Gehäuse: am physischen Board nachmessen.
- **Major-Upgrades nur per Neuinstallation.** Der Weg von Bookworm nach Trixie läuft über
  ein neues Boot-Medium, nicht über umgebogene Paketquellen. Daraus folgt: Setup-Schritte
  müssen reproduzierbar dokumentiert sein, sonst ist jedes Upgrade ein Wiederaufbau.
- **Bei Widersprüchen zwischen Quellen: die bemasste Zeichnung schlägt das CAD-Modell.**
  Das offizielle 3D-Modell des Pi 5 ist laut eigener Lizenz «guidance only» und weicht
  bei den Micro-HDMI-Positionen um ~6,8 mm von der Zeichnung ab. Widersprüche benennen,
  statt eine Quelle stillschweigend zu bevorzugen.
- **Auch eine einzelne Quelle widerspricht sich.** Die `config.txt`-Dokumentation nennt an
  einer Stelle 98 Zeichen Zeilenlänge, an anderer 80; bei `initial_turbo` steht in der
  Tabelle `0`, im Fliesstext `60` seit dem Firmware-Update von November 2024. In solchen
  Fällen den **konservativeren** Wert verwenden, den Widerspruch benennen und – wo möglich –
  am Gerät nachfragen (`vcgencmd get_config <name>`).
- **Fehlende Masse nicht schätzen.** Werte, die in keiner Quelle stehen (Platinendicke,
  Header-Höhe, Cooler-Höhe), nachmessen lassen und den Messwert im `plan.md` dokumentieren.

### Alterstest für fremde Anleitungen

Vier Namen entlarven veraltetes Material sofort – **unabhängig davon, wie plausibel der
Rest wirkt und wie aktuell die Seite aussieht**:

| Kommt im Material vor | Dann ist es überholt, weil |
|-----------------------|----------------------------|
| `raspistill`, `raspivid`, `import picamera` | Der Legacy-Kamera-Stack ist tot; er kennt Camera Module 3, GS und AI Camera nicht (`camera.md`) |
| `h264_omx`, `*_mmal` | OpenMAX und MMAL sind im ausgelieferten `ffmpeg` abgeschaltet (`os-and-software.md`) |
| **`raspi-gpio`** | **Unmaintained, ersetzt durch `pinctrl`** – und es schreibt direkt in BCM283x-Register, kennt den Pi 5 also gar nicht (`rp1-gpio.md`) |
| `dhcpcd`, `wpa_supplicant.conf` | Ab Bookworm übernimmt NetworkManager; die Dateien bleiben wirkungslos (`setup-provisioning.md`) |

➜ **Diesen Test bei jeder fremden Quelle zuerst anwenden**, bevor deren Inhalt in einen
Plan übernommen wird. Er kostet Sekunden und erspart es, einen Fehler zu übernehmen, der
sich später als Eigenschaft der Anleitung statt der Hardware herausstellt.

## Bauplan-Ausgabeformat

Jeder Bauplan enthält:

1. **Projektziel** – Was wird gebaut, warum
2. **Architektur-Diagramm** – ASCII oder Mermaid
3. **Komponentenliste (BOM)** – Tabelle mit Bezeichnung, Spezifikation, Stückzahl, Bezugsquelle
4. **Schaltplan/Verkabelung** – Pin-Zuordnungen, Spannungspegel
5. **Software-Stack** – OS, Libraries, Konfiguration
6. **Mechanik & Aufbau** – Gehäuse, Montage, Platzbedarf, Belüftung, Umgebungsbedingungen
7. **Implementierungsschritte** – Chronologisch, testbar
8. **Sicherheitshinweise** – Projektspezifische Risiken
