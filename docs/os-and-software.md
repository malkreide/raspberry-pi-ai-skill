# Raspberry Pi OS – Versionen, Updates, Software

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Raspberry Pi OS»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/os.html)).

## Inhaltsverzeichnis
1. [Versionen und Release-Zyklus](#versionen-und-release-zyklus)
2. [Editionen und Architektur](#editionen-und-architektur)
3. [System aktualisieren](#system-aktualisieren)
4. [Major-Upgrade: nur per Neuinstallation](#major-upgrade-nur-per-neuinstallation)
5. [Firmware: APT statt rpi-update](#firmware-apt-statt-rpi-update)
6. [Paketverwaltung mit APT](#paketverwaltung-mit-apt)
7. [Python: apt oder venv](#python-apt-oder-venv)
8. [Lite zu Desktop nachrüsten](#lite-zu-desktop-nachrüsten)
9. [Audio und Video](#audio-und-video)
10. [Diagnose-Werkzeuge](#diagnose-werkzeuge)
11. [Barrierefreiheit](#barrierefreiheit)

---

## Versionen und Release-Zyklus

Raspberry Pi OS basiert auf Debian und folgt dessen Release-Zyklus zeitversetzt.
**Neue Hauptversionen erscheinen rund alle zwei Jahre.**

| Version | Debian-Basis | Status |
|---------|--------------|--------|
| **Raspberry Pi OS (aktuell)** | **Trixie** | aktuelle Hauptversion |
| Vorgänger | **Bookworm** | vorherige Hauptversion |

Über 69 000 Debian-Pakete stehen zur Verfügung.

➜ **Für Projektpläne:** Die Zielversion explizit benennen. Aussagen wie «ab Bookworm»
gelten auch für Trixie – sie markieren, **seit wann** etwas gilt, nicht bis wann. Das
betrifft im Skill vor allem PEP 668, den Wegfall von `wpa_supplicant.conf` und Wayland
als Standard.

### Was zwischen den Versionen anders heisst

| Trixie | Bookworm | Anmerkung |
|--------|----------|-----------|
| **Control Centre** | **Raspberry Pi Configuration** | Dasselbe Desktop-Werkzeug, neuer Name |
| `auto_initramfs` voreingestellt | Datei vorhanden, Schlüsselwort nötig | In `config.txt` |
| — | letzte Version mit `raindrop` / `arandr` | Display-Konfiguration unter Trixie anders |

➜ Anleitungen aus der Bookworm-Zeit sind meist noch gültig, nennen aber alte Namen. Wenn
ein Menüpunkt «nicht existiert», zuerst den Namenswechsel prüfen, bevor eine Fehlfunktion
vermutet wird. Die Konfigurationsfläche im Detail: `configuration.md`.

---

## Editionen und Architektur

| Edition | Inhalt | Wofür |
|---------|--------|-------|
| **Raspberry Pi OS** | Desktop + Basissoftware (Chromium, Firefox, VLC, Thonny) | Standardempfehlung |
| **Raspberry Pi OS Full** | zusätzlich LibreOffice, KiCad, Scratch u.a. | Unterricht, Arbeitsplatz |
| **Raspberry Pi OS Lite** | nur Kommandozeile | **Headless, Embedded, ältere Modelle** |

Speicherbedarf je Edition: siehe `setup-provisioning.md`.

### 64-Bit oder 32-Bit

| Variante | Für |
|----------|-----|
| **64-Bit** | Pi 3, 4, 5 – mehr RAM nutzbar, schneller bei rechenintensiven Aufgaben |
| 32-Bit | Erster Pi, Pi 2, Pi Zero – weniger Speicherbedarf, bessere Altkompatibilität |

➜ **Für Edge AI zwingend 64-Bit.** Ollama, Hailo-Runtime und die meisten
ML-Wheels auf piwheels setzen aarch64 voraus.

---

## System aktualisieren

```bash
sudo apt update
sudo apt full-upgrade
```

> ⚠️ **`full-upgrade`, nicht `upgrade`.** Die offizielle Dokumentation empfiehlt das
> ausdrücklich: Raspberry Pi OS ändert Paketabhängigkeiten häufiger als Debian.
> `apt upgrade` lässt Pakete zurück, deren Aktualisierung neue Abhängigkeiten oder
> Entfernungen erfordert – genau die, die bei einem Pi-OS-Update oft anfallen.

### Vor dem Update: Platz prüfen

```bash
df -h                    # freien Speicher prüfen
sudo apt clean           # heruntergeladene .deb-Dateien löschen (/var/cache/apt/archives)
```

Meldet `full-upgrade` zu wenig Platz, zuerst `apt clean`, dann erneut versuchen.

Diese Befehle aktualisieren **Software, Kernel und stabile Firmware** derselben
Hauptversion. Ein Wechsel der Hauptversion passiert damit **nicht**.

---

## Major-Upgrade: nur per Neuinstallation

> 🔴 **Kein In-Place-Upgrade zwischen Hauptversionen.** Für den Weg von Bookworm nach
> Trixie empfiehlt Raspberry Pi ausdrücklich eine **Neuinstallation auf neuem
> Boot-Medium** – kein `do-release-upgrade`, kein Umbiegen der Paketquellen.

**Ablauf:**

1. **Backup des bestehenden Boot-Mediums** anlegen.
2. **Neues** Speichermedium mit der neuen OS-Version bespielen (Imager).
3. Eigene Dateien und Konfigurationen übertragen.
4. Neues Medium einsetzen und starten.

➜ **Konsequenz für Projekte:** Die Konfiguration eines Pi muss reproduzierbar sein –
sonst ist jedes Major-Upgrade ein manueller Wiederaufbau. Setup-Schritte gehören ins
`plan.md`, Abhängigkeiten in eine `requirements.txt`, Systemdienste als versionierte
Unit-Files ins Repository. Das alte Medium **nicht überschreiben**, bis das neue läuft.

---

## Firmware: APT statt rpi-update

| Werkzeug | Zweck |
|----------|-------|
| **APT** (`raspi-firmware`) | **Normalfall.** Stabile Firmware kommt mit den regulären Updates |
| **Beta Access** (`raspi-config`) | Freischaltung eines **Beta-Repositories** – neuere Pakete und Bootloader-Versionen, weiterhin über `apt` verwaltet |
| `rpi-update` | **Nur** Vorab-/Testfirmware für Entwicklung und gezielte Bugfixes |

> **Wer Neueres testen will, nimmt Beta Access – nicht `rpi-update`.** Beide liefern
> Vorabsoftware, aber Beta Access bleibt paketverwaltet und rückbaubar
> (`raspi-config` → `6 Advanced Options` → `A6 Beta Access`, danach `sudo apt update`).
> `rpi-update` geht an APT vorbei. Siehe `configuration.md`.

> ⚠️ **`rpi-update` ist kein Update-Werkzeug für den Alltag.** Es installiert
> Vorabversionen von Kernel, Modulen, Device-Tree und VideoCore-Firmware – auf Pi 4 und
> Pi 5 zusätzlich den **EEPROM-Bootloader**. Vorabfirmware ist nicht garantiert
> funktionsfähig und kann das System **instabil oder nicht mehr startfähig** machen.
>
> Nur verwenden, wenn ein Raspberry-Pi-Engineer es ausdrücklich empfiehlt. Vorher
> Backup.

### Rückweg auf die letzte stabile Firmware

```bash
sudo apt update
sudo apt install --reinstall raspi-firmware
sudo reboot
```

➜ Das ist der Rettungsanker, wenn nach einem `rpi-update` etwas nicht mehr geht.

---

## Paketverwaltung mit APT

```bash
apt-cache search <stichwort>      # Paket suchen
apt-cache show <paket>            # Details: Version, Grösse, Abhängigkeiten
sudo apt install <paket>          # installieren
sudo apt install -y <paket>       # ohne Rückfrage
sudo apt remove <paket>           # entfernen
sudo apt purge <paket>            # entfernen inkl. Konfigurationsdateien
```

Im Desktop: **Preferences → Add / Remove Software**.

---

## Python: apt oder venv

Raspberry Pi OS bringt Python 3 mit. **Nie in die System-Python-Installation eingreifen.**

### Zwei Wege

| Weg | Wann |
|-----|------|
| **`apt`** (`python3-<paket>`) | Systemweit, vorkompiliert, Abhängigkeiten werden mitverwaltet |
| **`pip` im venv** | Projektbezogen, alles was nicht als Debian-Paket vorliegt |

```bash
# apt: vorkompiliert, schnell, systemweit
apt search python3-        # Pakete tragen meist das Präfix python3-
sudo apt install python3-numpy
sudo apt install python3-build-hat
```

➜ **Faustregel:** Was es als `python3-*`-Paket gibt, über `apt` installieren – es ist
vorkompiliert und spart auf dem Pi viel Übersetzungszeit. Alles andere ins venv.

### PEP 668

Seit Bookworm (und damit auch unter Trixie) verweigert `pip` die Installation ins
System-Python:

```
error: externally-managed-environment
```

Das ist **keine Raspberry-Pi-Entscheidung**, sondern PEP 668 der Python-Community.

```bash
# Virtuelle Umgebung anlegen
python -m venv .venv

# Mit Zugriff auf die bereits systemweit installierten Pakete
python -m venv .venv --system-site-packages

# Aktivieren / verlassen
source .venv/bin/activate
deactivate

# Kontrolle
pip list          # im venv deutlich kürzer als im System-Python
which python3     # muss auf .venv/bin/python3 zeigen
```

⚠️ **`--break-system-packages` nicht verwenden.** Der Schalter existiert, hebelt aber
genau den Schutz aus, um den es geht.

**`--system-site-packages` ist auf dem Pi meist die richtige Wahl:** So bleiben
`python3-picamera2`, `python3-gpiozero` und andere per apt installierte Systempakete
im venv sichtbar, ohne sie neu übersetzen zu müssen.

### Thonny

Thonny nutzt standardmässig das System-Python. Über das Interpreter-Menü **rechts unten**
lässt sich ein venv auswählen oder unter *Configure interpreter…* ein neues anlegen.

➜ Im Unterricht der übliche Stolperstein: Das Skript läuft im Terminal, aber nicht in
Thonny – weil Thonny noch auf das System-Python zeigt.

---

## Lite zu Desktop nachrüsten

Eine Lite-Installation lässt sich nachträglich zum Desktop ausbauen:

```bash
# 1. Fenstersystem
sudo apt install rpd-wayland-core     # Wayland (empfohlen)
# oder
sudo apt install rpd-x-core           # X

# 2. Erscheinungsbild und Control Centre
sudo apt install rpd-theme
sudo apt install rpd-preferences

# 3. Anwendungen
sudo apt install rpd-applications
sudo apt install rpd-utilities
sudo apt install rpd-developer
sudo apt install rpd-graphics

# 4. Zusatzfunktionen (Screenshot, Remote Desktop)
sudo apt install rpd-wayland-extras   # bzw. rpd-x-extras

sudo reboot
```

Empfohlene Anwendungen aus der Full-Edition danach über
**Preferences → Recommended Software**.

➜ **Umgekehrt** lässt sich ein Desktop-System per *Boot to console* wie ein Lite-System
betreiben, ohne Pakete zu entfernen – praktisch, wenn ein Projekt später doch headless
laufen soll.

---

## Audio und Video

VLC ist in den Desktop-Editionen vorinstalliert, **nicht in Lite**.

```bash
# VLC auf Lite nachrüsten (ohne Desktop-Abhängigkeiten)
sudo apt install --no-install-recommends vlc-bin vlc-plugin-base

# Abspielen ohne GUI
cvlc --play-and-exit datei.mp3
cvlc --play-and-exit --fullscreen video.mp4
```

`cvlc` = VLC ohne Oberfläche. `--play-and-exit` verhindert, dass das Fenster nach dem
Ende offen bleibt.

### Audioausgabe gezielt wählen

```bash
aplay -L | grep sysdefault      # verfügbare ALSA-Geräte auflisten

cvlc --play-and-exit -A alsa --alsa-audio-device <geraet> datei.mp3
```

| ALSA-Gerät | Ausgang |
|------------|---------|
| `sysdefault:CARD=Headphones` | Klinkenbuchse |
| `sysdefault:CARD=vc4hdmi` | HDMI bei Modellen mit **einem** HDMI-Port (Zero, CM4S, CM vor CM4, Flagship vor Pi 4) |
| `sysdefault:CARD=vc4hdmi0` | HDMI0 ab Pi 4B, ab CM4, Keyboard-Modelle |
| `sysdefault:CARD=vc4hdmi1` | HDMI1 ab Pi 4B, ab CM4, Keyboard-Modelle |

### Videoausgabe gezielt wählen

```bash
kmsprint | grep Connector       # verfügbare DRM-Geräte auflisten

cvlc --play-and-exit --drm-vout-display <geraet> video.mp4
```

| DRM-Gerät | Ausgang |
|-----------|---------|
| `HDMI-A-1` | HDMI bei Zero/Pi 1/2/3, **HDMI0** bei Pi 4, 5, 400 |
| `HDMI-A-2` | HDMI1 ab Pi 4B, ab CM4, Keyboard-Modelle |
| `DSI-1` | Raspberry Pi Touch Display (1 und 2) |
| `DSI-2` | zweiter DSI-Ausgang ab Pi 5 bzw. ab CM5 |

**Beides kombiniert** – Bild aufs Touchdisplay, Ton auf die Klinke:

```bash
cvlc --play-and-exit --fullscreen \
     --drm-vout-display DSI-1 \
     -A alsa --alsa-audio-device sysdefault:CARD=Headphones video.mp4
```

### Roh-H.264 aus dem Kameramodul in einen Container packen

> Für Kameraprojekte relevant: Ein roher H.264-Stream, wie ihn das Kameramodul liefert,
> spielt in VLC deutlich schlechter ab als derselbe Stream in einem MP4-Container.

```bash
ffmpeg -r 30 -i video.h264 -c:v copy video.mp4
```

`-c:v copy` kopiert den Videostrom unverändert – kein Neucodieren, keine
Qualitätseinbusse, läuft auch auf dem Pi schnell.

---

## Diagnose-Werkzeuge

### `vcgencmd get_throttled` – vollständige Bit-Tabelle

```bash
vcgencmd get_throttled     # 0x0 = alles in Ordnung
```

| Bit | Wert | Bedeutung |
|-----|------|-----------|
| 0 | `0x1` | Unterspannung **jetzt** |
| 1 | `0x2` | Arm-Frequenz **jetzt** begrenzt |
| 2 | `0x4` | **jetzt** gedrosselt |
| 3 | `0x8` | Soft-Temperaturgrenze **jetzt** aktiv |
| 16 | `0x10000` | Unterspannung ist **aufgetreten** |
| 17 | `0x20000` | Frequenzbegrenzung ist **aufgetreten** |
| 18 | `0x40000` | Drosselung ist **aufgetreten** |
| 19 | `0x80000` | Soft-Temperaturgrenze war **aktiv** |

➜ **Die unteren vier Bits sagen «jetzt», die oberen vier «seit dem Booten».** Ein Wert
wie `0x50000` bedeutet: gerade ist alles in Ordnung, aber es gab Unterspannung und
Drosselung – der Fehler ist real, nur nicht im Moment der Messung sichtbar.

### Takt, Spannung, Temperatur

```bash
vcgencmd measure_temp                # SoC-Temperatur
vcgencmd measure_temp pmic           # PMIC-Temperatur (Pi 4)
vcgencmd measure_clock arm           # aktuelle Kernfrequenz
vcgencmd measure_volts core          # Kernspannung
```

`measure_clock` kennt: `arm`, `core`, `h264`, `isp`, `v3d`, `uart`, `pwm`, `emmc`,
`pixel`, `vec`, `hdmi`, `dpi`.
`measure_volts` kennt: `core`, `sdram_c`, `sdram_i`, `sdram_p`.

### 🔴 Speichergrösse: `get_mem` führt in die Irre

```bash
vcgencmd get_mem arm      # NICHT der Gesamtspeicher!
vcgencmd get_config total_mem   # der tatsächliche Wert, in MB
```

> Auf Geräten mit **mehr als 1 GB** liefert `get_mem arm` immer «1 GB minus
> GPU-Speicher», weil die GPU-Firmware nur das erste Gigabyte kennt. Wer auf einem
> 8-GB-Pi damit den RAM prüft, bekommt einen falschen Wert.
> ➜ Für den Gesamtspeicher `vcgencmd get_config total_mem` oder schlicht `free -h`.

### Weitere Befehle

```bash
vcgencmd commands                 # alle unterstützten Befehle auflisten
vcgencmd get_config int           # alle Integer-Konfigurationswerte
vcgencmd codec_enabled H264       # ist ein Codec freigeschaltet?
vcgencmd mem_oom                  # OOM-Ereignisse im VideoCore-Speicher
vcgencmd read_ring_osc            # Takt, Spannung, Temperatur des Ringoszillators
vcgencmd otp_dump                 # OTP-Speicher des SoC

sudo vclog --msg                  # VideoCore-Meldungslog (als root)
sudo vclog --assert               # VideoCore-Assertion-Log

kmsprint                          # angeschlossene Monitore
kmsprint -m                       # alle unterstützten Display-Modi
```

⚠️ **`codec_enabled` kennt H.265 nicht.** Ab Pi 4 liegt der H.265-Block **ausserhalb**
der VideoCore-GPU, sein Status ist über diesen Befehl nicht abfragbar. Ein leeres oder
negatives Ergebnis für HEVC bedeutet dort also nicht, dass der Decoder fehlt.

---

## Barrierefreiheit

Relevant für den Bildungseinsatz und für inklusive Aufbauten:

| Hilfsmittel | Aufruf |
|-------------|--------|
| **Orca Screenreader** | `Strg` + `Alt` + `Leertaste` installiert ihn automatisch; alternativ über *Recommended Software* |
| **Bildschirmlupe** | über *Recommended Software* |

Beim ersten Start eines frisch installierten Systems spielt nach **30 Sekunden**
automatisch ein gesprochener Hinweis ab, wie Orca installiert wird.

➜ Bei Klassensätzen einplanen: Wer den Hinweis nicht kennt, hält ihn für einen Fehler.

---

## Weitere Ressourcen

- [Raspberry Pi OS](https://www.raspberrypi.com/documentation/computers/os.html)
- [gpiozero](https://gpiozero.readthedocs.io/)
- [piwheels](https://www.piwheels.org/) – vorkompilierte Python-Wheels für den Pi
- [PEP 668](https://peps.python.org/pep-0668/)
