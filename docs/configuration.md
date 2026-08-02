# Konfiguration – raspi-config, config.txt und Device Tree

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Configuration»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/configuration.html)).

Diese Referenz beantwortet die Frage **«wo stelle ich das ein?»**. Sie ergänzt
`os-and-software.md` (welche Software, welche Version) und `setup-provisioning.md`
(erstmaliges Aufsetzen) um die Konfigurationsfläche eines bereits laufenden Systems.

➜ **Für die Datei selbst gibt es eine eigene Referenz:** `config-txt.md` behandelt das
Dateiformat mit seinen stillen Grenzen (98 Zeichen pro Zeile), bedingte Filter, A/B-Boot,
Watchdog, GPIO-Startzustände und Übertaktung.

## Inhaltsverzeichnis
1. [Drei Wege, ein Ziel](#drei-wege-ein-ziel)
2. [Die zwei Dateien](#die-zwei-dateien)
3. [raspi-config – Menülandkarte](#raspi-config--menülandkarte)
4. [Einstellungen mit Projektrelevanz](#einstellungen-mit-projektrelevanz)
5. [Device Tree, Overlays und Parameter](#device-tree-overlays-und-parameter)
6. [Bootloader und EEPROM](#bootloader-und-eeprom)
7. [Echtzeituhr (RTC) am Pi 5](#echtzeituhr-rtc-am-pi-5)
8. [Tastatur der Keyboard-Computer konfigurieren](#tastatur-der-keyboard-computer-konfigurieren)
9. [OTP-Speicher – einmal beschreibbar](#otp-speicher--einmal-beschreibbar)
10. [Was die Firmware über das System verrät](#was-die-firmware-über-das-system-verrät)
11. [Externe Datenträger dauerhaft einbinden](#externe-datenträger-dauerhaft-einbinden)
12. [Betriebssicherheit](#betriebssicherheit)
13. [Display und Bildschirmabschaltung](#display-und-bildschirmabschaltung)
14. [Boot-Dateien im Überblick](#boot-dateien-im-überblick)

---

## Drei Wege, ein Ziel

Alle drei Wege ändern letztlich dieselben Dateien – vor allem
`/boot/firmware/config.txt`.

| Weg | Wann | Grenzen |
|-----|------|---------|
| **Desktop-GUI** | System mit Desktop, Standardeinstellungen | Nicht headless; deckt nicht alles ab |
| **`sudo raspi-config`** (TUI) | **Der Normalfall für Embedded und Headless** | Menügeführt, aber nicht jede Option vorhanden |
| **CLI / Dateien von Hand** | Alles Übrige (Splash-Screen, `cmdline.txt`, eigene Overlays) | Kein Sicherheitsnetz |

> ⚠️ **Namenswechsel zwischen den OS-Versionen:** Unter **Trixie** heisst das
> Desktop-Werkzeug **Control Centre** (*Preferences → Control Centre*), unter
> **Bookworm** hiess es **Raspberry Pi Configuration**. Anleitungen aus der Bookworm-Zeit
> nennen den alten Namen – die Einstellungen sind dieselben.

➜ **Für Projekte in diesem Skill gilt: `raspi-config` oder Datei, nicht GUI.** Ein
Edge-AI-Aufbau läuft headless; jede Einstellung, die nur per Maus gesetzt wurde, ist beim
nächsten Neuaufsetzen verloren. Was reproduzierbar sein muss, gehört als Zeile in
`config.txt` oder als Skriptschritt ins `plan.md`.

---

## Die zwei Dateien

| Datei | Wer liest sie | Wofür |
|-------|---------------|-------|
| `/boot/firmware/config.txt` | **Bootloader/Firmware**, vor dem Kernel | Hardware: Overlays, Parameter, Takt, PCIe, UART |
| `/boot/firmware/cmdline.txt` | **Linux-Kernel**, beim Übernehmen | Verhalten des OS: Root-Device, Konsole, `video=`, `earlycon` |

```bash
sudo nano /boot/firmware/config.txt
sudo nano /boot/firmware/cmdline.txt

cat /proc/cmdline          # was der Kernel TATSÄCHLICH bekommen hat
```

> 🔴 **`cmdline.txt` ist eine einzige Zeile.** Alles nach dem ersten Zeilenumbruch wird
> ignoriert. Ein «zur Übersicht» eingefügter Umbruch ist eine der undankbarsten
> Fehlerquellen: Das System bootet, aber die Hälfte der Parameter fehlt.

> ⚠️ **`/proc/cmdline` weicht von `cmdline.txt` ab** – die Firmware ergänzt und ändert
> Parameter, bevor sie den Kernel startet. Für die Fehlersuche zählt `/proc/cmdline`.

> ⚠️ **Der Pi 5 braucht eine nicht-leere `config.txt`** in der Boot-Partition. Eine leere
> Datei ist kein «Standardzustand», sondern ein Defekt.

### Kernparameter in `cmdline.txt`

| Eintrag | Bedeutung |
|---------|-----------|
| `console=serial0,115200` / `console=tty1` | Wohin Boot-Meldungen gehen |
| `root=/dev/mmcblk0p2` | Wo das Root-Dateisystem liegt |
| `rootfstype=ext4` | Dateisystemtyp der Root-Partition |
| `quiet` | Log-Level auf `KERN_WARNING` – unterdrückt fast alles beim Boot |
| `splash` | Plymouth-Startbild verwenden |
| `video=` | Auflösung/Orientierung im Konsolenbetrieb (KMS) |
| `usbhid.mousepoll=0` | Gegen träge oder ruckelnde Funkmäuse |
| `dwc_otg.speed=1` | USB-Controller auf Full Speed – **nur zur Diagnose**, danach entfernen |

---

## raspi-config – Menülandkarte

Die Pfade sind stabil genug, um sie in Anleitungen zu schreiben. Aufruf immer
`sudo raspi-config`; Navigation mit Pfeiltasten, Auswahl mit Enter, Buchstabe springt
alphabetisch (z.B. `E` in der Zeitzonenliste zu *Europe*).

| Pfad | Einstellung |
|------|-------------|
| `1 System Options` → `S8 Power LED` | LED-Verhalten (nur Zero-Familie) |
| `2 Display Options` → `D4 Composite` | Composite statt HDMI |
| `2 Display Options` → `D6/D7 Onscreen Keyboard` | Bildschirmtastatur ein/aus, auf welchem Schirm |
| `3 Interface Options` | SSH, VNC, SPI, I2C, 1-Wire, Serial Port, Raspberry Pi Connect |
| `4 Performance Options` → `P1 Overclock` | **Nur Pi 1 und Pi 2** |
| `5 Localisation Options` | Locale, Zeitzone, Tastatur, **WLAN-Land** |
| `6 Advanced Options` → `A1 Expand Filesystem` | Root-Partition auf die Medienkapazität ausdehnen |
| `6 Advanced Options` → `A2 Network Interface Names` | Vorhersagbare Interface-Namen (Standard: **aus**) |
| `6 Advanced Options` → `A3 Network Proxy Settings` | Proxy für All/HTTP/HTTPS/FTP + Ausnahmen |
| `6 Advanced Options` → `A4 Boot Order` | SD zuerst / NVMe-USB zuerst / Netzwerk |
| `6 Advanced Options` → `A5 Bootloader Version` | `E1 Latest` oder `E2 Default` |
| `6 Advanced Options` → `A6 Beta Access` | Beta-Repository ein/aus |
| `6 Advanced Options` → `A7 Wayland` | `W1 X11` (nicht empfohlen) / `W2 Labwc` |
| `6 Advanced Options` → `A8 PCIe Speed` | **PCIe Gen 3 – siehe Warnung unten** |
| `6 Advanced Options` → `A9 Network Install UI` | Immer / nur auf Shift bzw. bei Fehler |
| `6 Advanced Options` → `A11 Shutdown Behaviour` | `B1 Full power off` / `B2 VPU sleep mode` |
| `6 Advanced Options` → `A12 Logging` | Default / Volatile / Persistent / Auto / None |
| `6 Advanced Options` → `A13 WLAN Power Save` | Stromsparen des WLAN-Chips |
| `6 Advanced Options` → `A14 Link-local Fallback` | 169.254.x.x als Rückfallebene (Standard: **aus**) |

> ⚠️ **Unterpunkt-Nummern können sich zwischen OS-Versionen verschieben.** Die
> Menü**namen** sind der verlässlichere Anker; die Nummern hier entsprechen dem aktuellen
> Stand der offiziellen Dokumentation.

---

## Einstellungen mit Projektrelevanz

### 🔴 PCIe Gen 3 – `A8 PCIe Speed`

Bisher stand im Skill nur der `config.txt`-Weg. Es gibt auch den offiziellen:

```bash
sudo raspi-config        # 6 Advanced Options → A8 PCIe Speed → Yes
# entspricht:  dtparam=pciex1_gen=3  in /boot/firmware/config.txt
```

> **Wortlaut der Dokumentation:** Raspberry Pi empfiehlt diese Einstellung ausdrücklich
> **nicht**, ausser ein PCIe-HAT verlangt sie. Der Pi 5 ist für **PCIe Gen 2.0
> zertifiziert**; Gen 3 ist deshalb ab Werk deaktiviert. Ein Erzwingen kann zu
> **Datenkorruption oder Systeminstabilität** führen, wenn HAT oder Flachbandkabel die
> höhere Frequenz nicht mitmachen.

➜ Deckungsgleich mit der Regel in `pcie.md` und `SKILL.md`: **Gen 2 ist Spezifikation,
Gen 3 ist Opt-in auf eigenes Risiko.** Bei sporadischen I/O-Fehlern zuerst zurückstellen.

### USB-Strombegrenzung (Pi 5, 500, 500+)

Betrifft **nur** Aufbauten **ohne** offizielles Netzteil.

```
raspi-config → 4 Performance Options → Disable USB Current Limit
```

> ⚠️ Aufheben der Begrenzung erlaubt stromhungrigere USB-Geräte, kann aber
> **Instabilität, Abstürze oder Datenverlust** verursachen, wenn das Netzteil die
> zusätzliche Last nicht sicher liefert.

➜ **Richtige Reihenfolge:** erst das Netzteil dimensionieren (siehe
`setup-provisioning.md`), dann – falls überhaupt nötig – die Grenze anheben. Nicht
umgekehrt. Ob die Firmware die hohe Grenze aktiviert hat, lässt sich auslesen (siehe
[Abschnitt 7](#was-die-firmware-über-das-system-verrät)).

### Overlay-Dateisystem – schreibgeschützter Dauerbetrieb

Zwei getrennte Schalter unter *Performance Options → Overlay File System*:

| Schalter | Wirkung |
|----------|---------|
| **Use Overlay** | Root-Dateisystem read-only, Änderungen landen in einem RAM-Overlay und sind nach dem Neustart **weg** |
| **Write-protect Boot Partition** | `/boot` gegen Änderungen sperren |

➜ **Für Kiosk-, Ausstellungs- und Dauerbetriebs-Aufbauten ist das die Antwort auf
korrupte SD-Karten nach Stromausfall.** Preis: Das System vergisst alles ausserhalb von
`/boot`. Logs, Messdaten und Modelle müssen dann auf ein separat gemountetes, beschreibbares
Medium – oder gar nicht anfallen. Vor dem Einschalten den Aufbau fertig konfigurieren, und
für Änderungen das Overlay wieder abschalten.

### Logging – SD-Karten-Schonung

```
raspi-config → 6 Advanced Options → A12 Logging
```

| Option | Ablage | Für |
|--------|--------|-----|
| `2 Volatile` | nur RAM (`/run/log/journal`), nach Reboot weg | Schreiblast auf der SD-Karte senken |
| `3 Persistent` | Platte (`/var/log/journal`), überlebt Reboots | Fehlersuche über längere Zeit |
| `4 Auto` | Persistent, falls `/var/log/journal` existiert, sonst volatile | Standardverhalten |
| `5 None` | keine Protokollierung | Nur wenn wirklich nichts geschrieben werden darf |

➜ **Zielkonflikt benennen, nicht auflösen:** `Volatile` schont die Karte, macht aber genau
die Fehlersuche unmöglich, die man bei einem sporadisch abstürzenden Feldgerät braucht.
Für Dauerbetrieb im Feld eher `Persistent` **plus** ein besseres Boot-Medium (SSD über
`pcie.md`) als `Volatile` auf einer Billigkarte.

### Boot-Reihenfolge – `A4 Boot Order`

| Option | Reihenfolge |
|--------|-------------|
| `B1 SD Card Boot` (Standard) | SD → NVMe → USB |
| `B2 NVMe/USB Boot` | NVMe → USB → SD |
| `B3 Network Boot` | SD → Netzwerk (PXE) |

➜ Wer eine NVMe am M.2 HAT+ als Systemlaufwerk betreibt, braucht `B2` – sonst startet das
Gerät bei eingelegter SD-Karte wieder von dieser, ohne dass es auffällt.

### Abschaltverhalten – `A11 Shutdown Behaviour`

| Option | Bedeutung |
|--------|-----------|
| `B1 Full power off` | Vollständig aus |
| `B2 VPU sleep mode` | Restspannung bleibt, schnelleres Wiederanlaufen |

**Standard je Modell:** Pi 400, 500, 500+ und CM5 → *Full power off*; **Pi 4B, Pi 5 und
CM4 → VPU sleep mode**.

➜ Das ist die raspi-config-Seite dessen, was `pcie.md` unter **Power States** elektrisch
beschreibt: Nach `sudo halt` ist ein Pi 5 im Standardfall **nicht spannungsfrei**. Für
batteriebetriebene oder solargespeiste Aufbauten `B1` setzen – und trotzdem messen.

### Dateisystem ausdehnen – `A1 Expand Filesystem`

> ⚠️ **Keine Rückfrage.** Die Partition wird sofort vergrössert, wirksam nach dem
> Neustart. Raspberry Pi OS macht das beim ersten Boot ohnehin automatisch; nötig wird der
> Menüpunkt vor allem nach dem Klonen auf ein **grösseres** Medium.

### Netzwerk-Feinheiten

| Einstellung | Standard | Wann anfassen |
|-------------|----------|---------------|
| `A2 Network Interface Names` | aus | Nur wenn stabile Namen über Hardwarewechsel hinweg gebraucht werden – ersetzt `eth0`/`wlan0` |
| `A14 Link-local Fallback` | aus | Nur bei Aufbauten ohne DHCP; kann sonst die Netzkonfiguration stören |
| `A13 WLAN Power Save` | – | **Nicht anfassen**, ausser ein Raspberry-Pi-Engineer empfiehlt es; Abschalten kann die Verbindung stabilisieren, erhöht aber den Verbrauch |
| `A3 Network Proxy Settings` | – | Verwaltete Netze (Schule, Firma) |

**Feste IP-Adresse:** Die Dokumentation empfiehlt ausdrücklich die **DHCP-Reservation am
Router** (statische Lease über die MAC-Adresse) gegenüber einer statisch am Gerät
gesetzten Adresse. Wer sie dennoch am Gerät setzt, tut das mit `nmcli` und muss selbst
dafür sorgen, dass die Adresse ausserhalb des DHCP-Pools liegt und mit niemandem
kollidiert.

**Netzwerkpriorität** bei mehreren bekannten WLANs: höhere Zahl gewinnt, `0` ist neutral
(Standard), negative Werte werden nur genutzt, wenn sonst nichts verfügbar ist.

---

## Device Tree, Overlays und Parameter

Der Device Tree beschreibt die Hardware. **Overlays** sind Teilbeschreibungen für optionale
Hardware, **Parameter** sind benannte Kleinänderungen daran. Zusammen sind sie der Grund,
warum ein Sensor-HAT ohne Kernel-Übersetzung funktioniert.

### In `config.txt`

```ini
dtoverlay=acme-board                  # overlays/acme-board.dtbo laden
dtoverlay=lirc-rpi,gpio_out_pin=16    # Overlay mit Parametern in einer Zeile
dtparam=i2c_arm=on,spi=on             # Parameter des Basis-DTB
dtparam=i2c,i2s                       # Kurzform: =on ist die Vorgabe
dtoverlay=                            # beendet den Geltungsbereich des letzten Overlays
```

> ⚠️ **Overlay-Parameter gelten nur bis zum nächsten `dtoverlay=`.** Wer `dtparam`-Zeilen
> unter das falsche Overlay schreibt, setzt sie am eigentlichen Ziel vorbei – ohne
> Fehlermeldung.

> 🔴 **Eine Zeile in `config.txt` darf maximal 98 Zeichen lang sein** – alles darüber wird
> stillschweigend verworfen. Das trifft genau die Zeilen, die lang werden: ein Overlay mit
> mehreren angehängten Parametern. Ab etwa 80 Zeichen die Parameter besser auf eigene
> `dtparam=`-Zeilen unterhalb des Overlays verteilen. Details in `config-txt.md`.

### Zur Laufzeit

```bash
dtoverlay -a                     # alle Overlays, aktive markiert
dtoverlay -l                     # aktive Overlays und Parameter
dtoverlay -h <overlay>           # Hilfe zu einem Overlay
dtoverlay -h uart2               # z.B. Pins und Optionen einer zusätzlichen UART
sudo dtoverlay <overlay> <param>=<wert>
sudo dtoverlay -r <overlay>      # entfernen (nur zur Laufzeit geladene)
```

> ⚠️ Overlays, die die **Firmware** beim Booten angewandt hat, sind «eingebacken»: Sie
> tauchen in `dtoverlay -l` nicht auf und lassen sich zur Laufzeit nicht entfernen.
> Overlays bilden einen **Stapel** – ein tiefer liegendes zu entfernen entfernt und
> reaktiviert alles darüber.

Die vollständige Liste der mitgelieferten Overlays und ihrer Parameter steht in
**`/boot/firmware/overlays/README`** – die verlässlichste Quelle, weil sie zur installierten
Firmware gehört.

### Board-spezifische Aliase für I2C

Die Firmware legt modellunabhängige Namen an, weil zwei frühe Pi-1-B-Revisionen die
I2C-Busse vertauscht haben:

| Alias | Bedeutung |
|-------|-----------|
| `i2c_arm` / `i2c_arm_baudrate` | Der Bus am 40-Pin-Header – **der, den man meint** |
| `i2c_vc` / `i2c_vc_baudrate` | Der Bus der GPU: Kamera und HAT-EEPROM |

> 🔴 **`i2c_vc` nicht aus Neugier einschalten.** Laut Dokumentation kann das
> **Kameramodul oder das Touch-Display lahmlegen**. Für eigene HAT-EEPROMs ist ein
> Software-I2C über `i2c-gpio` der empfohlene Weg.

Eigene Overlays sollten `&i2c_arm` referenzieren, nicht `&i2c1`.

### Overlay-Map: warum ein Overlay auf dem Pi 5 anders heisst

Die Firmware lädt `overlays/overlay_map.dtb` und bildet Overlay-Namen auf Plattformen ab:

| Plattformname | Modelle |
|---------------|---------|
| `bcm2835` | BCM2835/2836/2837 und RP3A0 – alle älteren Pi |
| `bcm2711` | Pi 4B, CM4, CM4S, Pi 400 |
| **`bcm2712`** | **Pi 5, CM5, Pi 500, Pi 500+** |

Beispiel aus der Map: `disable-bt` wird auf `bcm2712` automatisch durch **`disable-bt-pi5`**
ersetzt. `uart5` gibt es nur für `bcm2711`.

➜ **Konsequenz für die Fehlersuche:** «Das Overlay aus dem Forum tut auf dem Pi 5 nichts»
ist oft kein Tippfehler, sondern eine fehlende Plattform-Zuordnung. Ein nicht in der Map
genanntes Overlay gilt als für alle Plattformen kompatibel.

### Diagnose

```bash
sudo vclog --msg                       # Meldungen der Firmware – zuerst hier nachsehen
dtc -I fs /proc/device-tree            # aktueller Device Tree in lesbarer Form

# Wirkung eines Overlays zeigen, ohne es scharfzuschalten
dtmerge /boot/firmware/bcm2712-rpi-5-b.dtb base.dtb -
dtmerge base.dtb merged.dtb /boot/firmware/overlays/<name>.dtbo
dtdiff base.dtb merged.dtb
```

Zusätzliche Firmware-Protokolle mit `dtdebug=1` in `config.txt` einschalten.

> Der Loader **überspringt fehlende Overlays und ungültige Parameter stillschweigend**.
> Wenn eine `dtoverlay`-Zeile wirkungslos bleibt, ist `sudo vclog --msg` der erste Griff –
> nicht `dmesg`.

### Grenzen zur Laufzeit

- Teile des Device Tree werden **nur beim Booten** ausgewertet; ein Overlay zur Laufzeit
  ändert sie nicht.
- Nur Knoten auf oberster Ebene oder unterhalb eines Bus-Knotens werden erkannt.
- Takt- und Interrupt-Controller werden nur beim Booten gesucht – Overlays, die solche
  Knoten anlegen, funktionieren zur Laufzeit nicht.
- Das Entfernen eines Sound-Overlays kann hängen oder das System stören, solange ALSA
  darauf zugreift.

➜ **Für reproduzierbare Aufbauten: Overlays in `config.txt`, nicht zur Laufzeit.** Die
`dtoverlay`-Kommandos sind Werkzeuge zum Ausprobieren, nicht zum Konfigurieren.

---

## Bootloader und EEPROM

Betrifft **Pi 4B und neuer** sowie alle Keyboard-Computer. Der Bootloader liegt im EEPROM,
nicht auf der Karte.

```bash
sudo apt update && sudo apt full-upgrade   # ZUERST: aktuelles rpi-eeprom-Paket
sudo rpi-eeprom-update                     # CURRENT / LATEST / RELEASE anzeigen
rpi-eeprom-config                          # laufende Konfiguration lesen
sudo -E rpi-eeprom-config --edit           # bearbeiten, Update beim Reboot einplanen
sudo rpi-eeprom-config --apply boot.conf   # gespeicherte Konfiguration anwenden
sudo reboot
```

Release-Track wechseln: `raspi-config` → `6 Advanced Options` → `A5 Bootloader Version`
(`E1 Latest` = neueste Funktionen, `E2 Default` = stabil, getestet).

### Verbrauch im ausgeschalteten Zustand senken

Ein heruntergefahrener Pi 5 zieht weiterhin **1 bis 1,4 W** – über ein Jahr gerechnet
mehr als 10 kWh, nur um abgeschaltet dazuliegen. Eine Zeile in der EEPROM-Konfiguration
bringt das auf **etwa 0,01 W**:

```bash
sudo rpi-eeprom-config -e
# POWER_OFF_ON_HALT=1
```

Das ist der Unterschied zwischen «Faktor 100» und «Netzstecker ziehen». Relevant für
Batterie- und Solarbetrieb ebenso wie für Klassensätze, die über die Ferien am Netz bleiben.

⚠️ **Nebenwirkung:** Im PMIC-Standby sind alle Ausgänge abgeschaltet, die 5 V liegen aber
weiterhin an – **manche HATs kommen damit nicht zurecht**. Am Pi 5 weckt die Power-Taste
das Gerät wieder; auf älteren Modellen muss zusätzlich `WAKE_ON_GPIO=0` gesetzt sein, und
das Aufwecken erfolgt über GPIO3 oder GLOBAL_EN gegen Masse.

> ⚠️ **CM4 und CM4S können den Bootloader nicht automatisch aktualisieren** – ihr Boot-ROM
> lädt keine `recovery.bin` aus dem eMMC. Dort sind `rpiboot` bzw. `flashrom` nötig.

### `BOOT_ORDER` – die Bootreihenfolge lesen und schreiben

`BOOT_ORDER` ist eine 32-Bit-Zahl, in der **jede Hex-Ziffer für eine Bootquelle steht**.
Gelesen wird **von rechts nach links**, bis zu acht Ziffern.

| Ziffer | Quelle |
|--------|--------|
| `0x1` | SD-Karte (bzw. eMMC beim CM4) |
| `0x2` | Netzwerk (PXE/TFTP) |
| `0x3` | RPIBOOT (USB-Device-Modus, für Provisionierung) |
| `0x4` | USB-Massenspeicher |
| `0x5` | USB 2.0 an der Typ-C-Buchse (nicht am Pi 5) |
| **`0x6`** | **NVMe** – Pi 5, 500+, CM4, CM5 |
| `0x7` | HTTP-Boot über Ethernet |
| `0xe` | Anhalten und Fehlermuster zeigen |
| **`0xf`** | **Von vorn beginnen** (Endlosschleife) |

```
BOOT_ORDER=0xf416
              ││││
              │││└─ 6 = zuerst NVMe
              ││└── 1 = dann SD-Karte
              │└─── 4 = dann USB
              └──── f = von vorn
```

| Wert | Bedeutung |
|------|-----------|
| `0xf41` | SD, dann USB, dann wiederholen (**Voreinstellung**) |
| `0xf14` | USB zuerst, dann SD |
| `0xf21` | SD, dann Netzwerk – siehe `remote-access.md` |
| `0xf416` | **NVMe zuerst**, dann SD, dann USB |

🔴 **Die abschliessende `f` nicht vergessen.** Ohne sie hört der Bootloader nach dem
letzten Eintrag auf, statt es erneut zu versuchen – ein Gerät, dessen Datenträger beim
Kaltstart ein paar Sekunden zu langsam ist, bootet dann gar nicht mehr.

```bash
vcgencmd bootloader_config                 # laufende Konfiguration
sudo rpi-eeprom-config --edit              # ändern
```

Bequemer geht es über `raspi-config` → `6 Advanced Options` → `Boot Order`.

**Für ein NVMe-Gerät ohne HAT+-Kennung** zusätzlich:

```ini
PCIE_PROBE=1
```

HAT+-konforme Geräte werden automatisch erkannt und brauchen das nicht.

### Wenn die gewünschte Partition nicht bootet

| Eigenschaft | Wirkung |
|-------------|---------|
| `PARTITION=2` | Bootpartition festlegen, wenn nicht per `reboot 2` oder `autoboot.txt` gesetzt |
| `PARTITION_WALK=1` | Ist die verlangte Partition nicht bootfähig, **alle anderen der Reihe nach probieren** (Voreinstellung) |
| `SD_BOOT_MAX_RETRIES` | Wie oft SD-Boot wiederholt wird, bevor die nächste Quelle drankommt (`-1` = endlos) |
| `NET_BOOT_MAX_RETRIES` | dasselbe für den Netzwerk-Boot |
| `REBOOT_ON_FATAL_ERROR` | Nach einem schweren Fehler dreimal blinken und neu starten (Voreinstellung `1`) |

`PARTITION_WALK` ist die Rettungsleine für A/B-Boot-Aufbauten: Schlägt die aktive Partition
fehl, sucht der Bootloader selbstständig eine bootfähige. Bedingte Filter greifen auch
hier – so lässt sich ein durch den Watchdog ausgelöster Neustart auf eine Rettungspartition
umlenken:

```ini
[partition=62]
PARTITION=2
SD_QUIRKS=1
HDMI_DELAY=0
```

### Sich selbst aktualisierender Bootloader

`ENABLE_SELF_UPDATE=1` (Voreinstellung) lässt den Bootloader ein Update aus dem
Boot-Dateisystem einspielen – auch beim Netzwerk-Boot.

> ⚠️ **`FREEZE_VERSION=1` friert den Bootloader ein** und übersteuert dabei
> `ENABLE_SELF_UPDATE`. Praktisch für Geräteflotten mit geprüftem Stand oder wenn mehrere
> Betriebssysteme im Wechsel laufen. **Rückgängig geht das nur per SD-Karten-Boot mit
> `recovery.bin`** – nicht mehr über `rpi-eeprom-config`. Vor dem Setzen wissen, wie man
> es wieder loswird.

### Diagnose ohne Betriebssystem

Bootet ein Pi 4 oder neuer nicht, zeigt der Bootloader **ohne Boot-Medium** eine
Diagnoseseite über HDMI: Bootloader-Version, Boot-Reihenfolge, erkannte Partitionen,
Netzwerkstatus und Fehlercodes. Dafür Gerät ausschalten, **Boot-Medium entfernen**, wieder
einschalten.

| Zeile | Inhalt |
|-------|--------|
| `bootloader` | Version, `RO` bei schreibgeschütztem EEPROM, Build-Datum |
| `board` | Board-Revision, Seriennummer, MAC-Adresse |
| `boot` | Aktueller Modus, `BOOT_ORDER`, Wiederholungszähler |
| `SD` | Karte erkannt oder nicht |
| `net` / `tftp` | Verbindungsstatus, IP, Gateway, TFTP-Server |
| `display` | Ob HDMI-Hotplug und EDID erkannt wurden |

Abschaltbar über `DISABLE_HDMI=1`; `HDMI_DELAY` steuert, wie lange bis zur Anzeige
gewartet wird (Voreinstellung 5 s, damit die Seite bei normalem Boot nicht aufblitzt).

---

## Echtzeituhr (RTC) am Pi 5

Der Pi 5 hat eine eingebaute RTC. Ohne Netzwerk kennt ein Pi sonst beim Booten die Zeit
nicht – für Datenlogger und Feldgeräte ist das der Unterschied zwischen brauchbaren und
wertlosen Zeitstempeln.

```
[    1.295799] rpi-rtc soc:rpi_rtc: setting system clock to 2023-08-16T15:58:50 UTC
```

> ℹ️ **Die RTC funktioniert auch ohne Batterie** – dann allerdings nur, solange das Board
> am Strom hängt.

### Weckalarm – periodisch aufwachen bei ~3 mA

Das Board kann sich schlafen legen und zu einem gesetzten Zeitpunkt selbst wieder
einschalten. Im Schlafzustand zieht es rund **3 mA**. Für Zeitrafferaufnahmen,
Messreihen und alles, was stündlich kurz etwas tut, ist das der Unterschied zwischen
Batteriebetrieb und Netzanschluss.

```bash
sudo -E rpi-eeprom-config --edit
#   POWER_OFF_ON_HALT=1
#   WAKE_ON_GPIO=0
```

```bash
echo +600 | sudo tee /sys/class/rtc/rtc0/wakealarm   # in 600 s aufwachen
sudo halt
```

### Batterie – die Wahl ist nicht frei

Die offizielle Zelle ist ein **wiederaufladbarer Lithium-Mangan-Knopfakku** mit
JST-SH-Stecker für den **J5**-Anschluss (zwischen RTC-Batterieanschluss und Platinenkante,
rechts neben der USB-C-Buchse).

| Zelle | Eignung |
|-------|---------|
| **Lithium-Mangan, wiederaufladbar** | ✅ die offizielle Wahl |
| Nicht wiederaufladbare Lithium-Zelle | ❌ **nicht empfohlen** – der Pi zieht mehr als dedizierte RTC-Module, die Zelle ist schnell leer |
| **Lithium-Ionen-Zelle** | 🔴 **nicht verwenden** |

Bei einigen µA Ruhestrom hält die offizielle Zelle **mehrere Monate**.

### Laden aktivieren

Das Laden ist **ab Werk abgeschaltet**. Eine eingesteckte Batterie wird also nicht
geladen, bis man es einschaltet:

```ini
# In /boot/firmware/config.txt – Spannung in µV
dtparam=rtc_bbat_vchg=3000000
```

```bash
grep . /sys/class/rtc/rtc0/charging_voltage*
# charging_voltage:0            ← 0 bedeutet: Laden ist aus
# charging_voltage_max:4400000
# charging_voltage_min:1300000
```

Geladen wird mit konstant 3 mA. Zum Abschalten die `rtc_bbat_vchg`-Zeile wieder entfernen.

---

## Tastatur der Keyboard-Computer konfigurieren

Betrifft **Pi 500 und 500+**. Tastenbelegung lässt sich auf **beiden** ändern, die
Beleuchtung nur auf dem **500+** – nur dieser hat beleuchtete Tasten. Die Firmware basiert
auf **Vial QMK**.

```bash
sudo apt install rpi-keyboard-fw-update
sudo rpi-keyboard-fw-update          # Firmware aktualisieren – zwingend zuerst
sudo apt install rpi-keyboard-config
```

⚠️ **Ohne das Firmware-Update greifen die Konfigurationsbefehle nicht.** Das ist der
Schritt, den man beim Nachlesen überspringt.

```bash
rpi-keyboard-config info --ascii     # Modell, Sperrstatus und Tastaturdiagramm
rpi-keyboard-config help
```

Das Diagramm aus `info --ascii` liefert die **Zeilen-/Spaltenkoordinaten**, die alle
weiteren Befehle erwarten.

### Tasten umbelegen

```bash
rpi-keyboard-config list-keycodes              # alle Keycodes
rpi-keyboard-config list-keycodes --category basic
rpi-keyboard-config key get-all                # aktuelle Belegung
rpi-keyboard-config key set 2 2 KC_R           # Zeile 2, Spalte 2 → R
```

Es gibt **vier Ebenen** (0–3); `Fn` schaltet standardmässig von 0 auf 1. Mit `--layer`
lässt sich jeder der Befehle auf eine andere Ebene anwenden.

Tastendrücke mitlesen (etwa um eine defekte Taste zu prüfen) verlangt vorher ein
Entsperren:

```bash
rpi-keyboard-config unlock       # führt durch eine Tastenkombination (Enter + Esc)
rpi-keyboard-config key watch    # --no-leds unterdrückt die rote Rückmeldung
rpi-keyboard-config lock
```

> ℹ️ Wurden Enter oder Esc selbst umbelegt, gilt für das Entsperren die **physische
> Position**, nicht die neue Beschriftung – der Befehl nennt die richtigen Tasten.

### Beleuchtung (nur Pi 500+)

Ab Werk ist fast alles aus: nur die Power-LED, die Startanimation und die
Feststelltasten-Anzeige leuchten. Sieben Presets, umschaltbar über **Fn + F4** (rückwärts
mit **Fn + Shift + F4**):

| | Preset | |
|---|---|---|
| 0 | Off | Voreinstellung |
| 1 | Solid Colour White | |
| 2 | Solid Colour | Farbe über Fn + F3 |
| 3 | Gradient Left Right | fester Regenbogen |
| 4 | Cycle Pinwheel | animierter Regenbogen |
| 5 | Typing Heatmap | häufig getippte Tasten werden röter |
| 6 | Solid Reactive Simple | leuchtet auf Tastendruck |

**Ohne Konfigurationssoftware:** Farbe **Fn + F3**, Helligkeit **Fn + F5** (dunkler) und
**Fn + F6** (heller). `Shift` kehrt die Richtung jeweils um.

```bash
rpi-keyboard-config list-effects
rpi-keyboard-config effect "Cycle Spiral" --speed 42     # nur bis zum Neustart
rpi-keyboard-config preset set 3 "Rainbow Beacon" --speed 140
rpi-keyboard-config brightness 128                       # 0–255
```

Parameter `--speed`, `--sat` und `--hue` nehmen Werte **0–255** (Standard: Speed 128,
Sättigung 255, Farbton = globaler Wert). Statische Effekte ignorieren `--speed`.

Einzelne LEDs setzt der Effekt `direct`:

```bash
rpi-keyboard-config led set "2,6" --colour "85,255,255"   # HSV
rpi-keyboard-config leds set --colour red                  # auch rgb(255,0,0)
rpi-keyboard-config leds save
```

Die Power-LED lässt sich von keinem Effekt beeinflussen: **rot** = Strom liegt an, Gerät
aus; **grün** = eingeschaltet; **blinkend** = SD-Karten-Zugriff.

### Zurücksetzen

```bash
rpi-keyboard-config reset-presets     # nur Beleuchtung
rpi-keyboard-config reset-keymap      # nur Tastenbelegung, alle Ebenen
sudo rpi-keyboard-fw-update -w -i     # beides – löscht den Flash-Bereich
```

> 🔴 **Wenn die Tastatur so verstellt ist, dass keine Eingabe mehr möglich ist:** Eine
> **USB-Tastatur** an einen freien Port stecken und den Reset von dort ausführen. Die
> Einstellungen liegen im Flash und überleben Neustart **und Firmware-Update** – sie
> verschwinden also nicht von selbst.

---

## OTP-Speicher – einmal beschreibbar

Jeder Pi hat einen **One-Time-Programmable**-Bereich im SoC. Jedes Bit lässt sich genau
einmal von 0 auf 1 setzen – wie eine Sicherung, die man durchbrennt.

```bash
vcgencmd otp_dump
```

🔴 **Jede Änderung ist unumkehrbar.** Es gibt keinen Weg zurück, auch nicht über
Neuinstallation oder Firmware-Reset.

### Interessante Zeilen

Die Nummerierung unterscheidet sich zwischen den SoC-Generationen – eine Anleitung für den
Pi 4 liest auf dem Pi 5 die falschen Zeilen:

| Inhalt | bis BCM2711 | **BCM2712 (Pi 5)** |
|--------|-------------|--------------------|
| Seriennummer | Zeile 28 | **Zeile 31** |
| Board-Revision | Zeile 30 | **Zeile 32** |
| Kunden-Zeilen | 36–43 | **77–84** |
| Ethernet-MAC | 64–65 | 50–51 (Kunde: 87–88) |
| WLAN-MAC | – | 52–53 (Kunde: 89–90) |

### Eigene Werte ablegen

Acht 32-Bit-Zeilen stehen zur freien Verfügung – für Gerätenummern, Chargenkennungen oder
Standortcodes, die eine Neuinstallation überleben sollen:

```bash
# Zeilen 4, 5, 6 beschreiben
sudo vcmailbox 0x00038021 20 20 4 3 0x11111111 0x22222222 0x33333333

# Zurücklesen
sudo vcmailbox 0x00030021 20 20 4 3 0 0 0
```

Ergänzend zu `config-txt.md`, wo diese Zeilen als bedingte Filter (`cust_otpN`) verwendet
werden – so kann sich **dieselbe SD-Karte je nach Gerät anders verhalten**.

### Seriennummer einfacher lesen

Für den Normalfall braucht es kein `vcmailbox`:

```bash
cat /proc/device-tree/serial-number      # vollständige 64-Bit-Seriennummer
vcgencmd otp_dump | grep '^28:'          # bzw. 31: auf dem Pi 5
```

> ⚠️ **Zugriff auf die OTP-Zeilen läuft über `/dev/vcio`**, das der Gruppe `video`
> vorbehalten ist. Der Pi hat **keinen hardwaregeschützten Schlüsselspeicher** – wer
> geheimes Material dort ablegt, sollte das nur zusammen mit Secure Boot tun.

### Beta Access ist nicht `rpi-update`

| Weg | Was er tut | Risiko |
|-----|-----------|--------|
| **`A6 Beta Access`** | Schaltet ein **Beta-Repository** frei; Installation danach normal über `apt` | Vorabversionen, aber paketverwaltet |
| **`rpi-update`** | Zieht **ungetestete** Firmware direkt an APT vorbei | Kann das System unbootbar machen |

➜ Damit ergänzt sich die Regel aus `os-and-software.md`: Wer neuere Firmware **testen**
will, nimmt Beta Access – nicht `rpi-update`. `rpi-update` bleibt dem Fall vorbehalten,
dass Raspberry Pi es ausdrücklich empfiehlt.

---

## Was die Firmware über das System verrät

Die Firmware legt Werte unter `/proc/device-tree/chosen/` ab. Das ist der einzige Weg, an
manche Angaben **ohne Messgerät** heranzukommen – besonders wertvoll bei Strom- und
Speicherfragen.

```bash
# Zeichenketten direkt lesen
strings /proc/device-tree/chosen/rpi-serial64

# 32-Bit-Integer (Big Endian) hexadezimal ausgeben
od -v -An -t x1 /proc/device-tree/chosen/power/max_current | tr -d ' '
```

### Stromversorgung – `/chosen/power/` (Pi 5)

| Eigenschaft | Bedeutung |
|-------------|-----------|
| **`max_current`** | Maximalstrom in **mA**, den das Netzteil laut USB-C/USB-PD/PoE meldet |
| **`usb_max_current_enable`** | 0 = Peripherie auf die **niedrige** Grenze gedeckelt, ≠ 0 = hohe Grenze aktiv |
| `usb_over_current_detected` | ≠ 0, wenn beim USB-Boot eine Überstromabschaltung auftrat |
| `rpi_power_supply` | USB-VID/Product-VDO des offiziellen 27-W-Netzteils, falls angeschlossen |
| `power_reset` | Bitfeld: warum der PMIC zurückgesetzt hat |
| `usbpd_power_data_objects` | Rohe USB-PD-Objekte – für Fehlerberichte: `hexdump -C` |

**`power_reset` – Bitbedeutung:**

| Bit | Grund |
|-----|-------|
| 0 | Überspannung |
| 1 | Unterspannung |
| 2 | Übertemperatur |
| 3 | Enable-Signal |
| 4 | Watchdog |

> ➜ **Das ist der Beweis für den 600-mA-Fall.** `setup-provisioning.md` beschreibt, dass
> ein Pi 5 an einem 3-A-Netzteil die Peripherie auf 600 mA begrenzt, **ohne**
> Unterspannungswarnung. Statt zu raten, lassen sich `max_current` und
> `usb_max_current_enable` direkt auslesen – und die Diskussion ist beendet.
>
> Bei Laborsteckernetzteilen am GPIO-Header kennt die Firmware die Belastbarkeit nicht;
> dort muss `PSU_MAX_CURRENT` in der Bootloader-Konfiguration gesetzt werden.

### System-Identität

| Eigenschaft | Bedeutung |
|-------------|-----------|
| **`rpi-sdram-size-gbit`** | Physische RAM-Grösse in **Gigabit**, unbeeinflusst von Carveouts und `total_mem` |
| `rpi-serial64` | 64-Bit-Seriennummer als Zeichenkette |
| `rpi-machine-id` | Stabile 128-Bit-Kennung (Hash aus Seriennummer, ab Pi 4 auch MAC) |
| `rpi-duid` | Pi 5: Zeichenkette des QR-Codes auf der Platine |
| `rpi-boardrev-ext` | Erweiterter Board-Revisionscode aus OTP |
| `/chosen/bootloader/boot-mode` | Von welchem Medium tatsächlich gebootet wurde |
| `/chosen/bootloader/partition` | Verwendete Partitionsnummer |
| `/chosen/bootloader/pm_rsts` | `PM_RSTS`-Register beim Booten |

> ➜ **`rpi-sdram-size-gbit` löst ein bekanntes Problem des Skills.** `vcgencmd get_mem arm`
> liefert auf Geräten über 1 GB einen falschen Wert (siehe `os-and-software.md`), und die
> Speichergrösse im Board-Revisionscode kann Nicht-Zweierpotenzen wie 3 GB gar nicht
> abbilden. Für Skripte, die die Gerätekapazität ermitteln, ist dieser Wert die richtige
> Quelle.
>
> `rpi-machine-id` ist die saubere Antwort auf «wie identifiziere ich die Geräte im
> Klassensatz eindeutig» – stabil, ohne eigene Datei auf der Karte.

---

## Externe Datenträger dauerhaft einbinden

Relevant, sobald Modelle, Datensätze oder Aufnahmen nicht mehr auf die Boot-Karte passen.

> ⚠️ **Raspberry Pi OS Lite mountet nicht automatisch.** Auf den Desktop-Editionen landen
> FAT, NTFS und HFS+ automatisch unter `/media/pi/<LABEL>` – headless passiert nichts. Das
> ist der Grund, warum «der Stick geht auf meinem Desktop-Pi, aber nicht auf dem
> Feldgerät».

```bash
# 1. Gerät finden
sudo lsblk -o UUID,NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,MODEL
sudo blkid

# 2. Treiber nachrüsten, falls nötig
sudo apt install exfat-fuse      # exFAT
sudo apt install ntfs-3g         # NTFS beschreibbar (ohne: nur lesend)

# 3. Mountpunkt anlegen und einbinden
sudo mkdir /mnt/mydisk
sudo mount /dev/sda1 /mnt/mydisk
```

### Dauerhaft über `/etc/fstab`

```
UUID=5C24-1453 /mnt/mydisk ext4 defaults,auto,users,rw,nofail,x-systemd.device-timeout=30 0 0
```

| Option | Warum |
|--------|-------|
| **`UUID=`** statt `/dev/sda1` | Gerätenamen wechseln je nach Steckreihenfolge |
| **`nofail`** | 🔴 **Ohne diese Option bootet der Pi nicht, wenn das Medium fehlt** |
| `x-systemd.device-timeout=30` | Ohne sie wartet der Start **90 Sekunden** auf ein fehlendes Medium |
| `,umask=000` | Nur bei FAT/NTFS – sonst darf nur root schreiben |

➜ **`nofail` ist für Feldgeräte nicht optional.** Ein Gerät, das nach einem abgezogenen
USB-Stick nicht mehr hochkommt und headless in einem Schaltschrank sitzt, ist ein
Serviceeinsatz.

### Aushängen

```bash
sudo umount /mnt/mydisk

# «target is busy»? – herausfinden, wer das Medium offen hält
sudo apt install lsof
lsof /mnt/mydisk
```

Häufigste Ursache für «target is busy»: Ein Terminal steht noch im gemounteten Verzeichnis.

---

## Betriebssicherheit

Für ein Gerät, das dauerhaft im Netz hängt – Kamera-Node, Sensor-Gateway, Klassensatz.

### SSH härten

```bash
sudo nano /etc/ssh/sshd_config
#   AllowUsers alice bob        # nur diese Konten dürfen sich anmelden
#   DenyUsers  jane john        # oder gezielt sperren
sudo systemctl restart ssh
```

Zusätzlich empfiehlt die Dokumentation **schlüsselbasierte Anmeldung** statt Passwort und
– bei per SSH erreichbaren Geräten – einen täglichen Cron-Job, der gezielt den SSH-Server
aktualisiert:

```bash
apt install openssh-server
```

### Firewall (UFW)

> 🔴 **Reihenfolge ist entscheidend.** Wer UFW über eine SSH-Verbindung aktiviert, **ohne
> vorher SSH freizugeben, sperrt sich aus** – bei einem headless Gerät heisst das: Karte
> ausbauen.

```bash
sudo apt update && sudo apt install ufw
sudo ufw status                        # nach der Installation: inactive
sudo ufw default deny incoming
sudo ufw allow ssh                     # ZUERST – vor dem enable
sudo ufw allow 80/tcp                  # falls ein Webserver läuft
sudo ufw enable
sudo ufw status verbose
```

Nützliche Ergänzungen:

```bash
sudo ufw --dry-run allow 22            # Wirkung zeigen, ohne etwas zu ändern
sudo ufw limit ssh/tcp                 # Ratenbegrenzung gegen Brute-Force
sudo ufw allow in on eth0 to any port 80 proto tcp
sudo ufw status numbered && sudo ufw delete <nummer>
```

### fail2ban

```bash
sudo apt install fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

```ini
[ssh]
enabled  = true
port     = ssh
filter   = sshd
backend  = systemd
maxretry = 3
bantime  = -1       ; negativ = dauerhaft sperren
```

> ⚠️ Die Standardaktion `iptables-multiport` sperrt eine auffällige IP-Adresse auf **allen**
> Ports. Bei `bantime = -1` und einem Tippfehler beim eigenen Passwort sperrt man sich
> selbst dauerhaft aus. Für Geräte ohne physischen Zugang lieber eine endliche Sperrzeit.

### Und das Naheliegende

Nur die **jeweils aktuelle Hauptversion** von Raspberry Pi OS bekommt alle
Sicherheitsfixes. Der Wechsel Bookworm → Trixie ist damit kein Komfortthema, sondern ein
Sicherheitsthema – und läuft laut `os-and-software.md` über eine Neuinstallation.

---

## Display und Bildschirmabschaltung

| Modell | Maximum |
|--------|---------|
| **Pi 5, 500, 500+, CM5** | **2× 4K bei 60 Hz – ohne zusätzliche Konfiguration** |
| Pi 4B, 400, CM4 | 2× 4K bei 30 Hz **oder** 1× 4K bei 60 Hz mit `hdmi_enable_4kp60=1` in `config.txt` |
| Zero-Familie | 1 Display, meist bis 1920 × 1080 |

Kabel **vor** dem Einschalten anstecken – Raspberry Pi OS wählt dann die höchste
gemeinsam unterstützte Auflösung und Bildrate.

**Ohne Desktop** (Konsolenmodus) wird die Auflösung über den Kernel gesetzt, per
`video=`-Parameter in `cmdline.txt`.

> ⚠️ **Bookworm war die letzte Version mit `raindrop` und `arandr`.** Anleitungen, die
> diese Werkzeuge nennen, greifen unter Trixie ins Leere.

**Bildschirmabschaltung** ist per Voreinstellung nach **10 Minuten** Inaktivität aktiv –
für Info-Displays, Kiosk-Aufbauten und Statusanzeigen abschalten (Control Centre →
*Display*, oder `raspi-config` → *Display Options*).

---

## Boot-Dateien im Überblick

Die Boot-Partition ist FAT-formatiert und unter Linux als `/boot/firmware/` eingehängt.

| Datei | Zweck |
|-------|-------|
| `config.txt` | Firmware-Konfiguration – **Pi 5: darf nicht leer sein** |
| `cmdline.txt` | Kernel-Kommandozeile (eine Zeile!) |
| `autoboot.txt` | Optional: aus welcher Partition gebootet wird – Grundlage des A/B-Boots (max. 512 Bytes, siehe `config-txt.md`) |
| `boot.img` / `tryboot.img` | Optional: Boot-Dateisystem als RAM-Disk (max. 96 MB) |
| `bootcode.bin` | Bootloader – **entfällt bei Pi 4 und Pi 5** (im EEPROM) |
| `start*.elf` / `fixup*.dat` | VideoCore-Firmware – **entfällt beim Pi 5** (im EEPROM) |
| `*.dtb` | Device-Tree-Blobs je Modell |
| `overlays/` | Overlays plus **`README`** mit allen Parametern |
| `initramfs*` | Initiale RAM-Disk; unter Trixie ist `auto_initramfs` voreingestellt |
| `ssh` bzw. `ssh.txt` | Leere Datei genügt – aktiviert SSH beim Booten |
| `issue.txt` | Datum und Git-Commit der Distribution |

### Kernel-Images

| Datei | Prozessor | Modelle |
|-------|-----------|---------|
| `kernel8.img` | BCM2837/2711/2712 | 64-Bit-Kernel für alles ab Pi 2 (spätere Revisionen) |
| **`kernel_2712.img`** | **BCM2712** | **Pi 5, CM5, Pi 500, 500+ – für den Pi 5 optimiert** |
| `kernel7l.img` | BCM2711 | Pi 4, CM4, CM4S, Pi 400 (32 Bit, LPAE) |
| `kernel7.img` | BCM2836/2837 | Zero 2 W, Pi 2/3, CM3 (32 Bit) |
| `kernel.img` | BCM2835 | Pi Zero, Pi 1, CM1 |

> ⚠️ **`lscpu` meldet auf einem 32-Bit-Kernel `armv7l`, auf einem 64-Bit-Kernel
> `aarch64`.** Das `l` in `armv7l` steht für **Little Endian**, nicht für LPAE – anders als
> das `l` im Dateinamen `kernel7l.img`. Für die Prüfung «läuft hier wirklich 64 Bit?» (bei
> Edge AI zwingend) ist `aarch64` das Kriterium.

---

## Weitere Ressourcen

- `config-txt.md` – Dateiformat, bedingte Filter, A/B-Boot, Watchdog, Übertakten
- `remote-access.md` – SSH-Schlüssel, VNC, Dateifreigaben, Netzwerk-Boot
- [Configuration](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [config.txt](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [Device Trees, Overlays und Parameter](https://www.raspberrypi.com/documentation/computers/configuration.html#device-trees-overlays-and-parameters)
- `/boot/firmware/overlays/README` – auf dem Gerät, passend zur installierten Firmware
- [rpi-eeprom](https://github.com/raspberrypi/rpi-eeprom) – Bootloader-Images und Skripte
- [Raspberry Pi Linux Kernel](https://github.com/raspberrypi/linux) – Quelltexte der Overlays
