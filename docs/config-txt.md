# config.txt – Firmware-Konfiguration im Detail

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «config.txt»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/config_txt.html)).

`configuration.md` beantwortet **«wo stelle ich das ein?»**. Diese Referenz beantwortet
**«was kann in `config.txt` stehen und warum wirkt meine Zeile nicht?»** – das Dateiformat
mit seinen stillen Grenzen, bedingte Filter, Boot-Optionen, A/B-Boot, Watchdog,
GPIO-Startzustände und Übertaktung.

> **Merksatz vorweg:** `config.txt` wird von der **GPU gelesen, bevor die Arm-CPU und Linux
> starten**. Deshalb gibt es hier keine Fehlermeldungen im gewohnten Sinn – kein `dmesg`,
> kein Exit-Code. Eine falsche Zeile ist meist einfach wirkungslos. Das prägt jede
> Fehlersuche in dieser Datei.

## Inhaltsverzeichnis
1. [Dateiformat und stille Grenzen](#dateiformat-und-stille-grenzen)
2. [Bedingte Filter](#bedingte-filter)
3. [Boot-Optionen: Kernel, initramfs, Präfixe](#boot-optionen-kernel-initramfs-präfixe)
4. [A/B-Boot mit autoboot.txt und tryboot](#ab-boot-mit-autoboottxt-und-tryboot)
5. [Watchdog – Selbstheilung im Feld](#watchdog--selbstheilung-im-feld)
6. [GPIO-Zustände beim Booten](#gpio-zustände-beim-booten)
7. [Übertakten, Spannung und Temperatur](#übertakten-spannung-und-temperatur)
8. [Speicher](#speicher)
9. [Kamera und Display](#kamera-und-display)
10. [Video- und Audio-Ausgabe](#video--und-audio-ausgabe)
11. [Bootzeit und Boot-Diagnose](#bootzeit-und-boot-diagnose)
12. [EEPROM-Schreibschutz und Secure Boot](#eeprom-schreibschutz-und-secure-boot)
13. [Werte prüfen](#werte-prüfen)

---

## Dateiformat und stille Grenzen

Ein `property=value` pro Zeile, Wert ganzzahlig oder Zeichenkette. Kommentare beginnen mit
`#`. Änderungen wirken **erst nach einem Neustart**.

```ini
# Audio aktivieren (lädt snd_bcm2835)
dtparam=audio=on
# Overlays für erkannte Kameras automatisch laden
camera_auto_detect=1
# DRM-VC4-V3D-Treiber
dtoverlay=vc4-kms-v3d
```

### 🔴 Die 98-Zeichen-Grenze

> **Eine Zeile darf maximal 98 Zeichen lang sein. Alles darüber verwirft Raspberry Pi OS –
> ohne Warnung.**

Das trifft genau die Zeilen, die von Natur aus lang werden: ein Overlay mit mehreren
angehängten Parametern.

```ini
# Grenzwertig – bei weiteren Parametern wird stillschweigend abgeschnitten:
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25,spimaxfrequency=2000000
```

➜ **Praxisregel:** Sobald eine `dtoverlay=`-Zeile länger als etwa 80 Zeichen wird, die
Parameter auf mehrere `dtparam=`-Zeilen **unterhalb** des Overlays verteilen (der
Geltungsbereich läuft bis zum nächsten `dtoverlay=`, siehe `configuration.md`). Das ist
kürzer, lesbarer – und man verliert nicht die Hälfte der Konfiguration an eine
Zeichenzahl.

> ⚠️ **Die Quelle widerspricht sich bei der Zahl.** Der Abschnitt zum Dateiformat nennt
> **98 Zeichen**, der Hinweis zu mehreren `ramfsfile`-Einträgen spricht von einer
> **80-Zeichen**-Grenze. Wer sich an 80 hält, ist in beiden Fällen sicher.

### `include` – und was es nicht kann

```ini
include extraconfig.txt
```

Fügt den Inhalt der genannten Datei an dieser Stelle ein. Praktisch, um projektspezifische
Blöcke von der Grundkonfiguration zu trennen.

> 🔴 **Zwei harte Einschränkungen:**
> 1. **`bootcode.bin` und der EEPROM-Bootloader kennen `include` nicht.**
> 2. Einstellungen, die **der Bootloader** auswertet, wirken **nur direkt in `config.txt`** –
>    in einer eingebundenen Datei sind sie wirkungslos:
>    `bootcode_delay`, `gpu_mem` (auch `gpu_mem_256/512/1024`), `total_mem`, `sdram_freq`,
>    `start_x`, `start_debug`, `start_file`, `fixup_file`, `uart_2ndstage`.

➜ Das ist eine unangenehme Fehlerklasse: Die Konfiguration sieht aufgeräumt aus, ein Teil
davon tut aber nichts. **Bootloader-Einstellungen gehören in die Hauptdatei**, alles
Übrige darf ausgelagert werden.

---

## Bedingte Filter

Filter machen **eine** Konfigurationsdatei für **mehrere** Geräte tauglich – der Normalfall
bei Klassensätzen und geklonten Karten.

```ini
[pi4]
# gilt nur auf Pi 4B, 400, CM4, CM4S
[pi5]
# gilt nur auf Pi 5, 500, 500+, CM5
[all]
# gilt wieder überall
```

### 🔴 Filter wirken bis zum nächsten Filter

Ein Filter ist kein Block mit Klammern – er ist ein **Schalter**, der so lange gilt, bis der
nächste Filter kommt. Wer nach einem `[pi5]`-Abschnitt weiterschreibt, ohne `[all]` zu
setzen, konfiguriert versehentlich nur den Pi 5.

```ini
[pi5]
dtparam=pciex1_gen=3

# FEHLER: gilt ebenfalls nur auf dem Pi 5
dtparam=i2c_arm=on
```

➜ **Jede Filtergruppe mit `[all]` abschliessen.** Das ist die häufigste Ursache für
«dieselbe Karte, anderes Verhalten».

### Modellfilter und ihre Vererbung

| Filter | Modelle |
|--------|---------|
| `[pi1]` | 1A, 1B, 1A+, 1B+, CM1 |
| `[pi2]` | 2B |
| `[pi3]` | 3B, 3B+, 3A+, CM3, CM3+ |
| `[pi3+]` | 3A+, 3B+ – **sieht zusätzlich `[pi3]`** |
| `[pi4]` | 4B, 400, CM4, CM4S |
| **`[pi5]`** | **5, 500, 500+, CM5** |
| `[pi400]` | 400 – sieht zusätzlich `[pi4]` |
| `[pi500]` | 500, 500+ – sieht zusätzlich `[pi5]` |
| `[cm3]` / `[cm3+]` / `[cm4]` / `[cm4s]` / `[cm5]` | Compute Modules; sehen jeweils den Filter der Basisplattform |
| `[pi0]` | Zero, Zero W, Zero 2 W |
| `[pi0w]` | Zero W – sieht zusätzlich `[pi0]` |
| `[pi02]` | Zero 2 W – sieht zusätzlich `[pi0w]` und `[pi0]` |
| `[board-type=0x14]` | Genau ein Typ laut Revisionscode (hier: CM4) |

> ⚠️ **`[pi5]` trifft auch CM5, 500 und 500+.** Wer wirklich nur das eine Board meint, hat
> zwei Wege:
> 1. Im Basisfilter setzen und in den abgeleiteten Filtern (`[pi500]`, `[cm5]`) wieder
>    zurücknehmen, oder
> 2. **`[board-type=…]`** mit dem Revisionscode verwenden – der saubere Weg.

### Weitere Filtertypen

| Filter | Bedeutung |
|--------|-----------|
| `[none]` | Sperrt alles Folgende für jede Hardware – bequemer als jede Zeile auszukommentieren |
| `[0x12345678]` | **Seriennummer** – die **letzten acht** Hex-Ziffern aus `cat /proc/cpuinfo` |
| `[EDID=DEL-DELL_U2422H]` | Angeschlossener Monitor (`<Hersteller>-<Produktname>`, Leerzeichen → `_`) |
| `[gpio4=1]` | Zustand eines GPIO-Pins beim Booten |
| `[tryboot]` | Es wurde mit gesetztem Tryboot-Flag gestartet |
| `[partition=N]` | Angeforderte Partitionsnummer (`sudo reboot N`) |
| `[boot_partition=N]` | Partition, aus der `config.txt` tatsächlich geladen wurde |

> ⚠️ **Der `[EDID=…]`-Filter existiert auf dem Pi 5 nicht.** Ausserdem greift er nur beim
> Booten: Ein nachträglich angestecktes Display wählt keine andere Konfiguration.

**EDID-Namen ermitteln:**

```bash
ls -1 /sys/class/drm/card?-HDMI-A-?/edid
edid-decode /sys/class/drm/card1-HDMI-A-1/edid   # Manufacturer + Display Product Name
```

**Der GPIO-Filter** ist der einfachste Hardware-Schalter, den ein Pi haben kann: ein
Jumper oder DIP-Schalter am Header entscheidet, welche Konfiguration gilt – ohne Software,
ohne Netzwerk.

```ini
[gpio4=1]
cmdline=cmdline-service.txt     # Jumper gesteckt: Wartungsmodus
[all]
```

### Filter kombinieren

Filter **desselben** Typs ersetzen einander (`[pi2]` hebt `[pi1]` auf – beides kann nicht
gleichzeitig gelten). Filter **verschiedener** Typen werden **kombiniert**:

```ini
[EDID=VSC-TD2220]
# nur mit diesem Monitor
[pi2]
# nur mit diesem Monitor UND auf einem Pi 2
[all]
# wieder überall
```

### Ausdrucksfilter – Boot-Variablen vergleichen

Gedacht für Over-the-Air-Updates, Test und Diagnose. Vergleichsformen:

```ini
[ARG=VALUE]        # gleich
[ARG&MASK]         # (ARG & MASK) != 0
[ARG&MASK=VALUE]   # (ARG & MASK) == VALUE
[ARG<VALUE]        # kleiner
[ARG>VALUE]        # grösser
```

Boot-Variablen (immer **klein** geschrieben, keine Verschachtelung, `[all]` setzt zurück):

| Variable | Modelle | Herkunft |
|----------|---------|----------|
| `boot_arg1` | Pi 5+ | 32-Bit-Wert in einem reset-sicheren Register – überlebt den Reboot |
| `boot_count` | Pi 5+ | 8-Bit-Zähler, wird bei jedem Boot erhöht, bei 256 wieder 0, **beim Trennen der Stromversorgung gelöscht** |
| `bootvar0` | Pi 4+ | Persistent in der EEPROM-Konfiguration (`BOOTVAR0=42` via `rpi-eeprom-config`) |
| `cust_otpN` | – | Die acht Kunden-OTP-Zeilen (`N` = 0–7), **einmal programmierbar** |
| `boot_partition` | – | Partition, aus der `config.txt` geladen wurde |
| `partition` | – | Angeforderte Partitionsnummer |

```bash
# boot_arg1 setzen bzw. lesen, ohne config.txt anzufassen
sudo vcmailbox 0x0003808c 8 8 1 42     # setzen (wirkt beim nächsten Boot)
sudo vcmailbox 0x0003008c 8 8 1 0      # lesen
cat /proc/device-tree/chosen/bootloader/arg1   # Wert beim Start des OS
```

➜ **`boot_count` ist die Zutat für einen Rückfallpfad**: Ein Gerät, das dreimal
hintereinander neu gestartet ist, kann per `[boot_count>3]` automatisch in eine
Wartungskonfiguration wechseln. Weil der Zähler beim Trennen der Stromversorgung gelöscht
wird, zählt er **Reboots**, nicht Einschaltvorgänge – für ein Feldgerät, das nach einem
Absturz von selbst wieder hochkommt, ist genau das die richtige Grösse.

➜ **`bootvar0` erlaubt ein identisches Image für unterschiedliche Rollen.** Die Rolle steht
im EEPROM des jeweiligen Geräts, nicht auf der Karte – Karten bleiben tauschbar.

---

## Boot-Optionen: Kernel, initramfs, Präfixe

| Eigenschaft | Bedeutung |
|-------------|-----------|
| `kernel=` | Alternativer Kernel-Dateiname in der Boot-Partition |
| `cmdline=` | **Alternative `cmdline.txt`** – in Kombination mit Filtern das wichtigste Werkzeug für mehrere Konfigurationen auf einer Karte |
| `arm_64bit=` | `1` = 64-Bit-Kernel, `0` = 32 Bit |
| `initramfs <datei> <adresse>` | RAM-Disk laden – **ohne `=`**, abweichend von allen anderen Optionen |
| `auto_initramfs=1` | Passende initramfs automatisch finden (`kernel8.img` → `initramfs8`) |
| `os_prefix=` | Präfix vor allen OS-Dateien (Kernel, initramfs, `cmdline.txt`, DTBs, Overlays) |
| `overlay_prefix=` | Unterverzeichnis für Overlays, Standard `overlays/` |
| `armstub=` | Arm-Stub, der vor dem Kernel läuft |

**Standard-Kernel je Modell:**

| Modelle | Kernel |
|---------|--------|
| **Pi 5, 500, 500+, CM5** | **`kernel_2712.img`** – enthält Pi-5-Optimierungen (u.a. 16K Page Size); fehlt sie, wird `kernel8.img` genommen |
| Pi 4, 400, CM4 | `kernel8.img` (bzw. `kernel7l.img` bei `arm_64bit=0`) |
| Pi 2/3, Zero 2 W, CM3/3+ | `kernel7.img` |
| Pi 1, Zero, CM1 | `kernel.img` |

> ⚠️ **Modelle ab Pi 5 (sowie CM5 und Pi 500) unterstützen ausschliesslich 64-Bit-Kernel** –
> `arm_64bit` wird dort ignoriert. Bei Pi 4/400/CM4 ist `1` die Voreinstellung, auf allen
> älteren Modellen `0`.

> ℹ️ 64-Bit-Kernel dürfen unkomprimiert **oder gzip-gepackt** vorliegen; beide tragen oft
> die Endung `.img`. Der Bootloader erkennt das Archiv an den Signaturbytes.

**`os_prefix` – zwei Kernel-Stände parallel:** Das Präfix wird auf **Viabilität** geprüft.
Lassen sich Kernel und DTB darunter nicht finden, wird es stillschweigend ignoriert
(auf `""` gesetzt) – ein eingebautes Netz gegen ein unbootbares System. Für Overlays gilt
zusätzlich: Sie werden nur dann aus `${os_prefix}${overlay_prefix}` geladen, wenn dort eine
Datei `README` liegt; sonst gelten die Overlays als gemeinsam genutzt.

Ein absoluter Pfad umgeht **alle** Präfixe: `kernel=/my_common_kernel.img`.

> ⚠️ **Auf dem Pi 5 prüft die Firmware vor dem Booten, ob ein kompatibler Device Tree
> vorliegt** (`os_check=1`, Voreinstellung). Ohne diese Prüfung würden ältere,
> inkompatible Kernel geladen – und dann hängen. Nur für Bare-Metal-Entwicklung auf `0`
> setzen.

---

## A/B-Boot mit autoboot.txt und tryboot

Der offizielle Weg zu **ausfallsicheren OS-Updates** auf einem Gerät, das man nach dem
Update nicht besuchen kann. Für Feldgeräte, Ausstellungsaufbauten und Klassensätze die
relevanteste Funktion dieser ganzen Referenz.

**Bausteine:**

- `autoboot.txt` in der Boot-Partition, **max. 512 Bytes**, kennt nur `[all]`, `[none]`
  und `[tryboot]`.
- `boot_partition=N` – aus welcher Partition gebootet wird. `0` = erste bootfähige
  FAT-Partition. MBR-Partitionen sind 1–4.
- **Bootfähig** heisst: FAT12/16/32 **und** eine `start.elf` – auf dem **Pi 5** genügt eine
  `config.txt`.
- `sudo reboot "0 tryboot"` – einmaliger Startversuch; das Flag **löscht sich selbst**.
- `tryboot_a_b=1` – schaltet auf **Partitionsebene** statt auf Dateiebene um: Es werden die
  normalen `config.txt`/`boot.img` geladen statt `tryboot.txt`/`tryboot.img`. Damit müssen
  die Dateien in den A/B-Partitionen nicht angefasst werden.

```ini
# autoboot.txt – A läuft, B ist die Update-Partition
[all]
tryboot_a_b=1
boot_partition=2

[tryboot]
boot_partition=3
```

**Ablauf eines abgesicherten Updates:**

1. System läuft aus Partition 2.
2. Update-Dienst schreibt die neue Version nach Partition 3.
3. `sudo reboot "0 tryboot"` – der `[tryboot]`-Filter greift, das Gerät startet aus 3.
4. Das neue System prüft sich selbst:
   - `/proc/device-tree/chosen/bootloader/tryboot` ist `1`
   - `/proc/device-tree/chosen/bootloader/partition` ist die erwartete Partition
5. **Erfolg:** `autoboot.txt` wird getauscht (2 ↔ 3), Partition 3 ist ab jetzt der Standard.
   **Misserfolg oder Absturz:** Ein normaler Reboot landet wieder auf Partition 2 – das
   Tryboot-Flag ist bereits gelöscht.

> ➜ **Der entscheidende Punkt:** Ein Gerät, das im Tryboot-Zustand gar nicht mehr hochkommt,
> braucht **keinen** Eingriff. Es fällt beim nächsten Stromzyklus von selbst auf die alte,
> funktionierende Partition zurück. Genau das unterscheidet A/B-Boot von einem
> `apt full-upgrade` per SSH.

> ⚠️ **Nach dem Tausch von `autoboot.txt` ist die Umschaltung bereits vollzogen**, auch ohne
> Reboot. Ein Update-Dienst darf danach nicht mehr in die «aktuelle» Partition schreiben –
> er würde die gerade freigegebene Version überschreiben.

**Passende Root-Dateisysteme wählen:**

```ini
# config.txt in beiden Partitionen identisch
[boot_partition=1]
cmdline=cmdline_rootfs_a.txt
[boot_partition=2]
cmdline=cmdline_rootfs_b.txt
[all]
```

**Verwandt:** `boot_ramdisk=1` lädt ein `boot.img` (bzw. `tryboot.img`) als
RAM-Dateisystem, aus dem anschliessend gelesen wird – **maximal 96 MB**, Format: eine
schlichte FAT32-Partition ohne MBR. Der Speicher wird vor dem Start des OS wieder
freigegeben. Primär für Secure Boot gedacht, aber auch bei Netzwerk- und RPIBOOT-Aufbauten
nützlich.

---

## Watchdog – Selbstheilung im Feld

```ini
kernel_watchdog_timeout=30      # Sekunden; 0 = aus (Voreinstellung)
kernel_watchdog_partition=3     # optional: nach dem Auslösen von hier booten
```

Die Firmware übergibt einen Hardware-Watchdog an das Betriebssystem. Bedient das OS ihn
nicht regelmässig, startet das Gerät neu.

> 🔴 **Ohne zweiten Schritt ist der Watchdog wirkungslos.** `kernel_watchdog_timeout` setzt
> den systemd-Parameter `watchdog.open_timeout` – also nur die Frist, bis systemd die
> Bedienung übernimmt. Für den **laufenden** Betrieb muss zusätzlich `RuntimeWatchdogSec`
> in `/etc/systemd/system.conf` gesetzt sein. **Unter Raspberry Pi OS Bookworm ist dieser
> Parameter nicht voreingestellt.**

```bash
sudo nano /etc/systemd/system.conf
#   RuntimeWatchdogSec=15
sudo systemctl daemon-reexec
```

➜ **`kernel_watchdog_timeout` ist `dtparam=watchdog` vorzuziehen**, weil nur diese Variante
`open_timeout` explizit setzt und damit die Lücke zwischen Firmware und systemd schliesst.

**Lückenlose Abdeckung vom Einschalten bis zum Betrieb:** Ist zusätzlich
`BOOT_WATCHDOG_TIMEOUT` in der EEPROM-Konfiguration gesetzt (Pi 4 und Pi 5), übergibt der
Bootloader beim Start des OS nahtlos an den Kernel-Watchdog. Ein Gerät, das schon im
Bootloader hängt, ist damit ebenfalls abgedeckt.

**`kernel_watchdog_partition`** in Verbindung mit einem Ausdrucksfilter ergibt einen
automatischen Rückfall auf eine Wiederherstellungspartition, wenn das Hauptsystem hängt –
die konsequente Fortsetzung des A/B-Gedankens.

---

## GPIO-Zustände beim Booten

```ini
gpio=12=op,dh          # GPIO 12 als Ausgang, high
gpio=17-21=ip          # 17 bis 21 als Eingang
gpio=18,20=pu          # Pull-up an 18 und 20
gpio=0-27=a2           # Alt2 für DPI24
```

| Kürzel | Bedeutung |
|--------|-----------|
| `ip` / `op` | Eingang / Ausgang |
| `a0`–`a5` | Alternativfunktion 0–5 |
| `dh` / `dl` | Ausgang treibt high / low |
| `pu` / `pd` / `pn` (`np`) | Pull-up / Pull-down / kein Pull |

Angaben gelten als Einzelpin (`3`), Bereich (`3-4`) oder Liste (`3-4,6,8`). **Spätere
Zeilen überschreiben frühere.** Bedingte Filter gelten auch hier – Startzustände lassen
sich also je Modell oder Seriennummer unterscheiden.

> 🔴 **Zwei Einschränkungen, die man kennen muss:**
> 1. **Es dauert einige Sekunden**, bis die Einstellungen greifen – beim Booten über
>    Netzwerk oder USB-Massenspeicher länger. In dieser Zeit sind die Pins in ihrem
>    Reset-Zustand.
> 2. `gpio=` hat **keine direkte Wirkung auf den Kernel**: Die Pins erscheinen nicht in
>    sysfs, und `pinctrl`-Einträge im Device Tree oder das Werkzeug `pinctrl` können die
>    Einstellung wieder überschreiben.

➜ **Konsequenz für Aktoren:** `gpio=` verkürzt das Zeitfenster, in dem ein Ausgang
undefiniert ist – es beseitigt es **nicht**. Ein Relais, ein Motortreiber oder ein
Heizelement, das beim Einschalten nicht anziehen darf, braucht einen **externen
Pull-Widerstand am Treibereingang**. Die Zeile in `config.txt` ist die zweite
Verteidigungslinie, nicht die erste.

**JTAG:** `enable_jtag_gpio=1` legt GPIO 22–27 auf Alt4 und schaltet die
Arm-JTAG-Schnittstelle frei (alle Modelle).

| Pin | Funktion |
|-----|----------|
| GPIO22 | ARM_TRST |
| GPIO23 | ARM_RTCK |
| GPIO24 | ARM_TDO |
| GPIO25 | ARM_TCK |
| GPIO26 | ARM_TDI |
| GPIO27 | ARM_TMS |

➜ Diese sechs Pins stehen dann für nichts anderes zur Verfügung – bei der Pinplanung
berücksichtigen.

---

## Übertakten, Spannung und Temperatur

> ⚠️ **Warnhinweis der Dokumentation:** Werte ausserhalb dessen, was `raspi-config`
> anbietet, können ein **dauerhaftes Bit im SoC** setzen. Es wird gesetzt, sobald
> `force_turbo=1` **und** eine `over_voltage_*`-Einstellung > 0 aktiv ist, und ist danach
> auslesbar. Übertaktung und Überspannung werden ausserdem automatisch abgeschaltet, wenn
> `temp_limit` erreicht oder eine Unterspannung erkannt wird.

### Die wichtigsten Optionen

| Option | Bedeutung |
|--------|-----------|
| `arm_freq` | Arm-Takt in MHz |
| `arm_boost=1` | Höchste vom Board unterstützte Frequenz (Pi 4B ab R1.4, Pi 400) |
| `core_freq` | GPU-Kern – treibt L2-Cache und Speicherbus mit |
| `v3d_freq`, `isp_freq`, `hevc_freq`, `h264_freq` | Einzelblöcke; `gpu_freq` setzt sie gemeinsam |
| `over_voltage_delta` | **Pi 4 und Pi 5:** Offset in **Mikrovolt** auf den vom DVFS-Algorithmus errechneten Wert |
| `over_voltage` | Ältere Modelle: Bereich `[-16,8]` in 0,025-V-Schritten |
| `force_turbo=1` | Maximale Frequenzen auch im Leerlauf |
| `initial_turbo` | Turbo ab dem Boot für N Sekunden, **max. 60** |
| `core_freq_fixed=1` | **Skalierung des Kerntakts abschalten** |
| `temp_limit` | Schutzabschaltung der Übertaktung, Standard **85 °C**, Werte darüber werden auf 85 gekappt |
| `temp_soft_limit` | **Nur 3A+/3B+:** ab hier 1400 → 1200 MHz, Standard 60 °C, max. 70 |

**Voreinstellungen Pi 5 / 500 / 500+** (MHz):

| Wert | Standard | Minimum |
|------|----------|---------|
| `arm_freq` | **2400** | 1500 |
| `core_freq` | 910 | 500 |
| `isp_freq` | 910 | 500 |
| `v3d_freq` | **960** | 500 |
| `hevc_freq` | 910 | – |
| `sdram_freq` | 4267 | 4267 |

Zum Vergleich Pi 4B: `arm_freq` 1500 (1800 mit `arm_boost=1`), `core_freq` 500,
`sdram_freq` 3200.

> ⚠️ **SDRAM lässt sich ab Pi 4 nicht übertakten.** Auf dem Pi 5 ist ausserdem `v3d_freq`
> unabhängig von `core_freq`, `isp_freq` und `hevc_freq` – die Blöcke teilen sich dort
> keine PLL mehr.

> ⚠️ **Die Quelle widerspricht sich bei `initial_turbo`.** Die Tabelle nennt als Standard
> `0`, der Fliesstext beschreibt, dass das Firmware-Update von **November 2024** den
> Standard auf **60** gesetzt hat (zusammen mit dem Wechsel des CPU-Governors von
> `powersave` auf `ondemand`). Auf einem aktuellen System ist von `60` auszugehen; im
> Zweifel `vcgencmd get_config initial_turbo` fragen.

### 🔴 `core_freq_fixed` – der unterschätzte Schalter

Der Kerntakt treibt auf den Modellen bis einschliesslich Pi 4 auch **Peripherie**. Skaliert
er dynamisch mit der Last, verschieben sich abgeleitete Takte – was sich als sporadische
Übertragungsfehler an UART oder SPI zeigt, die scheinbar von der CPU-Auslastung abhängen.

```ini
core_freq_fixed=1
```

➜ **Bei unerklärlichen seriellen Fehlern, die unter Last auftreten und im Leerlauf nicht:
zuerst hier ansetzen**, bevor Baudraten oder Kabel getauscht werden. `core_freq_fixed` ist
einer festen `core_freq`-Zahl vorzuziehen – die Konfiguration bleibt so über Modelle hinweg
übertragbar.

### Automatische Spannungsregelung nicht versehentlich abschalten

> 🔴 Die Firmware skaliert die Spannung beim Übertakten **selbstständig** hoch.
> **Ein manuell gesetztes `over_voltage` schaltet genau diese Automatik ab.** Wer «zur
> Sicherheit» einen Wert einträgt, bekommt unter Umständen **weniger** Spannung als das
> System sich selbst gegeben hätte – und ein instabiles Gerät.

Auf Pi 4 und Pi 5 ist `over_voltage_delta` der richtige Griff: Es **ergänzt** den
berechneten Wert, statt ihn zu ersetzen.

Beim Übertakten die Blöcke **einzeln** setzen (`isp_freq`, `v3d_freq`, …) statt gemeinsam
über `gpu_freq` – die maximal stabile Frequenz ist je Block unterschiedlich.

### Temperatur und Drosselung

| Bereich | Verhalten |
|---------|-----------|
| 80–85 °C | Arm-Kerne werden gedrosselt |
| > 85 °C | Arm-Kerne **und** GPU werden gedrosselt |

```bash
cat /sys/class/thermal/thermal_zone0/temp   # in Milligrad
vcgencmd measure_temp                       # GPU-Temperatur
```

Das Erreichen der Grenze schadet dem SoC **nicht** – es kostet Leistung. Ein Kühlkörper mit
Luftstrom verschiebt den Punkt, an dem gedrosselt wird.

### Spannungsversorgung messen

| Schwelle | Bedeutung |
|----------|-----------|
| **> 4,8 V** | Notwendig für zuverlässigen Betrieb |
| **< 4,63 V** (±5 %) | Arm und GPU werden gedrosselt, Meldung landet im Kernel-Log |

```bash
vcgencmd pmic_read_adc EXT5V_V   # Pi 5: Versorgungsspannung aus dem PMIC-ADC
```

➜ **Auf dem Pi 5 ist kein Multimeter mehr nötig.** Der PMIC hat eingebaute ADCs; die
Versorgungsspannung ist direkt auslesbar. Auf älteren Modellen bleibt nur die Messung
zwischen VCC und GND am Header.

> ⚠️ Viele USB-Netzteile sind für das Laden eines 3,7-V-LiPo ausgelegt, nicht für die
> Versorgung eines Rechners – ihre Ausgangsspannung fällt unter Last bis auf **4,2 V**. Das
> ist die häufigste Ursache für den «Lightning Bolt».

### Tatsächlicher Takt ≠ angeforderter Takt

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq   # kHz – vom Kernel ANGEFORDERT
vcgencmd measure_clock arm                                  # Hz  – TATSÄCHLICH anliegend
```

> ➜ **Das ist ein echter Diagnosefehler-Kandidat.** `scaling_cur_freq` meldet, was der
> Kernel *möchte*. Eine thermische Drosselung oder eine Unterspannung senkt den echten
> Takt, ohne dass sich dieser Wert ändert. Wer «die CPU läuft doch auf 2,4 GHz» aus
> `scaling_cur_freq` abliest, hat die Drosselung nicht gesehen. Für die Wahrheit:
> `vcgencmd measure_clock arm` – und `vcgencmd get_throttled`.

### Spannungs- und Frequenzskalierung (DVFS)

Der Pi 4 senkt nicht nur den Takt, sondern auch die Spannung einzelner SoC-Blöcke, sobald
diese nicht auf Vollgas laufen (Arm, Core, V3D, ISP, H264, HEVC). Das drückt Verbrauch und
Abwärme spürbar. Steuerbar über `/boot/firmware/config.txt`:

| Wert | Verhalten |
|------|-----------|
| `dvfs=1` | Unterspannung erlaubt – sparsamster Modus |
| `dvfs=2` | Feste Spannung für die Standardfrequenzen |
| `dvfs=3` | Spannung bei Bedarf anheben (**Voreinstellung**) |

⚠️ **`dvfs=1` kann PCIe destabilisieren**, weil fest getaktete Peripherie mit
unterspannt wird. Nur auf Headless-Systemen ohne PCIe sinnvoll. Wird `over_voltage` in der
`config.txt` gesetzt, schaltet das System automatisch auf `dvfs=2` zurück.

> Auf dem **Pi 5 gibt es diese Einstellung nicht mehr** – dort ist das Verhalten von
> `dvfs=3` fest eingebaut.

Der Frequenz-Governor läuft standardmässig auf `ondemand` und kennt am Pi 4 die Stufen
1500 / 1000 / 750 / 600 MHz. Für dauerhaft niedrigen Leerlaufverbrauch:

```bash
sudo apt install cpufrequtils
sudo cpufreq-set -g powersave
```

### Wenn das Gerät nach dem Übertakten nicht mehr bootet

1. **Alle** Frequenz-Overrides aus `config.txt` entfernen (Karte in einem anderen Rechner
   bearbeiten – die Boot-Partition ist FAT).
2. Kernspannung über `over_voltage_delta` anheben.
3. Übertaktung schrittweise neu aufbauen, die bekannt schlechten Werte auslassen.

---

## Speicher

```ini
total_mem=1024      # in MB; wird auf [128 … physisch vorhanden] begrenzt
```

Begrenzt den nutzbaren Arbeitsspeicher. Ein 8-GB-Pi verhält sich damit wie ein 1-GB-Modell.

➜ **Zwei sinnvolle Anwendungen:**
1. **Vor der Beschaffung prüfen**, ob ein Modell, eine Pipeline oder ein Klassensatz-Setup
   mit der kleineren RAM-Variante auskommt – auf vorhandener Hardware, ohne sie zu kaufen.
2. **Fehler reproduzieren**, die nur auf den kleinen Varianten auftreten.

> ⚠️ **`total_mem` gehört zu den Bootloader-Einstellungen** und wirkt deshalb nur direkt in
> `config.txt`, nicht in einer per `include` eingebundenen Datei.

> ℹ️ Die physisch verbaute Grösse steht unabhängig davon in
> `/proc/device-tree/chosen/rpi-sdram-size-gbit` (siehe `configuration.md`) – ein
> gesetztes `total_mem` verfälscht diesen Wert nicht.

---

## Kamera und Display

| Option | Wirkung |
|--------|---------|
| `camera_auto_detect=1` | Overlays für erkannte CSI-Kameras automatisch laden – **in Raspberry Pi OS voreingestellt** |
| `display_auto_detect=1` | Dasselbe für erkannte DSI-Displays – ebenfalls voreingestellt |
| `disable_camera_led=1` | Rote Kamera-LED aus |
| `awb_auto_is_greyworld=1` | Weissabgleich nach **Greyworld** – ⚠️ nur alter Kamera-Stack, siehe unten |
| `ignore_lcd=1` | Erkennung des Touch-Displays am I2C-Bus überspringen |
| `disable_touchscreen=1` | Touch-Funktion des offiziellen Displays abschalten |

> 🔴 **`awb_auto_is_greyworld` wirkt auf den heutigen Kamera-Stack nicht.** Die Option
> stammt aus dem Firmware-Pfad des Legacy-Stacks. Die Dokumentation der Kamera-Software
> hält ausdrücklich fest, dass **`rpicam-apps` den automatischen Weissabgleich nicht in den
> Greyworld-Modus versetzen kann**.
>
> Für NoIR-Kameras – und HQ-Kameras mit ausgebautem IR-Filter – ist der richtige Weg eine
> **NoIR-Tuning-Datei**:
>
> ```bash
> rpicam-hello --tuning-file /usr/share/libcamera/ipa/rpi/pisp/imx219_noir.json   # ab Pi 5
> rpicam-hello --tuning-file /usr/share/libcamera/ipa/rpi/vc4/imx219_noir.json    # Pi 4 und älter
> ```
>
> Details in `camera.md`.

➜ **`disable_camera_led=1`** ist kein Kosmetikpunkt: Bei einer Kamera hinter Glas oder in
einem Gehäuse spiegelt sich die LED im Bild und stört jede nachgelagerte Erkennung.

---

## Video- und Audio-Ausgabe

### 🔴 DMT-Modus 81 – warum ein 1366×768-Monitor auf 1280×720 landet

Pi 4B, CM4, CM4S und Pi 400 erzeugen **zwei Bildpunkte pro Taktzyklus**. Timings mit
ungeraden horizontalen Werten sind damit unmöglich; Firmware und Kernel filtern solche
Modi heraus.

Betroffen ist **genau ein** Modus aus den CEA- und DMT-Standards: **DMT 81, 1366×768 bei
60 Hz** – ungerade Sync- und Back-Porch-Werte, Breite nicht durch 8 teilbar.

➜ Ein solcher Monitor läuft an einem Pi 4 automatisch im nächstbesten angebotenen Modus,
typischerweise **1280×720**. Das ist kein Defekt und keine falsche Einstellung.
**Pi 5 und neuer beherrschen diese Timings direkt** – derselbe Monitor läuft dort korrekt.

| Option | Bedeutung |
|--------|-----------|
| `hdmi_enable_4kp60=1` | **Nur Pi 4B/CM4/CM4S/400:** 4K bei 60 Hz statt 30 Hz, **nur an HDMI0**; hebt `core_freq` auf 550 MHz, erhöht Verbrauch und Temperatur |
| `disable_fw_kms_setup=1` | Firmware übergibt keinen Videomodus – KMS wertet die EDID selbst aus. **Auf dem Pi 5 Voreinstellung** |
| `enable_tvout` | Composite-Ausgang |

> ℹ️ Ab Pi 5 (sowie CM5 und Pi 500) sind **zwei 4K-Displays mit 60 Hz** ohne jede
> Konfiguration möglich; `hdmi_enable_4kp60` wird dort nicht gebraucht.

➜ **`disable_fw_kms_setup=1` ist der Griff bei «die Firmware wählt einen Modus, den mein
Display nicht kann»** – in seltenen Fällen wählt sie einen Modus, der gar nicht in der
EDID steht.

### Composite-Video

| Modell | Anschluss |
|--------|-----------|
| Pi 1 A/B | Cinch-Buchse |
| Zero | unbestückter TV-Header |
| Zero 2 W | Testpads auf der Unterseite |
| **Pi 5** | **Pad J7 neben der HDMI-Buchse** |
| übrige Modelle | 3,5-mm-AV-Buchse |
| Keyboard-Modelle | **kein Composite-Ausgang** |

```ini
enable_tvout=1
dtoverlay=vc4-kms-v3d,composite
```

```
# in cmdline.txt (eine Zeile!), Standard ist NTSC:
vc4.tv_norm=PAL
```

Weitere Werte: `NTSC`, `NTSC-J`, `NTSC-443`, `PAL`, `PAL-M`, `PAL-N`, `PAL60`, `SECAM`.

> 🔴 **Composite und HDMI schliessen einander aus.** Auf Pi 4 und neuer sowie den
> Zero-Modellen schaltet `enable_tvout=1` den HDMI-Ausgang ab. Umgekehrt wird Composite
> automatisch aktiv, wenn kein HDMI-Display erkannt wird – wer das nicht will, setzt
> ausdrücklich `enable_tvout=0`.

### Audio

```ini
dtoverlay=vc4-kms-v3d,noaudio    # HDMI-Audio abschalten
```

| Option | Bedeutung |
|--------|-----------|
| `audio_pwm_mode=2` | **Standard:** hochwertige Analogausgabe – kostet GPU-Rechenzeit und kann bei manchen Anwendungen stören |
| `audio_pwm_mode=1` | Alte, einfache Ausgabe – der Ausweg, wenn Modus 2 stört |
| `disable_audio_dither=1` | Dither abschalten – gegen hörbares Rauschen bei kleiner ALSA-Lautstärke |
| `enable_audio_dither=1` | Dither auch über 16 Bit erzwingen |
| `pwm_sample_bits` | Bittiefe der Analogausgabe, Standard 11; **unter 8 funktioniert die Ausgabe nicht mehr** |

➜ Bei Aufbauten, die GPU-Last erzeugen (Kamera, Video, KMS) und gleichzeitig ein leises
Störgeräusch am Klinkenausgang zeigen, sind `audio_pwm_mode` und `disable_audio_dither` die
beiden Stellschrauben.

---

## Bootzeit und Boot-Diagnose

### Bootzeit verkürzen

| Option | Wirkung |
|--------|---------|
| `disable_poe_fan=1` | Die I2C-Abfrage nach einem PoE-HAT beim Start entfällt – sie findet **auch ohne HAT** statt |
| `force_eeprom_read=0` | Kein Auslesen eines HAT-EEPROMs an ID_SD/ID_SC beim Einschalten |
| `disable_splash=1` | Kein Regenbogen-Startbild |

➜ Zusammen ein spürbarer Gewinn bei Aufbauten, die schnell betriebsbereit sein müssen –
und bei denen ohnehin kein HAT mit EEPROM steckt.

> ⚠️ `force_eeprom_read=0` schaltet die HAT-Erkennung ab. Wer später doch einen HAT mit
> EEPROM einsetzt, wundert sich, warum dessen Overlay nicht mehr automatisch geladen wird.

### Serielle Konsole und Firmware-Protokolle

```ini
enable_uart=1        # Kernel-Konsole auf GPIO 14/15 (Pin 8/10)
uart_2ndstage=1      # Firmware protokolliert zusätzlich über UART
sha256=1             # SHA256 aller geladenen Dateien protokollieren
```

`enable_uart=1` gehört mit `console=serial0,115200` in `cmdline.txt` zusammen. Damit die
Kernel-Meldungen wirklich erscheinen, zusätzlich `quiet` aus `cmdline.txt` entfernen.

> 🔴 **Auf dem Pi 5 zeigt `/dev/serial0` auf den dreipoligen Debug-Header, nicht auf
> GPIO 14/15** (siehe `rp1-gpio.md`). Für eine UART am 40-Pin-Header ist auf dem Pi 5
> zusätzlich `enable_rp1_uart=1` interessant: Die Firmware initialisiert RP1 UART0 auf
> 115200 Bit/s und setzt RP1 vor dem Start des OS **nicht** zurück – so gibt es schon in
> der frühen Boot-Phase Ausgabe am Header. Verwandt: `pciex4_reset=0` behält die
> PCIe-Konfiguration des Bootloaders bei (beides vor allem für Bare-Metal-Arbeit).

> ⚠️ **`sha256=1` kann die Bootzeit um viele Sekunden verlängern.** Als Diagnosewerkzeug
> gedacht – nach der Fehlersuche wieder entfernen. Die Ausgabe geht an die UART und ist
> über `sudo vclog --msg` lesbar.

`uart_2ndstage=1` schaltet die Protokollierung **auch in `start.elf`** ein – im Gegensatz
zur EEPROM-Eigenschaft `BOOT_UART`, die nur den Bootloader betrifft.

---

## EEPROM-Schreibschutz und Secure Boot

```ini
eeprom_write_protect=1     #  1 = ganzes EEPROM schützen, 0 = Schutz löschen, -1 = nichts tun (Standard)
bootloader_update=0        # Selbstaktualisierung des Bootloaders unterbinden
erase_eeprom=1             # nur mit recovery.bin: EEPROM löschen statt beschreiben
```

> ⚠️ **Der Schreibschutz braucht immer zwei Dinge:** die Konfiguration des
> Write-Status-Registers **und** den `/WP`-Pin. Den Pin allein auf Masse zu ziehen (CM4
> `EEPROM_nWP`, Pi 4 TP5) schützt nichts.
>
> **Auf dem Pi 5 liegt `/WP` bereits auf Masse.** Sobald das Status-Register konfiguriert
> ist, ist der Schutz damit aktiv. Zum Aufheben muss `/WP` hochgezogen werden – über eine
> Verbindung von TP14 zu TP1.
>
> `flashrom` kann Schreibschutzbereiche **nicht** löschen und scheitert an einem
> geschützten EEPROM.

➜ **`bootloader_update=0` ist der praktische Punkt für verwaltete Flotten:** Die
Selbstaktualisierung lässt sich pro Gerät unterbinden – in Kombination mit einem
Seriennummernfilter sogar aus einer gemeinsamen `config.txt` heraus.

**Secure Boot** (`program_pubkey`, `revoke_devkey`, `program_rpiboot_gpio`,
`program_jtag_lock`) programmiert **irreversibel** OTP-Speicher und funktioniert nur über
RPIBOOT beim Beschreiben des EEPROM.

> 🔴 **Für dieses Skill nicht relevant und ausdrücklich nicht empfohlen:** Die
> Dokumentation nennt Secure Boot für **Buildroot-basierte** Images gedacht; der Einsatz
> mit Raspberry Pi OS wird **weder empfohlen noch unterstützt**. `program_jtag_lock`
> verhindert zudem jede spätere Fehleranalyse über JTAG.

---

## Werte prüfen

```bash
vcgencmd get_config arm_freq     # einzelne Einstellung
vcgencmd get_config int          # alle ganzzahligen Werte ungleich 0
vcgencmd get_config str          # alle gesetzten Zeichenketten
```

> ⚠️ **Nicht jede Einstellung lässt sich so auslesen.** Wird ein Wert nicht angezeigt,
> heisst das **nicht**, dass er nicht gesetzt ist. Für den Beweis, dass eine Zeile gewirkt
> hat, ist die tatsächliche Wirkung zu prüfen – Taktfrequenz messen, Device-Tree-Knoten
> ansehen, `sudo vclog --msg` lesen.

**Der Diagnoseweg bei einer wirkungslosen Zeile – in dieser Reihenfolge:**

1. Ist die Zeile **länger als 98 Zeichen**? → wird abgeschnitten
2. Steht sie hinter einem **Filter**, der gerade nicht zutrifft? → `[all]` fehlt
3. Steht sie in einer per **`include`** eingebundenen Datei, obwohl sie der Bootloader
   auswertet? → gehört in die Hauptdatei
4. Wurde **neu gestartet**?
5. `sudo vclog --msg` – die Firmware protokolliert **nicht** nach `dmesg`
6. `vcgencmd get_config <name>` – mit dem Vorbehalt oben
7. Bei Overlays: `dtoverlay -l`, `dtdiff` (siehe `configuration.md`)

---

## Weitere Ressourcen

- [config.txt](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [Boot-Ablauf und `autoboot.txt`](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#boot-folder)
- [Raspberry Pi 4 Boot Security (Whitepaper)](https://pip.raspberrypi.com/categories/685-whitepapers-app-notes)
- [rpi-eeprom](https://github.com/raspberrypi/rpi-eeprom) – EEPROM-Konfiguration und `PSU_MAX_CURRENT`
- [usbboot](https://github.com/raspberrypi/usbboot) – RPIBOOT, `boot.img`, Secure-Boot-Tutorial
- `/boot/firmware/overlays/README` – auf dem Gerät, passend zur installierten Firmware
- `kernel.md` – eigene Kernel bauen und über `kernel=` gefahrlos auswählen
