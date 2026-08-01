# Debugging-Playbook für Raspberry Pi Projekte

## Inhaltsverzeichnis
1. [Isolationsmethode](#isolationsmethode)
2. [Pi-5-spezifische Stolpersteine](#pi-5-spezifische-stolpersteine)
3. [Software-Debugging](#software-debugging)
4. [Hardware-Debugging](#hardware-debugging)
5. [Edge-AI-Debugging](#edge-ai-debugging)
6. [Eskalationspfade](#eskalationspfade)
7. [Stalled-Projekt-Analyse](#stalled-projekt-analyse)
8. [Pre-Flight Quick Checks](#pre-flight-quick-checks)

---

## Isolationsmethode

Die zentrale Debugging-Strategie: Nie Hardware und Software gleichzeitig debuggen. Immer isolieren, dann integrieren.

### Dreischritt-Verfahren

**Schritt 1 – Hardware isoliert testen:**

```bash
# GPIO: LED-Blink-Test (ohne Anwendungscode)
python3 -c "from gpiozero import LED; led = LED(17); led.blink()"

# I2C: Bus scannen
i2cdetect -y 1

# SPI: Loopback-Test (MOSI → MISO verbinden)
# Wenn Daten zurückkommen → SPI funktioniert

# Kamera: Einzelbild aufnehmen
rpicam-still -o test.jpg

# Audio-Eingang: 5 Sekunden aufnehmen
arecord -D plughw:1,0 -d 5 -f cd test.wav

# Audio-Ausgang: Testton abspielen
aplay test.wav
speaker-test -t wav -c 2
```

**Schritt 2 – Software isoliert testen:**

```bash
# Script mit Mock-Daten laufen lassen (kein Hardware-Zugriff)
python3 -c "import numpy; print(numpy.__version__)"

# Libraries importierbar?
python3 -c "import cv2; import tflite_runtime; print('OK')"

# Ollama erreichbar?
curl http://localhost:11434/api/tags

# FastAPI/Webserver erreichbar?
curl http://localhost:8000/health
```

**Schritt 3 – Schnittstelle testen:**

```bash
# Berechtigungen: User in richtigen Gruppen?
groups $USER
# Erwartung: gpio i2c spi video audio

# Virtual Environment aktiv?
which python3
# Muss auf .venv/bin/python3 zeigen, nicht /usr/bin/python3

# Device-Nodes vorhanden?
ls -la /dev/i2c-* /dev/spidev* /dev/video* 2>/dev/null

# udev-Regeln greifen? (z.B. USB-Audio)
udevadm info --query=all --name=/dev/snd/controlC1
```

### Entscheidungsbaum

```
Problem aufgetreten
├── Hardware-Vermutung?
│   ├── Ja → Schritt 1 (Hardware isoliert)
│   │   ├── Hardware OK → Schritt 3 (Schnittstelle)
│   │   └── Hardware FAIL → Hardware-Debugging (Abschnitt 4)
│   │
│   └── Nein → Schritt 2 (Software isoliert)
│       ├── Software OK → Schritt 3 (Schnittstelle)
│       └── Software FAIL → Software-Debugging (Abschnitt 3)
│
└── Unsicher?
    └── Schritt 1 → Schritt 2 → Schritt 3 (alle drei)
```

---

## Pi-5-spezifische Stolpersteine

Diese Probleme treten **nur** auf dem Pi 5 auf und sind die häufigsten Ursachen für unerklärliches Fehlverhalten.

PCIe-Details (Pinout, FFC-Anforderungen, Sideband-Signale, M.2 HAT+): `pcie.md`.
RP1-Pads, Latenzverhalten und Alternativfunktionen: `rp1-gpio.md`.
Boot-Medium, Netzteilwahl, Headless-Provisionierung und erster Start: `setup-provisioning.md`.

### 1. Mini-CSI-Kabelinkompatibilität

**Symptom:** Kamera wird nicht erkannt, `rpicam-hello --list-cameras` zeigt keine Kamera.

**Ursache:** Pi 5 verwendet Mini-CSI-Anschlüsse (22-Pin, schmal), Pi 4 verwendet Standard-CSI (15-Pin, breit). Standard-HQ-Kamerakabel passen physisch nicht.

**Lösung:**
```bash
# Kamera-Anschluss prüfen
rpicam-hello --list-cameras

# Falls "No cameras available":
# → 22-Pin-auf-15-Pin-Adapterkabel verwenden
# → Oder Kamera mit nativem Mini-CSI-Kabel (Camera Module 3)
```

### 2. RP1 I/O-Controller Treiber-Inkompatibilitäten

**Symptom:** HAT funktioniert auf Pi 4, aber nicht auf Pi 5. GPIO-Libraries werfen Fehler.

**Ursache:** Pi 5 verwendet den RP1-Chip als separaten I/O-Controller (nicht mehr im SoC integriert). Ältere Treiber und Libraries kennen den RP1 nicht.

**Lösung:**
```bash
# Kernel-Version prüfen (mindestens 6.6 erforderlich)
uname -r

# gpiozero statt RPi.GPIO verwenden (RPi.GPIO ist inkompatibel mit Pi 5)
python3 -c "from gpiozero import Device; print(Device.pin_factory)"
# Erwartung: lgpio oder rpigpio

# lgpio installiert?
dpkg -l | grep lgpio
```

### 3. PEP 668 – Systemweite pip-Blockade

**Symptom:** `pip install` schlägt fehl mit "externally-managed-environment".

**Ursache:** Raspberry Pi OS Bookworm folgt PEP 668 und blockiert systemweite pip-Installationen.

**Lösung:**
```bash
# RICHTIG: Virtual Environment erstellen
python3 -m venv .venv --system-site-packages
source .venv/bin/activate
pip install <package>

# FALSCH (nie verwenden auf Bookworm):
# pip install --break-system-packages <package>
# sudo pip install <package>
```

### 4. PCIe: Gen 3 nicht aktiviert – oder zu Unrecht aktiviert

**Symptom A:** Hailo-8L NPU oder NVMe SSD langsamer als erwartet.

**Ursache:** Pi 5 bootet mit PCIe Gen 2. Gen 3 muss explizit aktiviert werden.

**Lösung:**
```bash
# PCIe Gen 3 aktivieren
echo "dtparam=pciex1_gen=3" | sudo tee -a /boot/firmware/config.txt
sudo reboot

# Verifikation
sudo lspci -vv | grep -i "LnkSta:"
# Erwartung: Speed 8GT/s (Gen3), Width x1
```

**Symptom B (häufiger übersehen):** Gerät verschwindet sporadisch, I/O-Fehler,
`dmesg`-Meldungen mit `AER`, `link training` oder `Bus error`.

**Ursache:** Der Product Brief spezifiziert für den Pi 5 nur **PCIe 2.0 x1**. Gen 3 ist ein
Opt-in ausserhalb der Spezifikation – Signalintegrität ist nicht zugesichert und hängt von
Kabel, HAT und Exemplar ab.

**Lösung – immer als erstes prüfen, bevor Treiber oder Hardware verdächtigt werden:**
```bash
# Gen-3-Zeile entfernen bzw. auskommentieren
sudo sed -i 's/^dtparam=pciex1_gen=3/#dtparam=pciex1_gen=3/' /boot/firmware/config.txt
sudo reboot

# Verifikation: Gen 2 = 5GT/s, stabil
sudo lspci -vv | grep -i "LnkSta:"

# PCIe-Fehler im Kernel-Log
dmesg | grep -iE "pcie|aer|hailo|nvme" | tail -30
```
Läuft das Gerät auf Gen 2 stabil, war Gen 3 die Ursache. Lieber stabil mit Gen 2 als
sporadisch schnell mit Gen 3.

### 5. Wayland vs. X11 Grafikprobleme

**Symptom:** PyGame zeigt schwarzes Fenster, Latenz bei Display-Output, Fenster wird nicht gerendert.

**Ursache:** Bookworm verwendet standardmässig Wayland (labwc). PyGame und ältere SDL-Anwendungen haben Kompatibilitätsprobleme.

**Lösung:**
```bash
# Aktuellen Display-Server prüfen
echo $XDG_SESSION_TYPE
# "wayland" oder "x11"

# Auf X11 zurückschalten (falls nötig)
sudo raspi-config
# → Advanced Options → Wayland → X11

# Oder: SDL-Backend explizit setzen
export SDL_VIDEODRIVER=x11
```

### 6. HAT-Stacking-Konflikte mit M.2 HAT+

**Symptom:** Audio-HAT + M.2 HAT+ (NVMe/Hailo) funktionieren einzeln, aber nicht zusammen.

**Ursache:** Physische Stapelhöhe, thermische Probleme, GPIO-Pin-Konflikte, RP1-Treiber-Interferenzen.

**Lösung:**
- USB-Audio (ReSpeaker USB Array v2.0) statt GPIO-Audio-HAT bevorzugen
- I2C-Adressen auf Kollisionen prüfen: `i2cdetect -y 1`
- SPI Chip-Select-Leitungen verifizieren
- Stapelhöhen prüfen: Bohrbild 58 × 49 mm, Standoff-Längen der Kits sind auf die **nackte**
  Platine ausgelegt (siehe `mechanical.md`)

### 7. Mechanik: Bumper, Gehäuse und Steckerüberstand

**Symptom:** HAT sitzt schief oder rastet nicht ein, Header greift zu kurz, Gehäusedeckel
schliesst nicht, Netzwerkstecker lässt sich nicht einstecken.

**Ursache:**
- Der offizielle **Bumper** vergrössert den Fussabdruck auf 89,6 × 60,6 mm bei 10 mm
  Nennhöhe und hebt die Platine um die Bodenstärke (2,20 mm) an. Ausschnitte und
  Stapelhöhe stimmen dann nicht mehr. Die Befestigungsbohrungen bleiben zugänglich.
- Die **USB-/Ethernet-Buchsen ragen 3 mm** über die 85-mm-Kante hinaus. Gehäuse, die auf
  85 mm konstruiert wurden, sind zu kurz.

**Lösung:**
- Bumper-Bodenstärke in die Standoff-Länge einrechnen (die Bohrungen bleiben zugänglich,
  der Stapel wird aber höher) – oder den Bumper für den HAT-Aufbau abnehmen
- **SD-Karte vor dem Einsetzen in den Bumper entfernen** (offizielle Warnung)
- Gehäuse-Innenmass gegen **88 × 56 mm** (ohne Bumper) bzw. **89,6 × 60,6 mm** (mit) prüfen
- Details und Ausschnittmasse: `mechanical.md`

### 8. Umgebungstemperatur ausserhalb der Spezifikation

**Symptom:** Instabilität, Abstürze oder Nicht-Booten bei Aussen-, Dachboden- oder
Schaltschrankaufstellung – ohne auffällige Werte in `vcgencmd`.

**Ursache:** Der Pi 5 ist für **0 °C bis 70 °C Umgebungstemperatur** spezifiziert. Diese
Grenze ist unabhängig von den SoC-Throttling-Schwellen (80/85 °C) und wird im Winter oder
in geschlossenen Gehäusen verletzt, ohne dass die SoC-Temperatur auffällt.

**Diagnose:**
```bash
# SoC-Temperatur (nicht Umgebung!)
vcgencmd measure_temp

# Verlauf mitschreiben und mit einem externen Thermometer im Gehäuse vergleichen
while true; do echo "$(date -Is) $(vcgencmd measure_temp)"; sleep 60; done | tee thermal.log
```

**Lösung:**
- Umgebungstemperatur am Einsatzort messen, nicht schätzen
- Unter 0 °C: Innenaufstellung mit Aussensensor, beheiztes Gehäuse oder Mikrocontroller
  (Pico W / ESP32) als Aussenknoten
- Über 70 °C bzw. schlecht belüftet: Öffnungen vergrössern, Gehäuse nie abdecken
- Kondenswasser bei Temperaturwechseln berücksichtigen

### 9. PCIe-FFC: Typ, Länge und der Kurzschluss-Fall

**Symptom:** PCIe-Gerät erscheint nicht in `lspci`, Link-Fehler, sporadische Aussetzer –
oder im schlimmsten Fall ein toter Pi bzw. HAT nach dem ersten Einschalten.

**Ursachen und Prüfreihenfolge:**

1. **Kabeltyp.** Das FFC muss vom Typ **opposite-sides-contact** sein. Ein Kabel mit
   gleichseitigen Kontakten ist nicht umkehrbar – falsch herum eingesteckt
   **kurzschliesst es den Pi 5 und/oder die Zusatzplatine**. Immer das mitgelieferte
   Kabel verwenden, nie ein Kamera- oder Display-FFC zweckentfremden.
2. **Länge und Impedanz.** Maximal **50 mm**, differentielle Impedanz **90 Ω ± 10 %**
   über durchgehender Massefläche. Ein längeres oder unkontrolliertes Kabel führt zu
   Link-Fehlern, nicht zu «etwas langsamer».
3. **Sitz.** Beide Enden vollständig eingeschoben, Verriegelung geschlossen.
4. **Gen-Modus.** Bei AER-Meldungen zuerst auf Gen 2 zurück (siehe Punkt 4 oben).

```bash
# Ist überhaupt ein Gerät am Bus?
lspci

# Link-Status und Geschwindigkeit
sudo lspci -vv | grep -i "LnkSta:"
# 5GT/s = Gen 2 (spezifiziert), 8GT/s = Gen 3 (Opt-in)

# PCIe-Fehler im Kernel-Log
dmesg | grep -iE "pcie|aer|link" | tail -30
```

**Bei Eigenentwicklungen zusätzlich:** `PCIE_DET_WAKE` (Pin 14) muss auf High gezogen
sein, sonst tastet der Pi den PCIe-Bus beim Booten gar nicht ab und das Gerät erscheint
nie. Pinout und Beschaltungsregeln stehen in `pcie.md`.

### 10. M.2 HAT+: Temperaturgrenze und Variantenwahl

**Symptom:** Aufbau mit Hailo oder NVMe läuft instabil, ohne dass Unterspannung oder
SoC-Throttling erkennbar wären.

**Ursache:** Der M.2 HAT+ ist für **0–50 °C Umgebungstemperatur** spezifiziert, der Pi 5
für 0–70 °C. Für den Stapel gilt die **niedrigere** Grenze. Wer mit den 70 °C des Pi
rechnet, plant 20 °C zu optimistisch.

```bash
# SoC-Temperatur (sagt wenig über die Umgebung im Gehäuse aus)
vcgencmd measure_temp

# Verlauf mitschreiben und mit einem Thermometer im Gehäuse vergleichen
while true; do echo "$(date -Is) $(vcgencmd measure_temp)"; sleep 60; done | tee thermal.log
```

**Verwandter Fall – falsche Variante beschafft:** Der **M.2 HAT+ Compact** unterstützt
**nur 2230**. Ein 2242-Modul passt mechanisch nicht. Die Standard-Variante unterstützt
2230 und 2242 und bringt den 16-mm-Stacking-Header mit, der über den Active Cooler passt.

### 11. Bit-Banging und Timing: der PCIe-Umweg des RP1

**Symptom:** Ein Skript, das auf dem Pi 4 lief, erzeugt auf dem Pi 5 falsche Signale –
WS2812-LEDs flackern, Software-1-Wire schlägt fehl, Software-SPI liefert Müll, oder eine
Polling-Schleife reagiert unregelmässig.

**Ursache:** Der GPIO sitzt beim Pi 5 nicht mehr im SoC, sondern im RP1 hinter einer
PCIe-Verbindung. Jeder Zugriff kostet typisch **~1 µs**, ein Lesezugriff mindestens das
Doppelte (Request + Response). Bei aktivem ASPM kommen 2–5 µs Aufwachzeit dazu.

**Lösung – in dieser Reihenfolge:**

1. **Hardware-Peripherie statt Software-Takt.** Der Pi 5 bietet am Header 6× SPI, 4× I2C,
   5× UART, 2× I2S und 4 PWM-Kanäle. Was in Hardware geht, gehört in Hardware.
2. **PIO nutzen.** RP1 hat denselben programmierbaren I/O-Block wie der RP2040. Er taktet
   im Chip, ohne PCIe-Round-Trip pro Flanke – die richtige Antwort für WS2812 und
   ähnliche Protokolle.
3. **ASPM abschalten**, wenn die Schleife eng ist. Das Datenblatt nennt ausdrücklich
   Polling-Schleifen mit 10–100 µs Verzögerung als Fall, in dem der Link in L0 bleiben soll.
4. **Write-Barrier vor dem Lesen** setzen, wenn der eigene Code Pins umschaltet und
   danach zurückliest.
5. **ADC-Statusregister nicht pollen**, während RIO genutzt wird – beide teilen sich einen
   APB-Splitter. Für den ADC DMA oder FIFO verwenden.

Hintergrund und Zahlen: `rp1-gpio.md`.

### 12. Treiberstrom: 16 mA gelten auf dem Pi 5 nicht

**Symptom:** LED zu dunkel, Pegel bricht unter Last ein, oder – umgekehrt – Sorge, ob eine
aus einer Pi-4-Anleitung übernommene Dimensionierung zulässig ist.

**Ursache:** Die RP1-Pads bieten **2 / 4 / 8 / 12 mA**. Das Maximum ist **12 mA**, nicht
16 mA wie beim BCM2711 des Pi 4. Die **Voreinstellung liegt bei 4 mA**, nicht am Maximum –
wer 12 mA erwartet, aber nichts umgestellt hat, hat ein Drittel davon.

**Lösung:**
- Vorwiderstände für den Pi 5 gegen **12 mA** rechnen, nicht gegen 16 mA
- Bei zu schwachem Ausgang die Treiberstärke setzen statt den Widerstand zu verkleinern
- Lasten grundsätzlich über Transistor/Treiber, nicht aus dem GPIO speisen
- Ein Summenstrom pro Bank ist für den Pi 5 **nicht dokumentiert** → konservativ rechnen

### 13. Taster prellt – obwohl RP1 das in Hardware kann

**Symptom:** Ein Taster löst mehrfach aus, `sleep()`-Workarounds im Callback.

**Ursache:** Software-Entprellung aus Pi-4-Zeiten wird weiterverwendet, obwohl RP1
Entprellung in Hardware anbietet.

**Lösung:** RP1 kennt acht Interrupt-Szenarien pro Pin, darunter **Debounced Level
High/Low** und **Filtered Edge High/Low**. In `gpiozero` deckt der Parameter
`bounce_time` den Anwendungsfall ab; für eigene Treiber steht die Filterzeit in
`IO_BANK0_GPIOn_CTRL.F_M`. Details: `rp1-gpio.md`.

### 14. Pi bootet nicht – die 5-Minuten-Regel

**Symptom:** Nach dem Einschalten passiert nichts, kein Bild, kein Netzwerk.

**Vorgehen:**

1. **5 Minuten warten.** Bootet der Pi bis dahin nicht, den **Status-LED** prüfen –
   blinkt sie, geben die **LED-Blinkcodes** die Ursache an.
2. Wurde von einem **anderen Medium als der SD-Karte** gebootet (USB, NVMe)? Zum Test
   mit einer SD-Karte starten.
3. SD-Karte **neu beschreiben** und dabei den **Verify-Schritt vollständig durchlaufen
   lassen** – nicht überspringen. Eine unvollständig geschriebene Karte ist die
   häufigste Ursache.
4. Mit dem Imager den **Bootloader neu flashen**, danach das OS erneut schreiben.

**Häufige Ursachen vor dem Karten-Tausch prüfen:**
- Netzteil zu schwach oder Kabel zu dünn (Spannung gilt **am Stecker**, nicht am Netzteil)
- Monitor nicht an **HDMI0**
- Bei Pi 5: EEPROM so konfiguriert, dass auf den Power-Button gewartet wird

### 15. Headless-Pi ist nach dem ersten Boot nicht erreichbar

**Symptom:** Der Pi läuft (LED an), antwortet aber nicht auf SSH.

**Ursachen und Prüfreihenfolge:**

1. **Kein Fernzugriff konfiguriert.** Beim **ersten** Boot sind nur **SSH** und
   **Raspberry Pi Connect** verfügbar – **VNC erst danach**, und mit den Lite-Varianten
   gar nicht. Mindestens eines von beiden muss im Imager aktiviert worden sein.
2. **`wpa_supplicant.conf` verwendet.** Ab Bookworm gibt es diese Funktion **nicht mehr**.
   WLAN über den Imager oder später über `nmcli` konfigurieren.
3. **5-GHz-Netz, aber Modell kann nur 2,4 GHz** (Zero W, Zero 2 W, Pi 3B).
4. **Falscher Hostname.** Der Pi meldet sich per mDNS als `<hostname>.local` bzw.
   `<hostname>.lan`.
5. **Benutzername ungültig.** Muss mit einem Buchstaben beginnen, nur Kleinbuchstaben,
   Ziffern, Unterstriche, Bindestriche, max. 31 Zeichen.

```bash
# Erreichbarkeit prüfen
ping -c3 hostname.local
ssh benutzer@hostname.local

# SSH von Hand nachrüsten (Partition bootfs, Karte am anderen Rechner)
touch /pfad/zu/bootfs/ssh
openssl passwd -6            # Hash erzeugen, auf macOS ggf. brew install openssl
# Ergebnis in userconf.txt: benutzer:$6$...
```

Details: `setup-provisioning.md`.

### 16. Peripherie fällt aus, ohne Unterspannungswarnung

**Symptom:** USB-SSD wird nicht erkannt, Kamera fällt sporadisch aus, Hub funktioniert
nicht – `vcgencmd get_throttled` meldet aber nichts.

**Ursache:** Am **Pi 5 mit einem 5 V / 3 A Netzteil** wird die Peripherieversorgung auf
**600 mA** begrenzt. Das Board läuft normal, nur die angeschlossenen Geräte bekommen zu
wenig. Ein 15-W-Netzteil vom Pi 4 ist deshalb kein vollwertiger Ersatz.

**Lösung:** 27-W-Netzteil (5 V / 5 A) verwenden. Zusätzlich das Kabel prüfen – die
Spannungsangabe gilt **am Stecker**, dünne oder lange USB-C-Kabel fallen hier auf.

---

## Software-Debugging

### Python-Abhängigkeitskonflikte auf ARM64

```bash
# Package auf aarch64 verfügbar?
pip install <package> --dry-run

# Vorkompilierte Wheels auf piwheels.org prüfen
pip install <package> -i https://www.piwheels.org/simple

# Fallback: Aus Source kompilieren (dauert lang)
pip install <package> --no-binary :all:

# Systemweite Packages in venv verfügbar machen
python3 -m venv .venv --system-site-packages
```

### Ollama / LLM-Debugging

```bash
# Ollama-Service-Status
sudo systemctl status ollama
journalctl -u ollama --since "10 min ago"

# RAM-Situation vor Modell-Loading
free -h
# "available" Spalte beachten, nicht "free"

# Modell lädt nicht? → RAM-Budget prüfen
# 7B q4_0 ≈ 4GB, 3B q4_K_M ≈ 2GB
# Total aller Prozesse + OS < 7.5GB (bei 8GB Pi)

# OOM-Killer zugeschlagen?
dmesg | grep -i "oom\|killed"

# Swap-Nutzung (Swap = massiver Performance-Einbruch)
swapon --show
free -h | grep Swap
```

### Systemd-Service-Debugging

```bash
# Service-Status mit Details
sudo systemctl status <service> -l

# Letzte Logs
journalctl -u <service> --since "30 min ago" --no-pager

# Service startet nicht? → ExecStart manuell testen
cat /etc/systemd/system/<service>.service | grep ExecStart
# Befehl manuell ausführen und auf Fehler prüfen

# Nach Änderung am Service-File:
sudo systemctl daemon-reload
sudo systemctl restart <service>
```

### Netzwerk-Debugging

```bash
# WLAN-Status
nmcli device status
nmcli connection show

# DNS-Auflösung
nslookup google.com

# Port offen?
ss -tlnp | grep <port>

# Firewall blockiert?
sudo ufw status verbose
```

---

## Hardware-Debugging

### Stromversorgung validieren

```bash
# Throttling-Status (wichtigster Einzelbefehl)
vcgencmd get_throttled

# Bit-Interpretation:
# 0x0     = Alles OK
# 0x50005 = Under-voltage jetzt UND seit Boot
# 0x80008 = Thermal Throttling

# Kernel-Meldungen zu Spannungsproblemen
dmesg | grep -i "voltage\|under"

# Live-Spannung messen (Pi 5)
vcgencmd pmic_read_adc
```

**Strombudget-Berechnung:**

| Komponente | Typischer Verbrauch |
|------------|---------------------|
| Pi 5 unter Last | ~2.5A @ 5V = 12.5W |
| Hailo-8L NPU | ~2.5W |
| NVMe SSD | ~3-5W |
| Kamera Module 3 | ~1.5W |
| USB-Peripherie | ~2-4W |
| **TOTAL** | **~22-25W** |
| **Netzteil (27W)** | **Reserve: 2-5W (≥20%)** |

### Thermal-Debugging

```bash
# Aktuelle Temperatur
vcgencmd measure_temp

# Throttling-Grenzen:
# 80°C → Soft-Throttling (Frequenz reduziert)
# 85°C → Hard-Throttling (massive Reduktion)

# Kontinuierliches Monitoring
watch -n 1 vcgencmd measure_temp

# CPU-Frequenz unter Last (zeigt Throttling)
watch -n 1 vcgencmd measure_clock arm
# Erwartung Pi 5: 2400000000 (2.4GHz)
# Wenn niedriger → Thermal Throttling aktiv
```

### GPIO-Debugging

```bash
# Aktuellen GPIO-Zustand lesen (alle Pins)
pinout

# Einzelnen Pin-Zustand prüfen (gpiozero)
python3 -c "
from gpiozero import DigitalInputDevice
pin = DigitalInputDevice(17, pull_up=True)
print(f'GPIO17: {pin.value}')
"

# I2C-Bus scannen
i2cdetect -y 1

# I2C-Register eines Geräts lesen (z.B. Adresse 0x76)
i2cdump -y 1 0x76

# SPI-Verfügbarkeit
ls -la /dev/spidev*
```

### USB-Gerät nicht erkannt

```bash
# USB-Baum anzeigen
lsusb -t

# Detaillierte USB-Info
lsusb -v 2>/dev/null | grep -A 5 "<Gerätename>"

# Kernel-Meldungen bei USB-Einstecken
dmesg --follow
# → USB-Gerät einstecken und Ausgabe beobachten

# Audio-Geräte (USB-Mikrofon)
arecord -l
aplay -l
```

---

## Edge-AI-Debugging

### Hailo-8L NPU

```bash
# 1. Hardware erkannt?
hailortcli fw-control identify
# Erwartung: Hailo-8L, Firmware-Version

# 2. PCIe-Link aktiv?
lspci | grep Hailo
# Erwartung: Co-processor: Hailo Technologies Ltd.

# 3. PCIe-Geschwindigkeit (Gen 3?)
sudo lspci -vv | grep -A 2 "Hailo"
# LnkSta: Speed 8GT/s = Gen3 ✓, Speed 5GT/s = Gen2 ✗

# 4. Hailo-Runtime funktional?
hailortcli run /usr/share/hailo-models/yolov8n.hef
# Muss ohne Fehler durchlaufen

# 5. GStreamer-Pipeline testen
gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink
# Erst ohne Hailo testen, dann mit hailonet Element

# 6. Temperatur des Hailo-Chips
hailortcli fw-control measure-temperature
```

**Häufige Hailo-Fehler:**

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| "Failed to identify" | PCIe nicht verbunden | FFC-Kabel prüfen, `hailo-all` installieren, Reboot |
| "HEF parsing failed" | Falsches Modell-Format | .hef für Hailo-8L (nicht Hailo-8) verwenden |
| Niedrige FPS | Gen 2 statt Gen 3 | `dtparam=pciex1_gen=3` in config.txt |
| Crash bei Start | Thermal | Active Cooler prüfen, Gehäuse-Lüftung |

### Whisper (Speech-to-Text)

```bash
# Mikrofon-Eingang testen (vor Whisper-Test)
arecord -D plughw:1,0 -d 3 -f cd /tmp/test.wav
aplay /tmp/test.wav

# Whisper-Modell-Grösse vs. RAM
# tiny: ~200MB, base: ~500MB, small: ~1GB
# Auf Pi 5 8GB: maximal "small" neben anderen Prozessen

# ALSA-Device-Index für USB-Mikrofon fixieren
cat /proc/asound/cards
# → udev-Regel erstellen für konsistente Zuordnung
```

### Ollama + LangGraph Orchestrierung

```bash
# Ollama API erreichbar?
curl -s http://localhost:11434/api/tags | python3 -m json.tool

# Modell geladen?
curl -s http://localhost:11434/api/ps

# LangGraph-Agent-Health
curl -s http://localhost:8000/health

# Prozess-Übersicht (alle AI-Prozesse)
ps aux | grep -E "ollama|whisper|piper|fastapi|uvicorn"

# Gesamter RAM-Verbrauch aller AI-Prozesse
ps aux --sort=-%mem | head -20
```

---

## Eskalationspfade

### Zeitbasierte Eskalation

| Zeitraum | Aktion |
|----------|--------|
| 0–15 Min | Isolationsmethode anwenden, Logs lesen |
| 15–30 Min | Claude/Gemini mit Fehlermeldung + Kontext konsultieren |
| 30–60 Min | Raspberry Pi Forum, GitHub Issues des betroffenen Projekts |
| 60+ Min | Alternatives Bauteil/Library evaluieren, Workaround suchen |

### Effektive Fehlerberichte erstellen

Beim Eskalieren an Claude, Forum oder GitHub Issues immer diese Infos mitliefern:

```
1. Was ist das Ziel? (Was soll passieren?)
2. Was passiert stattdessen? (Fehlermeldung vollständig)
3. Hardware: Pi-Version, RAM, Peripherie
4. Software: OS-Version, Python-Version, Library-Versionen
5. Was wurde bereits versucht? (inkl. Ergebnisse)
6. Seit wann tritt das Problem auf? (Was hat sich geändert?)
```

```bash
# System-Info für Fehlerberichte sammeln
cat /etc/os-release | head -3
uname -a
python3 --version
pip list 2>/dev/null | head -20
vcgencmd get_throttled
vcgencmd measure_temp
free -h
df -h /
```

---

## Stalled-Projekt-Analyse

Wenn ein Projekt seit >14 Tagen keine Aktivität zeigt (Is Stalled = true in Notion), systematische Ursachenanalyse durchführen:

### Ursachen-Kategorien

| Kategorie | Indikatoren | Massnahme |
|-----------|-------------|-----------|
| Technischer Blocker | Blocker/Risks-Feld gefüllt, Next Action = "Blocked" | Eskalation: Forum, alternatives Bauteil, Workaround |
| Fehlende Komponenten | Components Ordered = false, Next Action = "Procurement" | Bestellung auslösen, Alternative suchen |
| Skills-Lücke | Required Skills enthält unbekannte Technologie | Lernzeit einplanen, Tutorial durcharbeiten |
| Scope Creep | Progress stagniert trotz Aktivität | Scope reduzieren auf MVP, Success Criteria vereinfachen |
| Motivationsverlust | Keine offensichtliche technische Blockade | Projekt auf Micro-Milestone herunterbrechen (30-Min-Einheiten) |

### Wiederbelebungs-Protokoll

1. Notion-Eintrag öffnen, Blocker/Risks und Learnings lesen
2. Letzten bekannten funktionierenden Zustand identifizieren
3. Einen einzigen nächsten Schritt definieren (max. 30 Min)
4. Next Action-Feld aktualisieren
5. Last Activity-Datum setzen

---

## Pre-Flight Quick Checks

Vor Projektstart die passende Checkliste durchlaufen (basierend auf Difficulty-Level).

### Beginner (15–30 Min)

```
☐ Netzteil korrekt (Pi 5 = 27W USB-C PD)
☐ Active Cooler montiert
☐ OS geflasht & aktualisiert (apt update && upgrade), Verify-Schritt durchgelaufen
☐ SSH oder Raspberry Pi Connect im Imager aktiviert (VNC geht beim ersten Boot nicht)
☐ Netzteil passt zum Modell (Pi 5: 5 V/5 A – mit 3 A nur 600 mA für Peripherie)
☐ Aufstellung stabil, eben, nicht leitfähig; Gehäuse nicht abgedeckt
☐ Umgebungstemperatur im Einsatzbereich 0–70 °C
☐ Notion-Eintrag erstellt
```

### Intermediate (30–60 Min)

Alles aus Beginner, PLUS:

```
☐ Pi 5 Mini-CSI-Kabel (nicht Pi 4 Kabel!)
☐ GPIO-Pinout auf pinout.xyz verifiziert
☐ HAT-Kompatibilität: RP1-Chip, Kernel 6.6+ Treiber
☐ Spannungslogik: 3.3V vs. 5V → Logic Level Converter?
☐ Treiberstrom gegen 12 mA gerechnet (Pi 5), nicht gegen 16 mA (Pi 4)
☐ Zeitkritische Protokolle: Hardware-Peripherie oder PIO statt Bit-Banging
☐ Strombudget berechnet (Pi + Peripherie < 80% Netzteil)
☐ Python venv konfiguriert (PEP 668 auf Bookworm!)
☐ Packages auf aarch64 verfügbar? (piwheels.org prüfen)
☐ RAM-Variante passend gewählt (1/2/4/8/16 GB)
☐ Platzbedarf geprüft: 88 × 56 mm, mit Bumper 89,6 × 60,6 mm
☐ Inkrementeller Aufbauplan definiert
```

### Advanced (1–2 Std)

Alles aus Beginner + Intermediate, PLUS:

```
☐ Architekturdiagramm erstellt (Module, Kommunikation)
☐ RAM-Budget berechnet (alle Prozesse)
☐ Latenz-Budget definiert (z.B. Kamera → Erkennung → Display < 200ms)
☐ HAT-Stacking/PCIe-Konflikte geprüft (Bohrbild 58 × 49 mm, Standoff-Längen)
☐ I2C-Adressen kollisionsfrei?
☐ PCIe-Modus bewusst gewählt (Gen 2 = Spezifikation, Gen 3 = Opt-in ohne Garantie)
☐ FFC: mitgeliefertes Kabel, ≤ 50 mm, opposite-sides-contact
☐ M.2-Formfaktor passt zur HAT-Variante (Compact = nur 2230)
☐ Gehäuseausschnitte gegen Steckerpositionen geprüft (mechanical.md)
☐ Wayland vs. X11 entschieden
☐ Thermal-Monitoring eingerichtet (vcgencmd measure_temp)
☐ Fehlerszenarien durchgespielt
```

### Expert / Edge AI (2–4 Std)

Alles aus Beginner + Intermediate + Advanced, PLUS:

```
☐ RAM-Budget berechnet (8-GB-Pi: alle Modelle + OS < 7.5 GB; 16-GB-Pi: < 15 GB)
☐ hailortcli fw-control identify erfolgreich
☐ PCIe-Link verifiziert (lspci → 5GT/s Gen 2 bzw. 8GT/s Gen 3)
☐ Gehäuse-Innentemperatur unter Volllast gemessen (< 50 °C mit M.2 HAT+, sonst < 70 °C)
☐ Alle AI-Modelle einzeln getestet (Whisper, Ollama, YOLO)
☐ Audio-Subsystem: USB-Mikrofon statt GPIO-HAT (Stacking-Konflikt!)
☐ udev-Regel für USB-Audio erstellt
☐ Multi-Prozess-Architektur dokumentiert (Ports, IPC, Restart-Policy)
☐ systemd Unit-Files vorbereitet
☐ GDPR/DSG-Konformität geprüft (Gesichter, Stimmen → lokal, kein Cloud)
☐ Logging-Konfiguration definiert
```
