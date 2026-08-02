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
12. [Wo der Quellcode liegt](#wo-der-quellcode-liegt)

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

> 🔴 **Die Dokumentation von `rpi-update` selbst formuliert es unmissverständlich:**
> *«Only use rpi-update if you are happy to lose the data on your filesystem.»*
> Totalausfälle seien äusserst selten, aber möglich. Wer das Werkzeug auf einem System
> einsetzt, dessen Daten zählen, hat vorher ein Backup – nicht als Empfehlung, sondern als
> Bedingung.

### Rückweg auf die letzte stabile Firmware

```bash
sudo apt update
sudo apt install --reinstall raspi-firmware
sudo reboot
```

> 🔴 **Das reicht auf Pi 4 und Pi 5 nicht.** `rpi-update` schreibt dort **auch den
> EEPROM-Bootloader** – und der bleibt vom `raspi-firmware`-Paket unberührt. Das erklärt
> Fälle, in denen nach dem vermeintlichen Rückbau weiterhin etwas nicht stimmt.

**Den Bootloader zusätzlich zurücksetzen:**

```bash
# 2711 für Pi 4, 2712 für Pi 5
sudo rm -rf /lib/firmware/raspberrypi/bootloader-2711
sudo apt reinstall rpi-eeprom
sudo reboot
```

**Auf eine bestimmte Firmware-Fassung zurückgehen** – über den Git-Hash aus dem
Repository [`rpi-firmware`](https://github.com/raspberrypi/rpi-firmware):

```bash
sudo rpi-update fab7796df0cf29f9563b507a59ce5b17d93e0390
```

➜ Das ist präziser als das Neuinstallieren des Pakets: Wenn eine bestimmte Fassung
nachweislich lief und die nächste nicht, führt der Hash gezielt dorthin zurück, statt
irgendeinen «stabilen» Stand herzustellen.

**Schalter, die den Schaden begrenzen:**

| Variable | Wirkung |
|----------|---------|
| **`SKIP_BOOTLOADER=1`** | **Lässt den EEPROM-Bootloader unangetastet** – der wichtigste Schalter, weil genau dieser Teil sich am schwersten zurückbauen lässt |
| `SKIP_KERNEL=1` | Alles ausser den Kerneldateien aktualisieren |
| `SKIP_BACKUP=1` | Überspringt die Sicherung von `/boot` und `/lib/modules` – **nicht verwenden** |

```bash
sudo SKIP_BOOTLOADER=1 rpi-update
```

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

### 🔴 Das Kürzel `+rpt` – Raspberry Pi oder Debian?

Raspberry Pi patcht zahlreiche Debian-Pakete. Solche Fassungen tragen ein **`+rpt` in der
Versionsnummer**:

```bash
apt-cache policy labwc
#   Installed: 0.8.4-1+rpt1      ← von Raspberry Pi angepasst
#   Installed: 0.8.4-1           ← unveränderte Debian-Fassung
```

➜ **Das ist bei der Fehlersuche die erste Frage, wenn sich ein Paket anders verhält als
die Debian-Dokumentation beschreibt.** Steht ein `+rpt` in der Version, gilt die
Debian-Dokumentation nur eingeschränkt – und ein Fehlerbericht gehört zu Raspberry Pi,
nicht zu Debian. Ohne `+rpt` ist es umgekehrt.

### Quellcode eines Pakets holen

Die Quellpakete sind ab Werk **nicht** in den APT-Listen eingetragen. Dazu in diesen
Dateien jede Zeile `Types: deb` auf `Types: deb deb-src` erweitern:

| Datei | Gilt für |
|-------|----------|
| `/etc/apt/sources.list.d/debian.sources` | 64-Bit-Images |
| `/etc/apt/sources.list.d/raspbian.sources` | 32-Bit-Images |
| `/etc/apt/sources.list.d/raspi.sources` | **beide** – die Raspberry-Pi-eigenen Pakete |

⚠️ **Die zweite Datei nicht vergessen.** Wer nur `debian.sources` anpasst, bekommt die
Debian-Quellen, aber nicht die `+rpt`-Fassungen – also gerade nicht die, wegen derer man
nachsieht.

```bash
sudo apt update
apt source labwc                    # Quellen holen (ohne sudo!)

sudo apt install devscripts         # Hilfswerkzeuge
sudo apt build-dep labwc            # Build-Abhängigkeiten
cd labwc-0.8.4
debuild -uc -us                     # bauen, ohne zu signieren
```

➜ Sinnvoll, wenn ein Paket einen kleinen Patch braucht oder man wissen will, **was
Raspberry Pi gegenüber Debian geändert hat**. Für den Kernel gilt ein eigener Weg – siehe
`kernel.md`.

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

### 🔴 `h264_omx` und `*_mmal` gibt es nicht mehr

Unzählige Anleitungen beschleunigen `ffmpeg` auf dem Pi mit `-c:v h264_omx` zum Kodieren
oder `-c:v h264_mmal` zum Dekodieren. **Im `ffmpeg` von Raspberry Pi OS existieren diese
Codecs nicht.** Die Paketierung übersetzt ausdrücklich mit:

```
--disable-omx --disable-mmal --enable-v4l2-request
```

OpenMAX und MMAL sind die **alten Broadcom-Schnittstellen**; sie sind abgeschaltet. An
ihre Stelle tritt auf ARM die **V4L2-Request-API**, der heutige Weg zur
Hardwarebeschleunigung.

➜ **Damit ist das der Alterstest für `ffmpeg`-Anleitungen zum Raspberry Pi** – analog zu
`raspistill`/`raspivid` bei der Kamera (siehe `camera.md`): Steht `omx` oder `mmal` im
Befehl, ist die Anleitung überholt. Der Fehler lautet dann `Unknown encoder 'h264_omx'`,
was zuverlässig in die Suche nach einem fehlenden Paket führt – das es nicht gibt.

**Was das Gerät tatsächlich kann:**

```bash
ffmpeg -hide_banner -hwaccels                    # verfügbare Beschleuniger
ffmpeg -hide_banner -encoders | grep -i v4l2     # Hardware-Encoder
ffmpeg -hide_banner -decoders | grep -i v4l2     # Hardware-Decoder
```

> ⚠️ **Auf dem Pi 5 fehlt der H.264-Hardwarepfad ohnehin** – der Chip hat keinen
> H.264-Encoder mehr, HEVC dagegen bleibt in Hardware. Die CPU-Kosten dafür stehen in
> `hardware-specs.md` und `camera.md`. Auf dem Pi 5 also nicht nach einem
> H.264-Hardwareweg suchen: Es gibt keinen.

---

## Diagnose-Werkzeuge

### 🔴 `raspinfo` – der erste Befehl bei jedem Problem

```bash
raspinfo                 # vollständiger Systemzustand
raspinfo > bericht.txt
```

`raspinfo` sammelt in einem Durchlauf, was sonst ein Dutzend Einzelbefehle liefert:
Modell und Revision, Firmware- und Bootloader-Version, `config.txt` und `cmdline.txt`,
Drosselungsstatus, Temperaturen, Takte, geladene Module, erkannte Kameras, USB-Baum,
`dmesg`-Auszug.

➜ **Es ist ausdrücklich für Fehlerberichte gedacht** – wer im Forum oder auf GitHub fragt,
hängt diese Ausgabe an. Für dieses Skill gilt dasselbe: **Bevor eine Ferndiagnose beginnt,
`raspinfo` anfordern.** Das erspart die Rückfragerunde nach Modell, OS-Stand und
Firmware-Version fast vollständig.

> ⚠️ Die Ausgabe enthält Hostname, Seriennummer, MAC- und IP-Adressen sowie die WLAN-SSID.
> Vor dem Veröffentlichen durchsehen.

### Der Werkzeugkasten aus `raspberrypi/utils`

Diese Werkzeuge liegen im Paket `raspi-utils` beziehungsweise unter
[`raspberrypi/utils`](https://github.com/raspberrypi/utils). Mehrere davon lösen Probleme,
für die sonst umständliche Umwege nötig sind:

| Werkzeug | Wofür |
|----------|-------|
| **`raspinfo`** | Systemzustand für Fehlerberichte – siehe oben |
| **`pinctrl`** | GPIO-Zustand und Pin-Muxing anzeigen und ändern, **am Kernel vorbei** |
| **`rpi-gpu-usage`** | **GPU-Auslastung pro Prozess** (V3D, Pi 4 und 5) |
| **`ovmerge`** | Overlay-Quellen zusammenführen, flachklopfen und sortieren; zeigt den Include-Baum |
| **`dtapply`** | Wendet **alle** `dtparam`- und `dtoverlay`-Zeilen einer `config.txt` auf eine `.dtb` an |
| `dtmerge` | Einzelne übersetzte Overlays (`.dtbo`) auf eine `.dtb` anwenden |
| **`eeptools`** | EEPROMs für **HAT+ und HAT** erzeugen und verwalten |
| **`otpset`** | Kunden-OTP-Bits lesen und setzen – bequemer als `vcmailbox` von Hand |
| `piolib` | Zugriff auf die **PIO-Hardware des Pi 5** (siehe `rp1-gpio.md`) |
| `vclog`, `vcmailbox`, `vcgencmd` | VideoCore-Logs, Mailbox-Schnittstelle, Firmware-Befehle |
| `overlaycheck`, `kdtc` | Overlays im Kernelbaum prüfen und übersetzen (siehe `kernel.md`) |
| `rpieepromab` | A/B-EEPROM-Partitionen der Pi-5-Familie verwalten |

➜ **`rpi-gpu-usage` ist für Edge-AI-Projekte der interessanteste Eintrag.** Bei einer
Pipeline aus Kamera, Encoder und Inferenz beantwortet es die Frage, **welcher Prozess** die
GPU belegt – etwas, das `top` und `htop` nicht zeigen.

➜ **`dtapply` beantwortet die Frage «greift meine `config.txt` überhaupt?»** ohne Neustart:
Es baut den Device Tree so zusammen, wie die Firmware es beim Booten täte. Zusammen mit
`ovmerge` lässt sich damit prüfen, ob zwei Overlays denselben Pin beanspruchen – **bevor**
das Gerät nicht mehr bootet.

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

**Wann genau meldet das Board Unterspannung?** Die Erkennung schlägt an, sobald die
Versorgung unter **4,63 V (±5 %)** fällt, und schreibt einen Eintrag ins Kernel-Log. Die
Schaltung steckt in allen Modellen **ab dem Pi 1 B+ (2014) – ausser der Zero-Reihe**.

> ➜ Auf einem **Pi Zero gibt es diese Warnung nicht.** Ein Zero mit zu schwachem Netzteil
> zeigt kein Blitzsymbol und keinen Log-Eintrag, sondern nur Folgefehler: Abstürze, defekte
> Schreibvorgänge, korrupte SD-Karten. Beim Zero also nicht auf die Warnung warten, sondern
> Netzteil und Kabel von vornherein prüfen.

Häufigste Ursachen in dieser Reihenfolge: zu dünnes oder zu langes USB-Kabel,
unterdimensioniertes Netzteil, zu viele stromhungrige USB-Geräte.

```bash
vcgencmd pmic_read_adc      # Spannungen und Ströme am PMIC (Pi 4 / Pi 5)
```

> ℹ️ `pmic_read_adc` sieht den USB-Strom **nicht**: Was direkt an 5 V hängt, umgeht den
> PMIC. Die Summe ergibt deshalb nie die Leistung des Netzteils – brauchbar ist der Befehl
> vor allem für die Kernspannung.

➜ Was das Netzteil ausgehandelt hat und welche Grenze aktiv ist, steht unter
`/proc/device-tree/chosen/power/` – ausführlich in
[`configuration.md`](configuration.md#stromversorgung--chosenpower-pi-5).

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

## Wo der Quellcode liegt

Raspberry Pi verteilt seine Software auf drei GitHub-Organisationen. Für die Fehlersuche
ist vor allem wichtig, **wo die massgebliche Fassung einer Angabe steht** – nicht die
Repositories selbst.

| Was man sucht | Wo es steht |
|---------------|-------------|
| **Overlay-Parameter**, die auf dem Gerät fehlen | [`firmware/boot/overlays/README`](https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README) |
| Was eine Firmware geändert hat | [Firmware-Commits](https://github.com/raspberrypi/firmware/commits/master/) |
| Bootloader-Versionen und ihre Änderungen | [`rpi-eeprom` releases.md](https://github.com/raspberrypi/rpi-eeprom/blob/master/releases.md) |
| Kernelquellen aller Modelle | [`raspberrypi/linux`](https://github.com/raspberrypi/linux) |
| `pinctrl`, `raspinfo`, `piolib`, `gpiolib` | [`raspberrypi/utils`](https://github.com/raspberrypi/utils) |
| Kamera-Stack | [`libcamera`](https://github.com/raspberrypi/libcamera), [`rpicam-apps`](https://github.com/raspberrypi/rpicam-apps), [`picamera2`](https://github.com/raspberrypi/picamera2) |

> ➜ **Der Overlay-README ist der wichtigste Eintrag dieser Tabelle.** Er ist die einzige
> vollständige Liste der `dtoverlay`- und `dtparam`-Parameter. Die Fassung **auf dem Gerät**
> (`/boot/firmware/overlays/README`) passt zur installierten Firmware und ist der
> Online-Fassung vorzuziehen, wenn beide sich unterscheiden.

**Die drei Organisationen:**

| Organisation | Inhalt |
|--------------|--------|
| [`raspberrypi`](https://github.com/raspberrypi) | Kernel, Firmware, Bootloader, Kamera, Werkzeuge |
| [`raspberrypi-ui`](https://github.com/raspberrypi-ui) | Desktop, Taskleiste, Control Centre, Anwendungen |
| [`RPi-Distro`](https://github.com/RPi-Distro) | Distributionspakete und Build-Werkzeuge |

### Wohin mit einem Fehlerbericht

| Fall | Adresse |
|------|---------|
| Fehler in der **aktuellen OS-Fassung** | [`trixie-feedback`](https://github.com/raspberrypi/trixie-feedback) |
| Paket mit **`+rpt`** in der Version | Raspberry Pi – das Paket ist angepasst |
| Paket **ohne** `+rpt` | Debian – unveränderte Fassung |
| Kernel: **Pi-spezifisch** | `raspberrypi/linux` |
| Kernel: **allgemein** (neuer Treiber, generische Behebung) | **zuerst Upstream**, siehe `kernel.md` |
| **Paketarchiv** selbst nicht erreichbar, Paket fehlt, Signatur falsch | [`RPi-Distro/repo`](https://github.com/RPi-Distro/repo) – Issue-Tracker für `archive.raspberrypi.com` |
| `raspi-config` verhält sich falsch | [`RPi-Distro/raspi-config`](https://github.com/RPi-Distro/raspi-config) |

> ℹ️ **Der Unterschied zählt:** Ein `apt`-Fehler wie «404 Not Found» oder eine
> Signaturwarnung ist meist ein Problem des **Archivs**, nicht des Pakets – und gehört
> deshalb an `RPi-Distro/repo`, nicht an den Paketbetreuer.

### Weitere Werkzeuge

| Werkzeug | Zweck |
|----------|-------|
| [`rpi-imager`](https://github.com/raspberrypi/rpi-imager) | Boot-Medien schreiben |
| [`rpi-image-gen`](https://github.com/raspberrypi/rpi-image-gen) | **Eigenes OS-Image für eingebettete Systeme bauen** |
| [`pi-gen`](https://github.com/RPi-Distro/pi-gen) | Das Werkzeug, mit dem **Raspberry Pi OS selbst** gebaut wird – Stufenmodell in `setup-provisioning.md` |
| [`usbboot`](https://github.com/raspberrypi/usbboot) | `rpiboot`, `mass-storage-gadget` – siehe `compute-module.md` |
| [`rpi-sb-provisioner`](https://github.com/raspberrypi/rpi-sb-provisioner) | Serienprovisionierung mit Secure Boot und verschlüsseltem Dateisystem (Pi 5, CM4, CM5) |
| [`rpi-analyse-boot`](https://github.com/raspberrypi/rpi-analyse-boot) | Bootzeiten messen |

---

## Weitere Ressourcen

- `kernel.md` – Kernel-Header für Kernelmodule, eigene Builds, Patches, Beitragswege
- `compute-module.md` – `rpiboot`, eMMC beschreiben, Serienprovisionierung
- [Raspberry Pi OS](https://www.raspberrypi.com/documentation/computers/os.html)
- [Software sources](https://www.raspberrypi.com/documentation/computers/software-sources.html)
- [gpiozero](https://gpiozero.readthedocs.io/)
- [piwheels](https://www.piwheels.org/) – vorkompilierte Python-Wheels für den Pi
- [PEP 668](https://peps.python.org/pep-0668/)
