# RP1 I/O-Controller – GPIO, Pads und Timing

Grundlage: **Raspberry Pi RP1 Peripherals, RP-008370-DS-1** (Build 2023-11-07).

RP1 ist der Peripherie-Controller des Raspberry Pi 5. Er ist der Grund, warum sich der
Pi 5 bei GPIO-Arbeit anders verhält als alle Vorgänger – und die meisten überraschenden
Effekte lassen sich auf zwei Eigenschaften zurückführen: **andere Pad-Grenzwerte** und
**PCIe-Latenz zwischen CPU und GPIO**.

## Inhaltsverzeichnis
1. [Was RP1 ist](#was-rp1-ist)
2. [Verfügbare Peripherie am 40-Pin-Header](#verfügbare-peripherie-am-40-pin-header)
3. [UART auf dem Pi 5](#uart-auf-dem-pi-5)
4. [Elektrische Grenzwerte der Pads](#elektrische-grenzwerte-der-pads)
5. [Latenz: warum Bit-Banging auf dem Pi 5 anders ist](#latenz-warum-bit-banging-auf-dem-pi-5-anders-ist)
6. [Interrupts und Hardware-Entprellung](#interrupts-und-hardware-entprellung)
7. [Taktversorgung](#taktversorgung)
8. [Weitere RP1-Funktionen](#weitere-rp1-funktionen)
9. [Konsequenzen für die Praxis](#konsequenzen-für-die-praxis)

---

## Was RP1 ist

Auf allen Raspberry Pi ausser dem Zero gab es immer zwei Chips: einen Application
Processor (AP) und einen Peripherie-Controller. Beim Pi 5 ist Letzterer **RP1**, ein von
Raspberry Pi selbst entwickelter Chip.

| Eigenschaft | Wert |
|-------------|------|
| Anbindung an den AP (BCM2712) | **PCIe 2.0 x4** – chipintern, nicht der Steckverbinder |
| Gehäuse | BGA, **ca. 12 × 12 mm**, Kugelraster 0,65 mm |
| GPIO-Pins | **28** (GPIO 0–27), ein einziger elektrischer Bank: **VDDIO0** |
| Interne Verwaltung | Dual-Core ARM Cortex-M3 mit eng gekoppeltem Speicher |
| Shared SRAM | 64 kB |
| DMA | 8-Kanal-Controller |

> ℹ️ **RP1 heisst nicht so, weil es der erste Raspberry Pi wäre.** Das `RP` steht für
> Raspberry Pi, die Ziffer für die Generation – RP1 ist der **erste eingebettete
> I/O-Controller**. Mit dem ursprünglichen Raspberry Pi Model B hat der Name nichts zu tun,
> und mit den Mikrocontrollern RP2040 und RP2350 nur die Namenslogik: **RP1 ist kein
> einzeln erhältlicher Chip**, sondern fest in Pi 5 und CM5 verbaut.

> ⚠️ **Nicht verwechseln:** Die **x4**-Verbindung ist die chipinterne Anbindung zwischen
> BCM2712 und RP1. Der **externe** PCIe-Anschluss des Pi 5 (der 16-Pin-FFC für M.2 HAT+
> und NVMe) ist **PCIe 2.0 x1** – siehe [`pcie.md`](pcie.md). Zwei verschiedene Dinge mit
> demselben Namen.

**IO_BANK1 und IO_BANK2 sind für interne Zwecke reserviert.** Nur IO_BANK0 liegt am
40-Pin-Header.

---

## Verfügbare Peripherie am 40-Pin-Header

Der Chip enthält mehr Instanzen, als am Header nutzbar sind. Massgeblich ist, was
**Bank 0** unterstützt:

| Funktion | Am Header verfügbar | Instanzen im Chip |
|----------|---------------------|-------------------|
| **UART** | **5×** | 6 (uart0–uart5) |
| **SPI** | **6×** | 9 (spi0–spi8) |
| **I2C** | **4×** | 7 (i2c0–i2c6) |
| **I2S** | **2×** (1 Clock Producer, 1 Clock Consumer) | 3 |
| **PWM** | 1 Instanz mit **4 unabhängigen Kanälen** | 2 |
| **DPI** | 24-Bit-Parallel-Display-Ausgang | – |
| **PIO** | Programmierbare I/O auf allen 28 Pins | 1 |
| **RIO** | Registered IO (direkter GPIO-Zugriff) | – |
| **GPCLK** | General-Purpose-Clock ein/aus | – |
| **eMMC/SDIO** | 4-Bit-Bus | 2 |
| **AUDIO_OUT** | Stereo-PWM-Audio | – |

➜ **Das ist deutlich mehr als die üblichen «I2C1 und SPI0».** Wer auf dem Pi 4 an
Bus-Kollisionen scheiterte, hat auf dem Pi 5 vier I2C-Busse und sechs SPI-Instanzen zur
Verfügung – die Zuordnung erfolgt über die Alternativfunktionen der Pins (FUNCSEL).

**PIO** ist die grösste Neuerung gegenüber dem Pi 4: derselbe programmierbare
I/O-Baustein wie im RP2040. Damit lassen sich zeitkritische Protokolle in Hardware
abbilden, statt sie in Software zu takten – siehe den Latenz-Abschnitt unten.

### Regel bei der Pin-Zuweisung

> Jeder GPIO kann **eine** Funktion gleichzeitig haben. Und jeder Peripherie-**Eingang**
> (z.B. `I2C3_SCL`) darf nur auf **einem** GPIO ausgewählt sein. Ist derselbe Eingang auf
> mehreren Pins aktiv, sieht die Peripherie das **logische ODER** dieser Eingänge.

Das ist eine leise Fehlerquelle: Ein zweiter, versehentlich auf dieselbe Funktion
gesetzter Pin legt den Bus lahm, ohne dass eine Fehlermeldung erscheint.

---

## UART auf dem Pi 5

Ergänzung aus der offiziellen **Configuration**-Dokumentation. Serielle Schnittstellen
sind der häufigste Fall, in dem Pi-4-Anleitungen auf dem Pi 5 nicht mehr stimmen – weil
sich sowohl die Hardware als auch die Voreinstellung geändert hat.

### Was sich geändert hat

| | Pi 4 / 400 / CM4 | **Pi 5 / 500 / 500+ / CM5** |
|---|---|---|
| UART0 | PL011 | PL011 |
| UART1 | **Mini-UART** | **existiert nicht** |
| Weitere | UART2–UART5 (PL011, ab Werk aus) | **UART0–UART4 + UART10** (alle PL011, ab Werk aus) |
| Primäre UART | UART1 (Mini-UART) an GPIO 14/15 | **UART10 am dedizierten Debug-Header** |

➜ **Der Pi 5 hat keinen Mini-UART mehr.** Damit entfällt die ganze Klasse von Problemen,
die auf dem Pi 3 und 4 daher rührte, dass der Mini-UART seinen Takt aus dem VPU-Kern
bezog: keine Baudratendrift bei Frequenzwechsel, kein `core_freq=250`, kein
`enable_uart=1` als Krücke, kein `miniuart-bt`. Alle Schnittstellen sind vollwertige
PL011.

Die **fünf** am Header nutzbaren UARTs (siehe Tabelle oben) sind UART0–UART4. UART10 ist
die Debug-Schnittstelle und liegt **nicht** am 40-Pin-Header.

### 🔴 Der Fallstrick: `/dev/serial0` zeigt woanders hin

Auf allen Modellen **ausser dem Pi 5** liegt die primäre UART auf:

- **GPIO 14 (TX)** = Header-Pin **8**
- **GPIO 15 (RX)** = Header-Pin **10**

**Auf dem Pi 5 ist die primäre UART standardmässig UART10 am dreipoligen, mit `UART`
beschrifteten Debug-Header** – also `/dev/ttyAMA10`, und dorthin zeigt auch
`/dev/serial0`.

> Wer ein Skript vom Pi 4 übernimmt, das `/dev/serial0` öffnet und ein Gerät an Pin 8/10
> erwartet, redet auf dem Pi 5 mit dem Debug-Header. **Es kommen keine Daten – und keine
> Fehlermeldung.**

| Device-Node | Was |
|-------------|-----|
| `/dev/ttyAMA0` | Erste PL011 (UART0) |
| `/dev/ttyAMA10` | **Debug-UART des Pi 5** |
| `/dev/ttyS0` | Mini-UART (nicht auf dem Pi 5) |
| `/dev/serial0` | Symlink auf die **primäre** UART – modellabhängig |
| `/dev/serial1` | Symlink auf die sekundäre UART (meist Bluetooth) |

**`/dev/serial1` existiert ab Bookworm oft nicht mehr.** Es lässt sich mit
`dtparam=krnbt=off` in `config.txt` erzwingen – die Dokumentation rät ausdrücklich davon
ab, das ohne Not zu tun, weil die Option künftig entfallen kann.

### Zwei `config.txt`-Schalter, die die Zuordnung ändern

| Schalter | Wirkung auf dem Pi 5 |
|----------|----------------------|
| `enable_rp1_uart=1` | Firmware-Debugmeldungen (inkl. **aller Dateizugriffe**) gehen auf **GPIO 14/15** |
| `enable_uart=1` | Ohne Kabel am Debug-Header wandert die **Kernel-Ausgabe** auf GPIO 14/15 |

➜ Beide belegen die Header-Pins mit Konsolenausgabe. Wer dort ein Gerät angeschlossen
hat, bekommt eine unerklärlich «schwatzende» Leitung.

**Umgekehrt ist `enable_rp1_uart=1` genau dann richtig, wenn man die frühe Boot-Phase am
Header sehen will:** Die Firmware initialisiert RP1 UART0 auf 115200 Bit/s und setzt RP1
vor dem Start des OS **nicht** zurück – Ausgabe gibt es damit schon, bevor der Kernel
läuft. Für Bare-Metal-Arbeit gehört `pciex4_reset=0` dazu, damit die PCIe-Konfiguration
des Bootloaders erhalten bleibt. Details in `config-txt.md`.

### Zusätzliche UARTs freischalten

```ini
# Pi 5 / CM5
dtoverlay=uart2-pi5           # uart0-pi5 … uart4-pi5

# Pi 4 / 400 / CM4 / CM4S
dtoverlay=uart2               # uart2 … uart5
```

```bash
dtoverlay -h uart2-pi5        # welche Pins, welche Optionen
cat /boot/firmware/overlays/README
```

Die Pin-Zuordnung steht im Overlay, nicht im Datenblatt – deshalb immer über
`dtoverlay -h` prüfen und nicht raten. Mehr zum Umgang mit Overlays in
[`configuration.md`](configuration.md).

### Serielle Konsole abschalten, Hardware anlassen

Für Projekte mit einem seriellen Gerät (GPS, Modem, Mikrocontroller) gilt fast immer:

- **Serial Port hardware: ein** – die TX/RX-Pins werden freigegeben
- **Serial console: aus** – sonst schickt Linux Boot-Meldungen und einen Login-Prompt auf
  dieselbe Leitung

Beides sind **getrennte** Schalter unter `raspi-config` → *Interface Options*.

### ⚠️ 3,3 V – ausnahmslos

> **Alle UARTs arbeiten mit 3,3 V. Der Anschluss an ein 5-V-System beschädigt den Pi.**
> Für 5-V-Geräte einen Pegelwandler oder einen USB-auf-3,3-V-Seriell-Adapter verwenden.

Das ist dieselbe Regel wie für alle GPIO – hier aber besonders relevant, weil viele
Arduino-Boards und Industriemodule mit 5 V senden.

### Frühe Boot-Ausgabe (Kernel-Debugging)

Wenn das System so früh stehen bleibt, dass die reguläre Konsole noch nicht läuft, hilft
`earlycon` in `cmdline.txt`:

```
# Pi 5, über den Debug-Header
earlycon=pl011,0x107d001000,115200n8
```

> ⚠️ **Ein falsch gewählter Early-Console-Parameter kann das Booten ganz verhindern.**
> Nur mit einem funktionierenden Rückweg (zweite Karte, Kartenleser) einsetzen.

---

## Elektrische Grenzwerte der Pads

### Treiberstrom über alle Generationen

| SoC | Modelle | Voreinstellung | **Maximum** | Pull-Widerstand |
|-----|---------|----------------|-------------|-----------------|
| BCM2835 / 2836 / 2837 / RP3A0 | Pi 1, 2, 3, Zero (alle) | 8 mA | **16 mA** | 50–65 kΩ |
| BCM2711 | Pi 4B, Pi 400, CM4 | 4 mA | **8 mA** | 33–73 kΩ |
| **RP1** | **Pi 5, Pi 500** | **4 mA** | **12 mA** | – |

➜ **Die vielzitierten «16 mA pro Pin» stammen vom Pi 3 und älter – nicht vom Pi 4.**
Beim Pi 4 halbiert der BCM2711 alle Stufen des `DRIVE`-Feldes: Was das Register als 16 mA
beschriftet, liefert real 8 mA.

Daraus folgt eine Reihenfolge, die viele Anleitungen falsch darstellen:

```
Pi 1/2/3/Zero  16 mA  ████████████████
Pi 5 (RP1)     12 mA  ████████████
Pi 4 (BCM2711)  8 mA  ████████
```

**Der Pi 5 treibt also mehr Strom als der Pi 4, nicht weniger.** Wer Lastannahmen von
einem Pi 4 auf einen Pi 5 überträgt, rechnet konservativ und ist auf der sicheren Seite.
Gefährlich ist die umgekehrte Richtung – und vor allem der Sprung von einem Pi 3 auf
irgendetwas Neueres: Dort halbiert (Pi 5) beziehungsweise drittelt (Pi 4) sich das Budget.

> ⚠️ Unabhängig vom Pin-Maximum gilt die Auslegung der 3,3-V-Versorgung: **rund 3 mA pro
> GPIO** im Dauerbetrieb und **50 mA über alle Pins zusammen**. Das Pin-Maximum ist eine
> Eigenschaft des Pads, kein Budget, das man 28-mal ausschöpfen darf – zieht man aus vielen
> Pins gleichzeitig viel Strom, bricht die 3,3-V-Schiene ein und stört SD-Karte und SDRAM.

### Spannungspegel

Auch die garantierten Pegel unterscheiden sich zwischen den Familien – wichtig, wenn ein
Sensor an der Erkennungsschwelle liegt:

| Parameter | BCM2835/36/37, RP3A0 | BCM2711 (Pi 4) |
|-----------|----------------------|----------------|
| V<sub>IL</sub> (Eingang «Low» bis) | 0,9 V | **0,8 V** |
| V<sub>IH</sub> (Eingang «High» ab) | 1,6 V | **2,0 V** |
| V<sub>OL</sub> (Ausgang «Low» max.) | 0,14 V | 0,4 V |
| V<sub>OH</sub> (Ausgang «High» min.) | 3,0 V | 2,6 V |

Der Pi 4 verlangt am Eingang **2,0 V statt 1,6 V** für ein sicheres High. Ein Sensor mit
schwachem Ausgangspegel, der am Pi 3 zuverlässig lief, kann am Pi 4 sporadisch aussetzen –
ein Fehlerbild, das leicht der Software zugeschrieben wird.

> Die Treiberstärke ist **kein Strombegrenzer**. Sie sagt nur, bis zu welchem Strom der Pad
> die Pegel V<sub>OL</sub>/V<sub>OH</sub> noch einhält. Ein auf 2 mA gestellter Pin, aus dem
> 16 mA gezogen werden, geht nicht kaputt – er hält bloss den Pegel nicht mehr und wird
> vom Gegenüber womöglich nicht mehr als High erkannt.

### Eigenschaften jedes Pads

| Eigenschaft | Wert |
|-------------|------|
| Treiberstärke | 2 / 4 / 8 / 12 mA, per `DRIVE`-Feld wählbar |
| Schmitt-Trigger am Eingang | optional, **per Reset aktiv** (`SCHMITT` = 1) |
| Slew-Rate-Begrenzung | optional (`SLEWFAST` = 0 → langsam, Reset) |
| Pull-Verhalten | Pull-Up, Pull-Down, Bus-Keeper oder hochohmig |
| Eingangspuffer | abschaltbar (`IE`, Reset = 0), spart Strom an offenen Pins |
| Ausgang | `OD` (Output Disable) hat Vorrang, **Reset = 1** |
| Fault-Tolerance | Unterhalb 3,63 V fliesst kaum Strom in den Pin, solange IOVDD 0 V ist |
| ESD | **4 kV HBM, 500 V CDM, 200 V MM** |

### Versorgungsspannung der Bank

VDDIO0 kann nominal **1,8 V bis 3,3 V** sein. Auf dem Raspberry Pi 5 sind die
Interface-Timings bei **3,3 V** spezifiziert.

> 🔴 **Gefahrenstelle aus dem Datenblatt:** Die Eingangsschwellen sind per Voreinstellung
> für **2,5–3,3 V** gültig. Für 1,8 V müssen sie über `PADS_BANK0_VOLTAGE_SELECT`
> umgestellt werden. **Eine VDDIO-Spannung über 1,8 V bei auf 1,8 V gestellten
> Eingangsschwellen kann den Chip beschädigen.** 1,8 V mit den Standardschwellen zu
> betreiben ist dagegen sicher – nur die Schwellen liegen dann ausserhalb der Spezifikation.

Für normale Projekte am 40-Pin-Header bleibt es bei 3,3 V und der Voreinstellung. Die
Regel gilt für Eigenentwicklungen, die an der Bankversorgung drehen.

### Was das Datenblatt **nicht** sagt

Ein **Summenstrom pro Bank** ist in diesem Dokument nicht angegeben. Der für den Pi 4
kursierende Wert von ~50 mA lässt sich nicht auf den Pi 5 übertragen. ➜ Konservativ
rechnen und Lasten nicht über GPIO versorgen, sondern über Transistor/Treiber und die
5-V-Schiene.

---

## Latenz: warum Bit-Banging auf dem Pi 5 anders ist

Das ist der praktisch wichtigste Abschnitt des ganzen Dokuments.

GPIO hängt auf dem Pi 5 nicht mehr am SoC, sondern hinter einer PCIe-Verbindung.
**Jeder Zugriff kostet Zeit:**

| Vorgang | Latenz |
|---------|--------|
| PCIe-Link RP1 ↔ BCM2712 | typisch **~1 µs** |
| **Lesen** eines Pins | mindestens **doppelte** Link-Latenz (Request + Response) |
| Schreiben | pipelined (Posted Transactions), Latenz weitgehend verdeckt |
| Aufwachen aus ASPM L0s | **+ ~2 µs** |
| Aufwachen aus ASPM L1 | **+ ~5 µs** |

### Konsequenzen

**1. Bit-gebashte Protokolle sind auf dem Pi 5 keine gute Idee.** Software-getaktetes
1-Wire, WS2812, Software-SPI oder jede Schleife, die Pins schnell und zeitgenau umschalten
muss, kämpft gegen ~1 µs pro Zugriff. Auf dem Pi 4 lag der GPIO im SoC.

➜ **Stattdessen:** Hardware-Peripherie verwenden (SPI, I2C, PWM, I2S) oder **PIO** – der
programmierbare I/O-Block erledigt die Taktung im RP1 selbst, ohne PCIe-Round-Trip pro
Flanke.

**2. In Polling-Schleifen eine Write-Barrier setzen.** Das Datenblatt empfiehlt
ausdrücklich: nach dem letzten Schreibzugriff, der einen Pin umschaltet, eine Write-Barrier
einfügen und **dann** lesen. Sonst kann der Lesezugriff den Zustand vor der Änderung
sehen – und man round-trippt zweimal.

**3. ASPM abschalten, wenn die Schleife eng ist.** Wörtlich aus dem Datenblatt: Liegt die
Verzögerung in einer GPIO-Polling-Schleife bei 10–100 µs, sollte ASPM deaktiviert werden,
damit der Link in L0 bleibt. Sonst kommen bei seltenen Zugriffen 2–5 µs Aufwachzeit dazu –
unregelmässig und schwer zu diagnostizieren.

**4. ADC und RIO nicht gleichzeitig pollen.** Beide hängen am selben APB-Splitter. Wer
den ADC-Statusregister pollt, bremst RIO-Operationen. Das Datenblatt empfiehlt für den
ADC **DMA- oder FIFO-Betrieb**, wenn beides gleichzeitig genutzt wird.

**5. Store-Reordering verhindern.** Für AARCH64 empfiehlt das Datenblatt das
Speicher-Mapping **`Device_nGnRE`**, damit Schreibzugriffe nicht umsortiert werden.

➜ **Für die meisten Projekte in Python mit `gpiozero` ist all das nicht direkt sichtbar** –
die Bibliotheken kümmern sich darum. Relevant wird es, sobald jemand «das hat auf dem
Pi 4 funktioniert» sagt und eine zeitkritische Schleife mitbringt.

---

## Interrupts und Hardware-Entprellung

Jeder GPIO kann in **acht** Szenarien einen Interrupt auslösen:

| Typ | Bedeutung |
|-----|-----------|
| Level High / Low | Pin ist logisch 1 bzw. 0 |
| **Debounced** Level High / Low | Pin ist **länger als die Entprellzeit** 1 bzw. 0 |
| Edge High / Low | Flanke 0→1 bzw. 1→0 |
| **Filtered** Edge High / Low | Flanke, nachdem die Filterzeit abgelaufen ist |

➜ **RP1 entprellt in Hardware.** Die Filterzeit wird über `IO_BANK0_GPIOn_CTRL.F_M` in
Einheiten von IO_BANK0-Ticks gesetzt. Für Taster heisst das: Software-Entprellung mit
`sleep()` ist auf dem Pi 5 nicht mehr nötig, sondern nur noch ein Notbehelf.

**Verhalten, das man kennen muss:**
- **Level-Interrupts werden nicht gelatcht.** Wechselt der Pin, verschwindet der Interrupt.
- **Edge-Interrupts** stehen in `GPIOn_STATUS` und werden durch Schreiben einer 1 in
  `GPIOn_CTRL.IRQRESET` gelöscht.
- Alle Quellen werden verodert und auf drei Ziele geführt: Proc 0, Proc 1 und PCIe (der
  Host-Prozessor).
- Für **Level-basierte** Interrupts muss der IACK-Mechanismus aktiviert sein, sonst kann
  der Host Interrupts verpassen.

---

## Taktversorgung

| Takt | Frequenz |
|------|----------|
| Referenzquarz | **50 MHz** |
| `clk_sys` (Core) | typisch **200 MHz** (Core-PLL-VCO 2 GHz) |
| `clk_uart` | typisch **48 MHz** |
| `clk_pwm` | bis **150 MHz** |
| RGMII (Ethernet) | 125 MHz |
| I2S-Master | typisch 12,288 MHz (2^N × 48000) |
| AUDIO_IN / AUDIO_OUT | 76,8 MHz / 153,6 MHz (Audio-PLL-VCO 1,536 GHz) |

SPI-Master und I2C werden aus `clk_sys` getaktet und haben interne Teiler für die
Datenrate. PWM läuft aus dem unabhängigen `clk_pwm` – deshalb sind auf dem Pi 5 höhere
PWM-Auflösungen möglich als über Software-PWM.

---

## Weitere RP1-Funktionen

| Block | Details |
|-------|---------|
| **USB** | Zwei unabhängige XHCI-Controller, je ein USB-3.0- und ein USB-2.0-PHY – zusammen über **10 Gbps** und **mehr als die doppelte nutzbare Bandbreite des Pi 4** |
| **SDIO/eMMC** | 2 Schnittstellen – **am Pi 5 ungenutzt**, aber für eigene CM5-Trägerboards verfügbar |
| **MIPI** | 2× CSI-2 + 2× DSI auf zwei gemeinsam genutzten 4-Lane-DPHY, zusammen **8 Gbps**; jeder Kamera-Controller hat eine **ISP-Vorstufe (ISP-FE)** |
| **Ethernet** | Integrierter MAC, externer Gigabit-PHY über RGMII |
| **ADC** | 5 Eingänge, SAR, **12 Bit (ENOB 9,5)**, 500 kSPS – 4 externe Eingänge plus interner Temperatursensor |
| **DMA** | 8 Kanäle für langsame Peripherie |
| **Timebase** | Konfigurierbare «Ticks» zum Takten von DMA und zum Entprellen von GPIO-Ereignissen |

⚠️ **Zum ADC:** RP1 enthält ihn, aber in der Funktionsauswahl-Tabelle der Header-GPIOs
(GPIO 0–27) taucht keine ADC-Funktion auf. Für Analogmessungen am 40-Pin-Header weiterhin
einen externen ADC über I2C oder SPI einplanen (z.B. ADS1115, MCP3008).

> ➜ **Warum die USB-Angabe zählt:** Am Pi 4 hängen alle vier Buchsen an einem einzigen
> VL805-Controller, dessen USB-2.0-Leitungen sich **einen gemeinsamen internen Hub** teilen
> – die Bandbreite für alle USB-2.0-Geräte zusammen entspricht dort einem einzigen Port
> (siehe `interfaces.md`). Der Pi 5 hat **zwei getrennte Controller**. Für mehrere
> USB-Kameras oder USB-Audio ist das der eigentliche Unterschied zwischen den Modellen,
> nicht der Prozessor.

### Multimedia- und Audioblöcke

RP1 bringt Video- und Audiofunktionen mit, die **ohne externen Codec** auskommen:

| Block | Was er kann |
|-------|-------------|
| **Video-DAC** | 3-kanalig, **PAL/NTSC und VGA** – am Pi 5 ist **nur ein Composite-Kanal** herausgeführt |
| **DPI-Bildgenerator** | Paralleldisplay an der GPIO-Leiste (siehe `interfaces.md`) |
| **CSI-2-Empfänger** | mit DMA und ISP-Vorstufe für Zuschnitt und Statistik |
| **DSI-Sender** | mit eigenem DMA |
| **Delta-Sigma-PWM** | **Analoger Audioausgang ohne Codec-Baustein** |
| **PDM-Mikrofoneingang** | Taktgenerator und **Stereo-Bitstrom-Eingang** |

➜ **Der PDM-Eingang ist für Sprachprojekte relevant.** PDM-Mikrofone lassen sich damit
**direkt** anbinden – ohne USB-Mikrofon und ohne I2S-Codec-Platine. Für einen
Sprachassistenten auf dem Pi 5 entfällt damit eine Komponente aus dem Bauplan.

⚠️ **Der Video-DAC kann VGA, der Pi 5 führt es nicht heraus.** Wer analoge Bildausgabe
jenseits von Composite braucht, muss ein eigenes Trägerboard entwerfen – auf dem
Einplatinenrechner ist die Fähigkeit vorhanden, aber nicht zugänglich.

**Atomare Registerzugriffe:** Jeder Registerblock mit Atomic Access belegt 4 kB und bietet
Alias-Adressen – `+0x1000` XOR, `+0x2000` Bitmaske setzen, `+0x3000` Bitmaske löschen.
Damit entfällt der Read-Modify-Write-Zyklus, der sonst die doppelte PCIe-Round-Trip-Zeit
kosten würde. Wer eigene Treiber schreibt, sollte das nutzen.

---

## 🔴 `raspi-gpio` funktioniert auf dem Pi 5 nicht

Das Werkzeug **`raspi-gpio` ist abgekündigt** – es wird ausdrücklich weder gewartet noch
unterstützt und ist durch **`pinctrl`** ersetzt.

Für den Pi 5 kommt ein zweiter, härterer Grund dazu: `raspi-gpio` schreibt **direkt in die
GPIO-Register des BCM283x**. Auf dem Pi 5 liegen die GPIO aber am **RP1**, nicht am SoC –
das Werkzeug greift dort schlicht ins Leere.

```bash
pinctrl              # alle Pins mit Funktion und Pegel
pinctrl get 17       # ein einzelner Pin
pinctrl set 17 op dh # als Ausgang, High
```

➜ **Damit ist `raspi-gpio` der Alterstest für GPIO-Anleitungen** – parallel zu
`raspistill`/`raspivid` bei der Kamera und `h264_omx` bei `ffmpeg` (siehe `SKILL.md`).
Taucht es in einer Anleitung auf, stammt diese aus der Zeit vor dem Pi 5, und ihre übrigen
Annahmen zu Treiberstrom, Timing und Pin-Verhalten sind ebenfalls zu prüfen.

---

## Konsequenzen für die Praxis

| Situation | Regel auf dem Pi 5 |
|-----------|--------------------|
| Vorwiderstand für eine LED dimensionieren | Am Pi 5 mit **12 mA** rechnen, am Pi 4 mit **8 mA**, erst ab Pi 3 mit 16 mA |
| «Es hat auf dem Pi 4 funktioniert» | Bit-Banging-Annahmen prüfen – beim Treiberstrom ist der Pi 5 der stärkere |
| «Es hat auf dem Pi 3 funktioniert» | Treiberstrom halbiert (Pi 5) bzw. gedrittelt (Pi 4), und der Pi 4 verlangt 2,0 V für High |
| Zeitkritisches Protokoll | Hardware-Peripherie oder **PIO**, nicht Software-Takt |
| Taster entprellen | Hardware-Entprellung des RP1 nutzen statt `sleep()` |
| Enge GPIO-Polling-Schleife | ASPM deaktivieren, Write-Barrier vor dem Lesen |
| Mehrere I2C-Geräte mit Adresskonflikt | Pi 5 bietet **4 I2C-Busse** am Header |
| Analogwert messen | Externer ADC über I2C/SPI – der RP1-ADC liegt nicht am Header |
| Serielles Gerät an Pin 8/10 | **Nicht `/dev/serial0`** – das zeigt auf dem Pi 5 auf den Debug-Header |
| «Der Mini-UART macht Ärger» | Gibt es auf dem Pi 5 nicht mehr – Ursache liegt woanders |
| Bibliothekswahl | `gpiozero` mit lgpio; `RPi.GPIO` kennt RP1 nicht |
| Aktor darf beim Einschalten nicht anziehen | **Externer Pull-Widerstand am Treibereingang**; `gpio=` in `config.txt` nur ergänzend |
| JTAG gewünscht | `enable_jtag_gpio=1` belegt GPIO 22–27 dauerhaft – bei der Pinplanung einrechnen |

### Startzustand der Pins

Zwischen dem Anlegen der Spannung und dem ersten Zugriff durch Software sind die GPIOs in
ihrem Reset-Zustand. `config.txt` kann definierte Zustände vorgeben:

```ini
gpio=12=op,dl        # Ausgang, treibt low
gpio=17-21=ip,pd     # Eingang mit Pull-down
gpio=0-27=a2         # Alternativfunktion 2 für den ganzen Bereich (z.B. DPI24)
```

> 🔴 **Das ist keine Absicherung, sondern eine Verkürzung des Fensters.** Auch diese
> Einstellungen greifen erst **einige Sekunden** nach dem Einschalten – beim Booten über
> Netzwerk oder USB-Massenspeicher später. Sie wirken ausserdem nicht auf den Kernel: Die
> Pins erscheinen nicht in sysfs, und `pinctrl`-Einträge im Device Tree oder das Werkzeug
> `pinctrl` können sie überschreiben.

Alle Kürzel und die Zusammenarbeit mit bedingten Filtern stehen in `config-txt.md`.

---

## Weitere Ressourcen

- [`configuration.md`](configuration.md) – Overlays, `config.txt`, `raspi-config`
- [`config-txt.md`](config-txt.md) – Dateiformat, Filter, `gpio=`, `enable_rp1_uart`
- [RP1 Peripherals Datasheet](https://datasheets.raspberrypi.com/rp1/rp1-peripherals.pdf)
- [RP1 GPIO Linux Kernel Driver](https://github.com/raspberrypi/linux) – Referenzimplementierung
- [gpiozero Dokumentation](https://gpiozero.readthedocs.io/)
- [GPIO Pinout (interaktiv)](https://pinout.xyz/)
