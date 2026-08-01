# RP1 I/O-Controller – GPIO, Pads und Timing

Grundlage: **Raspberry Pi RP1 Peripherals, RP-008370-DS-1** (Build 2023-11-07).

RP1 ist der Peripherie-Controller des Raspberry Pi 5. Er ist der Grund, warum sich der
Pi 5 bei GPIO-Arbeit anders verhält als alle Vorgänger – und die meisten überraschenden
Effekte lassen sich auf zwei Eigenschaften zurückführen: **andere Pad-Grenzwerte** und
**PCIe-Latenz zwischen CPU und GPIO**.

## Inhaltsverzeichnis
1. [Was RP1 ist](#was-rp1-ist)
2. [Verfügbare Peripherie am 40-Pin-Header](#verfügbare-peripherie-am-40-pin-header)
3. [Elektrische Grenzwerte der Pads](#elektrische-grenzwerte-der-pads)
4. [Latenz: warum Bit-Banging auf dem Pi 5 anders ist](#latenz-warum-bit-banging-auf-dem-pi-5-anders-ist)
5. [Interrupts und Hardware-Entprellung](#interrupts-und-hardware-entprellung)
6. [Taktversorgung](#taktversorgung)
7. [Weitere RP1-Funktionen](#weitere-rp1-funktionen)
8. [Konsequenzen für die Praxis](#konsequenzen-für-die-praxis)

---

## Was RP1 ist

Auf allen Raspberry Pi ausser dem Zero gab es immer zwei Chips: einen Application
Processor (AP) und einen Peripherie-Controller. Beim Pi 5 ist Letzterer **RP1**, ein von
Raspberry Pi selbst entwickelter Chip.

| Eigenschaft | Wert |
|-------------|------|
| Anbindung an den AP (BCM2712) | **PCIe 2.0 x4** – chipintern, nicht der Steckverbinder |
| GPIO-Pins | **28** (GPIO 0–27), ein einziger elektrischer Bank: **VDDIO0** |
| Interne Verwaltung | Dual-Core ARM Cortex-M3 |
| Shared SRAM | 64 kB |
| DMA | 8-Kanal-Controller |

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

## Elektrische Grenzwerte der Pads

### ⚠️ Korrektur gegenüber dem Pi 4

| | Raspberry Pi 4 (BCM2711) | **Raspberry Pi 5 (RP1)** |
|---|---|---|
| Treiberstrom pro Pin | 2–**16 mA** | **2 / 4 / 8 / 12 mA** – Maximum **12 mA** |
| Voreinstellung | – | **4 mA** (Reset-Wert des DRIVE-Feldes) |

➜ **Der oft zitierte Wert «16 mA pro Pin» gilt auf dem Pi 5 nicht.** Wer Vorwiderstände
oder Lastannahmen aus Pi-4-Anleitungen übernimmt, überschreitet die Spezifikation. Für
den Pi 5 mit **12 mA** rechnen – und beachten, dass die Voreinstellung bei **4 mA** liegt,
nicht am Maximum.

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
| **USB** | Zwei unabhängige XHCI-Controller, je ein USB-3.0- und ein USB-2.0-PHY – zusammen über **10 Gbps** |
| **MIPI** | 2× CSI-2 + 2× DSI auf zwei gemeinsam genutzten 4-Lane-DPHY, zusammen **8 Gbps**; jeder Kamera-Controller hat eine **ISP-Vorstufe (ISP-FE)** |
| **Ethernet** | Integrierter MAC, externer Gigabit-PHY über RGMII |
| **ADC** | 5 Eingänge, SAR, **12 Bit (ENOB 9,5)**, 500 kSPS – 4 externe Eingänge plus interner Temperatursensor |
| **DMA** | 8 Kanäle für langsame Peripherie |
| **Timebase** | Konfigurierbare «Ticks» zum Takten von DMA und zum Entprellen von GPIO-Ereignissen |

⚠️ **Zum ADC:** RP1 enthält ihn, aber in der Funktionsauswahl-Tabelle der Header-GPIOs
(GPIO 0–27) taucht keine ADC-Funktion auf. Für Analogmessungen am 40-Pin-Header weiterhin
einen externen ADC über I2C oder SPI einplanen (z.B. ADS1115, MCP3008).

**Atomare Registerzugriffe:** Jeder Registerblock mit Atomic Access belegt 4 kB und bietet
Alias-Adressen – `+0x1000` XOR, `+0x2000` Bitmaske setzen, `+0x3000` Bitmaske löschen.
Damit entfällt der Read-Modify-Write-Zyklus, der sonst die doppelte PCIe-Round-Trip-Zeit
kosten würde. Wer eigene Treiber schreibt, sollte das nutzen.

---

## Konsequenzen für die Praxis

| Situation | Regel auf dem Pi 5 |
|-----------|--------------------|
| Vorwiderstand für eine LED dimensionieren | Mit **12 mA** Maximum rechnen, nicht mit 16 mA |
| «Es hat auf dem Pi 4 funktioniert» | Zuerst Treiberstrom und Bit-Banging-Annahmen prüfen |
| Zeitkritisches Protokoll | Hardware-Peripherie oder **PIO**, nicht Software-Takt |
| Taster entprellen | Hardware-Entprellung des RP1 nutzen statt `sleep()` |
| Enge GPIO-Polling-Schleife | ASPM deaktivieren, Write-Barrier vor dem Lesen |
| Mehrere I2C-Geräte mit Adresskonflikt | Pi 5 bietet **4 I2C-Busse** am Header |
| Analogwert messen | Externer ADC über I2C/SPI – der RP1-ADC liegt nicht am Header |
| Bibliothekswahl | `gpiozero` mit lgpio; `RPi.GPIO` kennt RP1 nicht |

---

## Weitere Ressourcen

- [RP1 Peripherals Datasheet](https://datasheets.raspberrypi.com/rp1/rp1-peripherals.pdf)
- [RP1 GPIO Linux Kernel Driver](https://github.com/raspberrypi/linux) – Referenzimplementierung
- [gpiozero Dokumentation](https://gpiozero.readthedocs.io/)
- [GPIO Pinout (interaktiv)](https://pinout.xyz/)
