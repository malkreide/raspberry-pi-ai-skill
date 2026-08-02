# PCIe-Anschluss & M.2 HAT+ – Raspberry Pi 5

Grundlage dieser Referenz sind die offiziellen Raspberry-Pi-Dokumente:

| Dokument | Nummer | Inhalt |
|----------|--------|--------|
| Raspberry Pi Connector for PCIe | RP-008298-DS-1 (Rev. 1.1, 15.01.2024) | Steckerspezifikation, Pinout, FFC-Anforderungen, Power States |
| Raspberry Pi M.2 HAT+ Product Brief | RP-009234-MM-1 (September 2025) | M.2 HAT+ Standard und Compact |

> ⚠️ **Die wichtigste Regel vorweg:** Das FFC-Kabel muss vom Typ
> **opposite-sides-contact** sein (Kontakte an gegenüberliegenden Enden auf
> unterschiedlichen Seiten). Ein Kabel mit gleichseitigen Kontakten ist **nicht
> umkehrbar** – falsch herum eingesteckt **kurzschliesst es den Raspberry Pi 5
> und/oder die Zusatzplatine**. Das ist kein Konfigurationsfehler, sondern ein
> Hardwareschaden. Immer das mitgelieferte Kabel verwenden.

## Inhaltsverzeichnis
1. [Der Anschluss](#der-anschluss)
2. [Pinout](#pinout)
3. [FFC-Kabel](#ffc-kabel)
4. [Strombudget am PCIe-Anschluss](#strombudget-am-pcie-anschluss)
5. [Sideband-Signale für eigene Platinen](#sideband-signale-für-eigene-platinen)
6. [Power States des Pi 5](#power-states-des-pi-5)
7. [M.2 HAT+](#m2-hat)
8. [Temperaturgrenze im Stapel](#temperaturgrenze-im-stapel)
9. [Troubleshooting](#troubleshooting)
10. [Begriffe: HAT, HAT+ und «kein HAT»](#begriffe-hat-hat-und-kein-hat)

---

## Der Anschluss

Der Raspberry Pi 5 ist das erste Raspberry-Pi-Produkt mit einem PCI-Express-Anschluss.

| Eigenschaft | Wert |
|-------------|------|
| Bauform | 16-Pin FFC, **0,5 mm Raster**, vertikal montiert |
| Bezeichnung auf der Platine | **J20** |
| Steckertyp (Pi 5) | 62674-161120ALF |
| Lanes | 1× PCIe **Gen 2** |
| Sideband-Pegel | **3,3 V** |
| 5-V-Versorgung | Pins 1 und 2, je **500 mA** (zusammen **1 A**) |
| Kontaktfinger am Pi 5 | rechte Seite |

> **Gen 3:** Das Dokument sagt wörtlich: *«Signals can be run at Gen 3 speeds, but this
> is not officially supported.»* Das deckt sich mit dem Product Brief, der PCIe 2.0
> spezifiziert. Gen 3 ist damit dokumentiert als Möglichkeit, nicht als Zusage – bei
> Instabilität ist der Rückfall auf Gen 2 der erste Schritt (siehe
> `debugging-playbook.md`).
>
> Die **Configuration**-Dokumentation wird noch deutlicher: Der Pi 5 ist für **Gen 2.0
> zertifiziert**, Gen 3 ist deshalb ab Werk deaktiviert, und ein Erzwingen kann zu
> **Datenkorruption oder Systeminstabilität** führen, wenn Kabel oder HAT die höhere
> Frequenz nicht mitmachen. Empfohlen wird die Umstellung nur, wenn ein PCIe-HAT sie
> ausdrücklich verlangt.

**Zwei Wege, dasselbe Ergebnis:**

```bash
sudo raspi-config      # 6 Advanced Options → A8 PCIe Speed
```
```ini
# oder direkt in /boot/firmware/config.txt
dtparam=pciex1_gen=3
```

---

## Pinout

Pinout des 16-Wege-FFC-Anschlusses J20 auf dem Raspberry Pi 5:

| Pin | Signal | Bemerkung |
|-----|--------|-----------|
| 1 | **+5 V** | max. 500 mA |
| 2 | **+5 V** | max. 500 mA |
| 3 | GND | |
| 4 | PCIE_CLK_P | Referenztakt, differentiell |
| 5 | PCIE_CLK_N | |
| 6 | GND | |
| 7 | PCIE_RX_P | Empfang, differentiell |
| 8 | PCIE_RX_N | |
| 9 | GND | |
| 10 | PCIE_TX_P | Sendung, differentiell |
| 11 | PCIE_TX_N | |
| 12 | GND | |
| 13 | **PCIE_PWR_EN** | 3,3-V-**Ausgang** des Pi |
| 14 | **PCIE_DET_WAKE** | 3,3-V-**Eingang** des Pi |
| 15 | PCIE_CLKREQ_N | 3,3 V |
| 16 | PCIE_RST_B | 3,3 V |
| SH1–SH4 | – | **Mechanische Befestigungspins.** Elektrisch nicht angeschlossen, auf dem Pi 5 lediglich auf Masse gelegt. Nicht als Masseverbindung einplanen. |

```
J20 (16W FFC, 0.5 mm), Blick auf den Pi 5

  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
 5V 5V GND│  │ GND│  │ GND│  │ GND│  │  │  │
          │  │    │  │    │  │    │  │  │  └── RST_B
          │  │    │  │    │  │    │  │  └───── CLKREQ_N
          │  │    │  │    │  │    │  └──────── DET_WAKE  (Eingang)
          │  │    │  │    │  │    └─────────── PWR_EN    (Ausgang)
          │  │    │  │    │  └──────────────── TX_N
          │  │    │  │    └─────────────────── TX_P
          │  │    │  └──────────────────────── RX_N
          │  │    └─────────────────────────── RX_P
          │  └──────────────────────────────── CLK_N
          └─────────────────────────────────── CLK_P
```

---

## FFC-Kabel

| Anforderung | Wert |
|-------------|------|
| **Typ** | **opposite-sides-contact** (zwingend, siehe Warnung oben) |
| Maximale Länge | **50 mm** |
| Differentielle Impedanz | **90 Ω ± 10 %** |
| Massebezug | durchgehende Massefläche |
| Raster | 0,5 mm, 16-polig |

**Warum das strikt ist:** PCIe Gen 2 arbeitet mit 5 GT/s. Ein längeres oder nicht
impedanzkontrolliertes Kabel führt nicht zu «etwas langsamer», sondern zu Link-Fehlern,
sporadisch verschwindenden Geräten und AER-Meldungen im Kernel-Log.

➜ **Praxisregel:** Kein Verlängerungskabel, keine improvisierten Adapter, kein Kabel
aus dem Kamera- oder Display-Zubehör. Das dem HAT beiliegende Kabel verwenden.

---

## Strombudget am PCIe-Anschluss

Der FFC liefert **5 V über die Pins 1 und 2 mit je 500 mA, also 1 A insgesamt (5 W)**.

Das ist die Grenze **des Steckers**, nicht des Gesamtsystems: Ein HAT+ sitzt zusätzlich
auf dem 40-Pin-Header und kann darüber weitere Leistung beziehen – der offizielle
M.2 HAT+ gibt bis zu 3 A an das M.2-Gerät ab. Die beiden Angaben stammen aus
unterschiedlichen Dokumenten und beschreiben unterschiedliche Pfade.

**Für die Projektplanung:**

- Eine Zusatzplatine, die **ausschliesslich** über den FFC versorgt wird, hat **5 W** zur
  Verfügung – mehr nicht.
- Für alles darüber ist ein HAT+ mit Header-Anschluss oder eine externe Versorgung nötig.
- Das Netzteil-Budget des Gesamtsystems bleibt davon unberührt: Pi 5 + NPU + SSD
  gehören weiterhin in die Rechnung aus [`hardware-specs.md`](hardware-specs.md).

---

## Sideband-Signale für eigene Platinen

Relevant, wenn eine eigene PCIe-Platine entwickelt wird – und erklärt zwei häufige
«Gerät wird nicht erkannt»-Fälle.

### PCIE_PWR_EN (Pin 13)

- 3,3-V-**Ausgang** vom Pi an die Zusatzplatine
- Signalisiert der Platine, ihre Spannungsversorgungen hochzufahren
  (beim M.2 M Key HAT+ etwa die 3,3 V für das M.2-Modul, erzeugt aus den 5 V)
- **Auf jeder HAT+-Platine einen 100-kΩ-Pull-down vorsehen**

### PCIE_DET_WAKE (Pin 14)

- 3,3-V-**Eingang** am Pi
- **Muss auf High gezogen werden**, sonst probt der Pi den PCIe-Bus beim Booten nicht
  und das Gerät erscheint nie:
  - über einen Spannungsteiler aus 5 V: 3k6 / 6k8 (Ausgangsimpedanz 2,35 kΩ), **oder**
  - über dauerhaft anliegende 3,3 V mit 2,2 kΩ
- Der Pi erkennt den High-Pegel beim Booten und tastet daraufhin den PCIe-Bus ab
- Für Wakeup wird dieses Signal über **PCIe WAKE#** auf Low gezogen

➜ **Debugging-Konsequenz:** Erscheint eine selbst entwickelte Platine nicht in `lspci`,
ist der Pull an DET_WAKE der erste Verdacht – noch vor Treibern und Kernel-Version.

---

## Power States des Pi 5

Relevant für PCIe-Zusatzplatinen, weil sie bestimmen, welche Rails anliegen:

| Zustand | Bedeutung |
|---------|-----------|
| **OFF** | Keine 5 V am Board |
| **WARM-STANDBY** | Pi angehalten, aber **alle Rails weiterhin aktiv**. Standardverhalten bei `sudo halt` oder Power-Button-Aus |
| **STANDBY** | Nur die +5-V-Schiene aktiv (PMIC versorgt), alle übrigen Versorgungen aus. Per EEPROM anstelle von WARM-STANDBY konfigurierbar |
| **SLEEP** | Einige Rails aus (u.a. CPU-Kern), Linux in Suspend-to-RAM. Power-Button weckt via PMIC nach ACTIVE |
| **ACTIVE** | Alle Rails aktiv, System läuft |

⚠️ **SLEEP ist auf dem Raspberry Pi 5 laut Dokument ungetestet und nicht unterstützt.**
Für batteriebetriebene Projekte deshalb nicht mit Suspend-to-RAM planen – stattdessen
STANDBY per EEPROM konfigurieren oder das System sauber herunterfahren und über den
Power-Button bzw. die RTC-Weckfunktion starten.

➜ Wichtig für Dauerbetrieb: Nach `sudo halt` bleiben im Standardfall **alle Rails aktiv**
(WARM-STANDBY). Wer erwartet, dass der Pi danach «stromlos» ist, misst trotzdem
Verbrauch – und angeschlossene PCIe-Geräte bleiben versorgt.

### Der Schalter dazu

Was das PCIe-Dokument elektrisch beschreibt, heisst in der Bedienoberfläche
**Shutdown Behaviour**:

```
raspi-config → 6 Advanced Options → A11 Shutdown Behaviour
   B1 Full power off      – vollständig aus
   B2 VPU sleep mode      – Restspannung bleibt (Standard auf Pi 4B, Pi 5, CM4)
```

➜ Für batterie- oder solargespeiste Aufbauten `B1` setzen. Die zweifarbige LED des Pi 5
leuchtet nach dem Herunterfahren **rot** – das ist der Standby-Zustand, nicht «aus».
Details in `configuration.md`.

---

## M.2 HAT+

Der offizielle Adapter von der 16-Pin-FFC-Schnittstelle auf M.2 M Key.

### Varianten

| | **M.2 HAT+ Standard** | **M.2 HAT+ Compact** |
|---|---|---|
| Listenpreis | $12 | $15 |
| Unterstützte Formfaktoren | **2230 und 2242** | **nur 2230** |
| Abmessungen | 65 × 56,5 mm | 65 × 56,5 mm, L-förmig bis 71,5 mm |
| Gedacht für | Pi 5 **mit Active Cooler** | Raspberry Pi Case für Pi 5 |
| Lieferumfang | Flachbandkabel, **16-mm-Stacking-Header**, Gewindeabstandshalter und Schrauben, gerändelte Doppelbundschraube zur Fixierung des M.2-Moduls | Flachbandkabel, Montagematerial |

**Die Variantenwahl ist eine Gehäuse-Entscheidung, keine Leistungsfrage:**

- **Standard:** Der beiliegende 16-mm-Stacking-Header ist so bemessen, dass der HAT
  **über dem montierten Active Cooler** sitzt. Wer den Active Cooler braucht – bei
  Hailo-Projekten also immer – nimmt diese Variante.
- **Compact:** L-förmig ausgeschnitten, damit im offiziellen Gehäuse der integrierte
  Lüfter frei bleibt. Der Preis dafür: **nur 2230**, keine 2242-Module.

### Gemeinsame Eigenschaften

| Eigenschaft | Wert |
|-------------|------|
| Schnittstelle | 1× PCIe 2.0, **bis 500 MB/s** Spitzenübertragungsrate |
| Stromabgabe an das M.2-Gerät | bis **3 A** |
| Anzeigen | Power- und Aktivitäts-LED |
| Spezifikation | konform zur **HAT+**-Spezifikation, wird von aktueller Firmware **automatisch erkannt** |
| **Betriebstemperatur** | **0 °C bis 50 °C (Umgebung)** |
| Produktionszusage | mindestens bis **Januar 2032** |
| Bohrbild | 58 × 49 mm, 3,5 mm Kantenabstand – deckungsgleich mit dem Pi |

### Warnungen aus dem Product Brief

- Das Produkt darf **nur über die PCIe-Schnittstelle** mit einem Raspberry Pi verbunden
  werden.
- Externe Netzteile müssen den Vorschriften des Einsatzlandes entsprechen.
- Betrieb in **gut belüfteter Umgebung**; ein verwendetes Gehäuse darf nicht abgedeckt
  werden.
- Im Betrieb sicher befestigen, kein Kontakt mit leitfähigen Gegenständen.
- Inkompatible Geräte an der PCIe-Schnittstelle können Konformität und Garantie kosten
  und den Pi beschädigen.
- Kabel und Stecker aller Peripheriegeräte brauchen ausreichende Isolation.
- **Betrieb erfordert Aufsicht durch Erwachsene** – relevant für den Schuleinsatz.

---

## Temperaturgrenze im Stapel

Das ist der Punkt, der in Projektplänen am häufigsten fehlt:

| Komponente | Zulässige Umgebungstemperatur |
|------------|-------------------------------|
| Raspberry Pi 5 | 0 °C bis **70 °C** |
| **M.2 HAT+** | 0 °C bis **50 °C** |

➜ **Für das Gesamtsystem gilt die niedrigste Grenze.** Ein Pi 5 mit M.2 HAT+ ist ein
**0–50-°C-System**, nicht ein 0–70-°C-System. Wer die Pi-Grenze aus
[`mechanical.md`](mechanical.md) als Systemgrenze verwendet, plant 20 °C zu optimistisch.

**Konsequenzen:**

- Im geschlossenen Gehäuse unter Volllast ist der Abstand zu 50 °C schnell aufgebraucht –
  bei 25 °C Raumtemperatur sind 45–55 °C Innentemperatur realistisch.
- Schaltschrank-, Dachboden- und Sommerbetrieb neu rechnen, sobald ein M.2 HAT+
  im Spiel ist.
- Die Innentemperatur messen, nicht schätzen. `vcgencmd measure_temp` liefert die
  **SoC**-Temperatur und sagt über die Umgebungstemperatur im Gehäuse wenig aus.
- Das gilt zusätzlich zu den SoC-Throttling-Schwellen (80/85 °C), nicht statt ihnen.

---

## Troubleshooting

| Symptom | Erster Verdacht |
|---------|-----------------|
| Gerät fehlt komplett in `lspci` | FFC nicht vollständig eingerastet; bei Eigenentwicklung: Pull an **DET_WAKE** fehlt |
| Gerät verschwindet sporadisch, AER-Meldungen | Gen 3 aktiviert (nicht spezifiziert) → auf Gen 2 zurück; FFC zu lang oder ohne Impedanzkontrolle |
| Link läuft nur mit 5 GT/s | Das ist **Gen 2 und damit der spezifizierte Zustand**, kein Fehler |
| Gerät startet nicht, keine LED am HAT | PCIE_PWR_EN wird nicht ausgewertet; Netzteil unterdimensioniert |
| Instabil unter Last, keine Unterspannung | Umgebungstemperatur gegen die **50-°C-Grenze** des HAT prüfen |
| Nach `sudo halt` weiterhin Stromverbrauch | Erwartetes Verhalten: **WARM-STANDBY** lässt alle Rails aktiv |
| Pi oder HAT nach dem Anstecken defekt | FFC-Typ prüfen: gleichseitige Kontakte falsch herum = Kurzschluss |

Befehle und ausführliche Diagnose: `debugging-playbook.md`.

### «Link Down» – der Fehler auf der physischen Ebene

Meldet `dmesg` beim Host-Bridge-Controller (`brcm-pcie`) ein **«Link Down»** und `lspci`
zeigt gar kein Gerät, ist das **Link-Training** gescheitert – die LTSSM-Zustandsmaschine
kommt nicht zustande. Das passiert **vor** jeder Treiberfrage; Treiberkompatibilität ist
dann nicht die Ursache.

Die drei häufigsten physischen Ursachen:

1. **FFC falsch herum.** Die Metallkontakte müssen zur Platine zeigen.
2. **ZIF-Konnektor beschädigt.** Diese Steckverbinder sind **nicht für hunderte
   Steckzyklen ausgelegt**. Wer beim Aufbauen oft umsteckt, verschleisst sie.
3. **Verschmutzte oder gerissene Kontakte.** Unter **zehnfacher Vergrösserung** prüfen;
   reinigen mit **99-prozentigem Isopropanol**.

➜ **Das gehört an den Anfang der Fehlersuche, nicht ans Ende.** Softwareseitige
Diagnose an einem Link, der physisch nicht steht, führt zu nichts.

### ASPM abschalten

```ini
dtparam=pciex1_aspm=off
```

Kann die Stabilität verbessern, wenn Aussetzer im Zusammenhang mit Energiesparzuständen
auftreten.

> ⚠️ **Es löst das Grundproblem nicht.** Bei Gen-3-Betrieb sind Einstreuungen im
> Gigahertz-Bereich die eigentliche Ursache; ASPM abzuschalten kaschiert sie
> bestenfalls. Die belastbare Massnahme bleibt `dtparam=pciex1_gen=2`.

> ℹ️ Der Hailo-Treiber schaltet **ASPM L0s von sich aus ab** – die entsprechende
> `dmesg`-Zeile ist erwartet (`hailo.md`).

---

## Begriffe: HAT, HAT+ und «kein HAT»

Das PCIe-Dokument stellt ausdrücklich klar:

> Zusatzplatinen von Drittanbietern sind **nicht** an den HAT-Formfaktor gebunden – sie
> können zum Beispiel unterhalb des Raspberry Pi montiert werden. Solange sie die
> HAT-Spezifikation nicht einhalten, dürfen sie aber **nicht als HAT bezeichnet** werden.

Für Baupläne und Stücklisten heisst das:

- **HAT+** – erfüllt die HAT+-Spezifikation, wird automatisch erkannt (z.B. M.2 HAT+)
- **HAT** – erfüllt die HAT-Spezifikation
- **Zusatzplatine / Adapter** – alles andere, auch wenn es im Handel «HAT» genannt wird

Die Unterscheidung ist nicht kosmetisch: Nur bei HAT+ ist die automatische Erkennung
über die Firmware zugesichert.

---

## Weitere Ressourcen

- [Raspberry Pi Connector for PCIe](https://datasheets.raspberrypi.com/pcie/pcie-connector-standard.pdf)
- [Raspberry Pi M.2 HAT+ Product Brief](https://datasheets.raspberrypi.com/m2-hat-plus/raspberry-pi-m2-hat-plus-product-brief.pdf)
- [HAT+ Specification](https://datasheets.raspberrypi.com/hat/hat-plus-specification.pdf)
- [Produktzulassungen (PIP)](https://pip.raspberrypi.com)
