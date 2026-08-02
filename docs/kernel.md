# Der Linux-Kernel – Header, Module, eigene Builds

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «The Linux kernel»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/linux_kernel.html)).

Diese Referenz behandelt die Ebene **unterhalb** von `config.txt` und Device Tree: Woher der
Kernel kommt, wie man Module dagegen übersetzt, und wann ein eigener Kernel gerechtfertigt
ist – meistens nämlich nicht.

## Inhaltsverzeichnis
1. [Zuerst: brauchen Sie das überhaupt?](#zuerst-brauchen-sie-das-überhaupt)
2. [Woher der Kernel kommt](#woher-der-kernel-kommt)
3. [Kernel-Header – der häufigste Fall](#kernel-header--der-häufigste-fall)
4. [Quelltext beschaffen](#quelltext-beschaffen)
5. [Konfiguration je Modell](#konfiguration-je-modell)
6. [Nativ bauen](#nativ-bauen)
7. [Cross-Compilation](#cross-compilation)
8. [Installieren – ohne sich auszusperren](#installieren--ohne-sich-auszusperren)
9. [Kernel konfigurieren mit menuconfig](#kernel-konfigurieren-mit-menuconfig)
10. [Patches anwenden](#patches-anwenden)
11. [PREEMPT_RT – harte Echtzeit für Robotik](#preempt_rt--harte-echtzeit-für-robotik)
12. [Änderungen beitragen](#änderungen-beitragen)

---

## Zuerst: brauchen Sie das überhaupt?

Ein selbst gebauter Kernel ist in diesem Skill die **letzte** Option, nicht die erste. Er
kostet nicht die Bauzeit – er kostet die **Wartung für die gesamte Lebensdauer des
Geräts**: Sicherheitsaktualisierungen kommen ab dann nicht mehr über `apt`, sondern müssen
von Hand nachgebaut werden.

| Ziel | Richtiger Weg | Kernel bauen? |
|------|---------------|---------------|
| Sensor, HAT, Display anbinden | **Device-Tree-Overlay** (`configuration.md`) | Nein |
| Hardware ein-/ausschalten, Takte, PCIe | **`config.txt`** (`config-txt.md`) | Nein |
| Kernelmodul eines Herstellers übersetzen (z.B. Hailo, CAN-Adapter) | **Kernel-Header über `apt`** – siehe unten | Nein |
| Neuere Firmware ausprobieren | **Beta Access** in `raspi-config` (`os-and-software.md`) | Nein |
| Neuerer Kernel gewünscht | `sudo apt full-upgrade`; für Testkernel `rpi-update` | Nein |
| Kernel-Funktion aktivieren, die in keinem `defconfig` steht | Eigener Build | **Ja** |
| Patchset anwenden (z.B. `PREEMPT_RT` für harte Echtzeit) | Eigener Build | **Ja** |
| Treiber für brandneue Hardware, noch nicht im Kernel | Eigener Build mit Hersteller-Patchset | **Ja** |

➜ **Für die Anforderungsanalyse relevant:** Sobald ein Projekt *harte* Echtzeit verlangt –
garantierte Latenz statt «meistens schnell genug» –, führt der Weg über einen
`PREEMPT_RT`-Kernel und damit über einen eigenen Build. Das gehört in die Aufwandsschätzung
und ins `plan.md`, nicht in eine spätere Überraschung. Für *weiche* Echtzeit sind
Hardware-Peripherie und PIO des RP1 (`rp1-gpio.md`) fast immer der bessere Hebel.

---

## Woher der Kernel kommt

Der Raspberry-Pi-Kernel liegt auf GitHub unter
[`raspberrypi/linux`](https://github.com/raspberrypi/linux) und **hinkt dem Upstream-Kernel
bewusst hinterher**:

1. Upstream-Linux entwickelt sich laufend weiter.
2. Raspberry Pi übernimmt **Long-Term-Releases** – nicht jede Version.
3. Je LTS-Release entsteht ein `next`-Branch in `raspberrypi/firmware`.
4. Nach ausgiebigen Tests wird `next` in `main` überführt.

> ➜ **Das erklärt zwei wiederkehrende Beobachtungen:** Ein Treiber, der «seit Kernel 6.x im
> Upstream ist», steht auf dem Pi oft erst Monate später zur Verfügung. Und umgekehrt hat
> der Pi-Kernel Anpassungen, die es im Upstream nicht gibt – ein generischer
> Kernel-Quelltext von kernel.org ist **kein** Ersatz.

Der übliche `apt`-Weg aktualisiert den Kernel auf die jeweils **stabile** Version. Wer den
aktuellen Testkernel braucht, aktualisiert von Hand (`rpi-update` – mit den Vorbehalten aus
`os-and-software.md`).

---

## Kernel-Header – der häufigste Fall

**Das ist der Abschnitt, der in der Praxis am meisten gebraucht wird.** Zum Übersetzen
eines Kernelmoduls braucht es nicht den ganzen Kernel, sondern nur die Header: die
Funktions- und Strukturdefinitionen, gegen die das Modul gebaut wird.

```bash
# 64 Bit (der Normalfall – für Edge AI ohnehin zwingend)
sudo apt install linux-headers-rpi-v8

# 32 Bit
sudo apt install linux-headers-rpi-{v6,v7,v7l}
```

> ⚠️ **Die Installation dauert mehrere Minuten und zeigt keinen Fortschritt.** Nicht
> abbrechen, weil «nichts passiert».

### 🔴 Der Fallstrick: Header und laufender Kernel passen nicht zusammen

> **Nach einem Kernel-Update kann es mehrere Wochen dauern, bis das `apt`-Paket der Header
> nachzieht.** In dieser Zeit passen die installierten Header nicht zum laufenden Kernel –
> und jedes Modul, das dagegen gebaut wird, scheitert oder lädt nicht.

```bash
uname -r                                  # laufender Kernel
ls /lib/modules/                          # wofür Module installiert sind
dpkg -l 'linux-headers-*' | grep ^ii      # welche Header installiert sind
```

➜ **Konsequenz für die Reihenfolge beim Aufsetzen:** Erst `sudo apt full-upgrade`, dann
**neu starten**, dann die Header installieren, dann das Modul bauen. Wer nach dem
Modulbau noch aktualisiert, hat ein Modul für den vorherigen Kernel.

➜ **Wenn die `apt`-Header noch nicht verfügbar sind**, bleibt nur, den passenden
Kernel-Quelltext zu klonen – dort sind die Header enthalten.

**Für DKMS-Pakete gilt dasselbe verschärft:** Ein Modul, das über DKMS bei jedem
Kernel-Update automatisch neu gebaut wird, scheitert still, wenn die Header fehlen. Das
Gerät bootet, aber die Hardware ist weg – der typische Fall bei einem Beschleuniger oder
CAN-Adapter, der «nach dem Update nicht mehr erkannt wird».

---

## Quelltext beschaffen

```bash
sudo apt install git

# Aktiver Branch, ohne Historie – der schnelle Normalfall
git clone --depth=1 https://github.com/raspberrypi/linux

# Bestimmter Branch, ohne Historie
git clone --depth=1 --branch <branch> https://github.com/raspberrypi/linux
```

> ℹ️ `--depth=1` lädt den Branch, aus dem die Raspberry-Pi-OS-Abbilder gebaut werden, **ohne
> Historie**. Ohne diese Option kommt das gesamte Repository mit allen Branches – dauert
> deutlich länger und belegt erheblich mehr Speicher. Auf einem Pi mit SD-Karte ist das ein
> spürbarer Unterschied.

Der Klon dauert auch mit `--depth=1` mehrere Minuten.

---

## Konfiguration je Modell

Die Voreinstellung wird über ein `defconfig` gesetzt. **Die Zuordnung ist nicht
offensichtlich** – insbesondere teilen sich Pi 3 und Pi 4 dasselbe `defconfig`, und die
Variable `KERNEL` bestimmt später nur den Dateinamen beim Installieren.

### 64 Bit

| Modelle | Befehle |
|---------|---------|
| 3, 3+, CM3, CM3+, Zero 2 W, 4, 400, CM4, CM4S | `KERNEL=kernel8`<br>`make bcm2711_defconfig` |
| **5, 500, 500+, CM5** | `KERNEL=kernel_2712`<br>`make bcm2712_defconfig` |

### 32 Bit

| Modelle | Befehle |
|---------|---------|
| 1, CM1, Zero, Zero W | `KERNEL=kernel`<br>`make bcmrpi_defconfig` |
| 2, 3, 3+, CM3, CM3+, Zero 2 W | `KERNEL=kernel7`<br>`make bcm2709_defconfig` |
| 4, 400, CM4, CM4S | `KERNEL=kernel7l`<br>`make bcm2711_defconfig` |

> 🔴 **Die 32-Bit-Ausgabe von Raspberry Pi OS läuft auf den 4er-Modellen mit einem
> 64-Bit-Kernel** und lediglich einem 32-Bit-Userland. Für einen echten 32-Bit-Kernel
> braucht es **beides**: `ARCH=arm` beim Bauen **und** `arm_64bit=0` in `config.txt`. Wer
> nur eines von beiden setzt, bekommt entweder einen Kernel, der nicht gebootet wird, oder
> einen Build, der die falsche Architektur erzeugt.

➜ Die passenden Kernel-Dateinamen und ihre Zuordnung stehen auch in `config-txt.md`.

### Eigene Kernelversion kennzeichnen: `LOCALVERSION`

In `.config`:

```
CONFIG_LOCALVERSION="-v7l-MY_CUSTOM_KERNEL"
```

Auch erreichbar über `menuconfig` → *General setup* → *Local version – append to kernel
release*.

> 🔴 **Das ist keine Kosmetik.** `LOCALVERSION` verhindert, dass der eigene Build die
> Module des Systemkernels in `/lib/modules` **überschreibt**. Ohne eigene Kennung landen
> beide Kernel im selben Verzeichnis – und ein späterer Rückfall auf den Systemkernel
> findet dort die Module des Eigenbaus vor. Ausserdem ist danach in `uname -r` sofort
> erkennbar, welcher Kernel gerade läuft.

---

## Nativ bauen

Direkt auf dem Pi. Einfacher, aber langsam – auf kleinen Modellen sehr langsam.

```bash
sudo apt install bc bison flex libssl-dev make

cd linux
KERNEL=kernel_2712          # Modellabhängig, siehe oben
make bcm2712_defconfig

# 64 Bit
make -j6 Image.gz modules dtbs

# 32 Bit
make -j6 zImage modules dtbs
```

> ℹ️ **`-j<n>` verteilt die Arbeit auf die Kerne.** Empfohlen wird das **1,5-Fache** der
> Prozessorzahl aus `nproc` – auf einem Pi 5 (4 Kerne) also `-j6`.

**Vor dem Bauen an das Naheliegende denken:** Ein Kernel-Build erzeugt über längere Zeit
Volllast auf allen Kernen. Ohne aktive Kühlung drosselt ein Pi 5 dabei zuverlässig
(`debugging-playbook.md`), und ein knapp dimensioniertes Netzteil fällt hier auf, wenn
sonst nie.

---

## Cross-Compilation

Auf einem anderen Rechner bauen – um Grössenordnungen schneller und der Normalfall, sobald
mehr als einmal gebaut wird. Als Host eignet sich Ubuntu; weil Raspberry Pi OS ebenfalls
Debian-basiert ist, sind die Befehle nahezu identisch.

Cross-Compilation erlaubt ausserdem, einen 64-Bit-Kernel von einem 32-Bit-System aus zu
bauen und umgekehrt.

```bash
sudo apt install bc bison flex libssl-dev make libc6-dev libncurses5-dev

# Toolchain je Zielarchitektur
sudo apt install crossbuild-essential-arm64     # 64 Bit
sudo apt install crossbuild-essential-armhf     # 32 Bit
```

```bash
# Beispiel Pi 5, 64 Bit
cd linux
KERNEL=kernel_2712
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

# 32 Bit
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2711_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
```

> ⚠️ **`ARCH=` und `CROSS_COMPILE=` gehören an *jeden* `make`-Aufruf** – auch an
> `defconfig`, `menuconfig` und `modules_install`. Ein vergessenes Präfix baut still gegen
> die Host-Architektur.

> ℹ️ **Unterschied zum nativen Build:** Die Anleitung baut beim Cross-Compilieren `Image`
> (unkomprimiert), nativ dagegen `Image.gz`. Beides ist gültig – der Bootloader erkennt ein
> gzip-Archiv an den Signaturbytes (siehe `config-txt.md`). Wichtig ist nur, dass die
> **kopierte Datei zum gebauten Ziel passt**.

---

## Installieren – ohne sich auszusperren

### Module

```bash
# Nativ
sudo make -j6 modules_install

# Cross-Compiliert, auf gemountete Zielmedien
sudo env PATH=$PATH make -j12 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
     INSTALL_MOD_PATH=mnt/root modules_install
```

**Zielmedium beim Cross-Compilieren finden und einhängen:**

```bash
lsblk                      # VOR dem Anstecken
# Medium anstecken
lsblk                      # das neue Gerät ist das Ziel

mkdir -p mnt/boot mnt/root
sudo mount /dev/sdb1 mnt/boot     # FAT32-Boot-Partition
sudo mount /dev/sdb2 mnt/root     # ext4-Root-Partition
```

> 🔴 **`lsblk` zweimal ausführen – vor und nach dem Anstecken.** Der Gerätename ist nicht
> vorhersagbar. Ein `dd` oder `mount` auf das falsche Gerät trifft die Systemplatte des
> Entwicklungsrechners. Zur Sicherheit zusätzlich Grösse und Partitionslayout gegenprüfen.

### Kernel und Device-Tree-Dateien

```bash
# 64 Bit, nativ – Sicherungskopie ZUERST
sudo cp /boot/firmware/$KERNEL.img /boot/firmware/$KERNEL-backup.img
sudo cp arch/arm64/boot/Image.gz /boot/firmware/$KERNEL.img
sudo cp arch/arm64/boot/dts/broadcom/*.dtb /boot/firmware/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* /boot/firmware/overlays/
sudo cp arch/arm64/boot/dts/overlays/README /boot/firmware/overlays/
sudo reboot
```

> ⚠️ **Der Pfad der 32-Bit-DTBs hat sich mit Kernel 6.5 geändert:**
>
> | Kernelversion | Pfad |
> |---------------|------|
> | bis 6.4 | `arch/arm/boot/dts/*.dtb` |
> | ab 6.5 | `arch/arm/boot/dts/broadcom/*.dtb` |
>
> Anleitungen aus der Zeit davor kopieren ins Leere – ohne Fehlermeldung, weil `cp` mit
> einem nicht passenden Glob schlicht nichts findet. Bei 64 Bit lag der Pfad schon immer
> unter `broadcom/`.

> ⚠️ **`overlays/README` mitkopieren.** Diese Datei ist die massgebliche Liste aller
> Overlays und Parameter der **installierten** Firmware (`configuration.md`). Bleibt die
> alte Fassung liegen, beschreibt sie ab jetzt einen anderen Stand als die Overlays daneben.

### 🔴 Der sichere Weg: nicht überschreiben

Statt `kernel8.img` bzw. `kernel_2712.img` zu ersetzen, den eigenen Kernel **unter neuem
Namen** ablegen und in `config.txt` auswählen:

```ini
kernel=kernel-myconfig.img
```

➜ **Zusammen mit einem eigenen `LOCALVERSION` ergibt das ein System, aus dem man wieder
herauskommt:** Bootet der eigene Kernel nicht, genügt es, die eine Zeile in `config.txt`
auszukommentieren – die Boot-Partition ist FAT und lässt sich in jedem anderen Rechner
bearbeiten. Der Systemkernel ist unberührt, seine Module ebenfalls.

➜ **Noch robuster für Feldgeräte:** dieselbe Auswahl über einen bedingten Filter oder über
A/B-Boot mit `tryboot` (`config-txt.md`). Dann fällt das Gerät nach einem misslungenen
Kernel-Wechsel von selbst zurück, ohne dass jemand die Karte ausbaut.

---

## Kernel konfigurieren mit menuconfig

```bash
sudo apt install libncurses5-dev

make menuconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig   # cross, 64 Bit
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig   # cross, 32 Bit
```

| Taste | Wirkung |
|-------|---------|
| Pfeiltasten | Navigieren |
| Enter | Untermenü öffnen (`--->`) bzw. Auswahl bestätigen |
| Leertaste | Binäre Option umschalten |
| Escape ×2 | Eine Ebene zurück / beenden |
| `H` | Hilfe zur markierten Option |

Gespeichert wird in `.config`. Diese Datei ist die vollständige Konfiguration – zum Sichern
und Wiederverwenden genügt es, sie zu kopieren.

> ➜ **Rat aus der Dokumentation, der es wert ist, wiederholt zu werden:** Der Versuchung
> widerstehen, im ersten Anlauf viele Optionen umzustellen. Eine Konfiguration ist schnell
> zerschossen, und der Fehler zeigt sich erst nach einem langen Build. Klein anfangen,
> `.config` nach jedem funktionierenden Stand sichern.

---

## Patches anwenden

**Zuerst die Version feststellen** – ein Patch gegen die falsche Version schlägt fehl oder,
schlimmer, wendet sich halb an:

```bash
uname -r                    # laufender Kernel
head Makefile -n 4          # Version des Quelltexts im Verzeichnis
```

```
VERSION = 6
PATCHLEVEL = 1
SUBLEVEL = 38               # → 6.1.38
```

**Einzelne Patch-Datei:**

```bash
wget https://www.kernel.org/pub/linux/kernel/projects/rt/6.1/patch-6.1.38-rt13-rc1.patch.gz
gunzip patch-6.1.38-rt13-rc1.patch.gz
cat patch-6.1.38-rt13-rc1.patch | patch -p1
```

**Patchsets im Mailbox-Format** (ein Verzeichnis mit mehreren Dateien):

```bash
git config --global user.name "Vorname Name"
git config --global user.email "adresse@example.com"

git am -3 /path/to/patches/*
```

> ⚠️ Die Git-Identität muss **vor** `git am` gesetzt sein, sonst bricht der Vorgang ab.

Immer der Anleitung des Patch-Herausgebers folgen: Manche Patchsets setzen einen **ganz
bestimmten Commit** als Basis voraus, nicht nur eine Version.

**Zwei typische Anlässe:**

| Anlass | Beschreibung |
|--------|--------------|
| **Neue Hardware** | Hersteller liefern Patchsets als Übergangslösung, bis die Änderungen im Upstream und danach im Pi-Kernel angekommen sind |
| **`PREEMPT_RT`** | Vollständig unterbrechbarer Kernel für harte Echtzeit |

---

## PREEMPT_RT – harte Echtzeit für Robotik

Der wichtigste Grund, überhaupt einen eigenen Kernel zu bauen. Er verdient eigene Zahlen,
weil «Echtzeit» sonst ein Gefühl bleibt.

### Warum der Standardkernel nicht reicht

Ein gewöhnlicher Linux-Kernel ist ein **General Purpose OS** und damit **nicht
deterministisch**. Unter Last – Protokolldateien, Netzwerkverkehr, KI-Inferenz – werden
Hardware-Ereignisse als *SoftIRQs* verzögert abgearbeitet.

| Konfiguration | Worst-Case-Latenz bei einem 250-Hz-Regelkreis |
|---------------|-----------------------------------------------|
| Standardkernel | **> 9 ms** |
| **`PREEMPT_RT` + CPU-Isolation** (`isolcpus=2,3`) | **< 225 µs** |

➜ **Ein Flugregler, der 9 ms auf einen Sensorwert wartet, wird instabil.** Der Unterschied
ist nicht «etwas flotter», sondern der Unterschied zwischen fliegt und stürzt ab. Für
Aktorik mit engem Regelkreis – Drohnen, Balancierroboter, Schrittmotorprofile – ist es
das ausschlaggebende Kriterium.

> ⚠️ **`isolcpus` gehört zur Lösung dazu.** Der Patch allein bringt einen Teil des Gewinns;
> die zitierte Zahl gilt für PREEMPT_RT **plus** exklusiv reservierte Kerne für den
> Regelkreis. Der Parameter steht in `cmdline.txt` (siehe `configuration.md` – eine Zeile!).

### Was der Patch technisch ändert

| Mechanismus | Ohne Patch | Mit `PREEMPT_RT` |
|-------------|-----------|------------------|
| **Spinlocks** | Blockierter Prozess wartet aktiv in einer Schleife, frisst CPU-Zeit, nicht unterbrechbar | **Schlafende Spinlocks** auf Mutex-Basis – der Task wird schlafen gelegt, hochpriorisierte Aufgaben laufen weiter |
| **Interrupts** | Hardware-Interrupts haben absolute Priorität und stoppen alles | **Threaded Interrupts**: fast alle Handler laufen als Kernel-Threads unter dem normalen Scheduler |
| **Prioritätsinversion** | Ein niederpriorer Prozess kann einen hochprioren beliebig lange blockieren | **`rtmutex` mit Priority Inheritance**: Der blockierende Prozess erbt vorübergehend die hohe Priorität, wird schnell fertig und gibt frei |

➜ **Threaded Interrupts sind der praktisch nutzbarste Teil.** Damit lässt sich festlegen,
dass der Interrupt der Motorsteuerung Vorrang vor dem Netzwerk-Interrupt hat – auch wenn
Letzterer tausende Pakete pro Sekunde liefert. Ohne den Patch gewinnt immer die Hardware.

### Der Preis

> 🔴 **Determinismus kostet Durchsatz.** In Vergleichsmessungen ist der **Standardkernel
> etwa 9–12 % schneller** bei gewöhnlichen Berechnungen. Die laufende Verwaltung von
> Interrupt-Prioritäten und Sperren ist nicht umsonst.

➜ **Das ist ein echter Zielkonflikt, kein Detail:** Wer auf demselben Gerät KI-Inferenz
*und* harte Echtzeit will, zahlt bei der Inferenz. Die saubere Antwort ist meist eine
**Aufgabenteilung** – Wahrnehmung auf dem Pi mit NPU, zeitkritische Regelung auf einem
Mikrocontroller (Pico, STM32) – statt beides in einen Kernel zu zwingen.

Dazu kommt der Aufwand: Cross-Compilation, Kernel-Build-Skripte und die Pflege bei jedem
Update. Alles aus [«Zuerst: brauchen Sie das überhaupt?»](#zuerst-brauchen-sie-das-überhaupt)
gilt hier verschärft.

### Vorgehen

1. Kernelversion feststellen (`head Makefile -n 4`) und den **passenden** RT-Patch laden.
2. `cat patch-<version>-rt<n>.patch | patch -p1`
3. In `menuconfig` unter *General setup → Preemption Model* das vollständig unterbrechbare
   Modell wählen.
4. Bauen, unter **neuem Namen** installieren und über `kernel=` in `config.txt` auswählen –
   damit der Rückweg offen bleibt.
5. `isolcpus=` in `cmdline.txt` ergänzen und die Latenz **selbst messen**, statt sie
   anzunehmen.

---

## Änderungen beitragen

Zwei Wege, abhängig davon, was geändert wurde:

| Art der Änderung | Weg |
|------------------|-----|
| Raspberry-Pi-spezifisch (Code oder Fehlerbehebung) | **Pull Request** an [`raspberrypi/linux`](https://github.com/raspberrypi/linux) |
| Allgemein (neuer Treiber, generische Fehlerbehebung) | **Zuerst an den Upstream-Kernel** – per E-Mail an die Mailinglisten, nicht über GitHub |

> ➜ **Der Weg über den Upstream ist lang, und das ist eine Planungsgrösse:** Änderung →
> Aufnahme in Linux → nächstes Long-Term-Release → Test durch Raspberry Pi → stabiler
> Pi-Kernel. Wer auf eine solche Änderung angewiesen ist, plant für die Zwischenzeit mit
> einem Patchset, nicht mit dem Warten.

Für Beiträge an den Upstream gelten dessen Regeln – insbesondere
[Submitting patches](https://www.kernel.org/doc/html/latest/process/submitting-patches.html)
und der
[Linux kernel coding style](https://www.kernel.org/doc/html/latest/process/coding-style.html).

---

## Weitere Ressourcen

- [The Linux kernel](https://www.raspberrypi.com/documentation/computers/linux_kernel.html)
- [`raspberrypi/linux`](https://github.com/raspberrypi/linux) – Kernel-Quelltext und Branches
- [`raspberrypi/firmware`](https://github.com/raspberrypi/firmware) – `next`-Branches je LTS-Release
- `config-txt.md` – `kernel=`, `arm_64bit`, Kernel-Dateinamen, A/B-Boot
- `configuration.md` – Overlays, `/boot/firmware/overlays/README`
- `os-and-software.md` – `apt`, `rpi-update`, Beta Access
