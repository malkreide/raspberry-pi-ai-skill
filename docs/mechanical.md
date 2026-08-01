# Mechanik, Montage & Gehäusedesign – Raspberry Pi 5

Grundlage dieser Referenz sind die offiziellen Raspberry-Pi-Dokumente:

| Dokument | Nummer | Inhalt |
|----------|--------|--------|
| Raspberry Pi 5 Product Brief | RP-008348-DS (April 2026) | Spezifikation, Umgebungsbedingungen, Sicherheitshinweise |
| Raspberry Pi 5 Mechanical Drawing | RP-008347-DS-1 | Platinenmasse, Bohrbild, Steckerpositionen, Höhenprofil |
| Raspberry Pi 5 Bumper Mechanical Drawing | RP-006237-DD-1 (Rev. 1, 28.06.2024) | Offizieller Bumper (Unterschale), Teil RP-006236-DD-1 |
| Raspberry Pi Case for Raspberry Pi 5 | RP-008159-DS-1 (April 2024) | Offizielles Gehäuse mit Aktivlüfter |

> ⚠️ **Verbindlichkeitshinweis (aus den Zeichnungen selbst):**
> Alle Masse sind Näherungswerte und dienen nur als Referenz. Sie dürfen **nicht** als
> Produktionsdaten verwendet werden, unterliegen Bauteil- und Fertigungstoleranzen und
> können sich ändern. Nicht alle Bauteile sind in den Zeichnungen dargestellt.
> Für Serienfertigung immer gegen ein physisches Board bzw. das aktuelle CAD-Modell von
> Raspberry Pi prüfen.

## Inhaltsverzeichnis
1. [Platinenmasse & Bohrbild](#platinenmasse--bohrbild)
2. [Steckerpositionen für Gehäuseausschnitte](#steckerpositionen-für-gehäuseausschnitte)
3. [Höhenprofil & Überstände](#höhenprofil--überstände)
4. [Offizieller Bumper](#offizieller-bumper)
5. [Offizielles Raspberry Pi Case](#offizielles-raspberry-pi-case)
6. [Stapelhöhen & HAT-Kompatibilität](#stapelhöhen--hat-kompatibilität)
6. [Umgebungsbedingungen & Gehäusebelüftung](#umgebungsbedingungen--gehäusebelüftung)
7. [Offizielle Sicherheits- und Handhabungshinweise](#offizielle-sicherheits--und-handhabungshinweise)
8. [Checkliste Gehäusedesign / 3D-Druck](#checkliste-gehäusedesign--3d-druck)
9. [Was die Zeichnungen NICHT enthalten](#was-die-zeichnungen-nicht-enthalten)

---

## Platinenmasse & Bohrbild

### Aussenmasse

| Mass | Wert |
|------|------|
| Länge (Anschlusskante) | **85 mm** |
| Breite | **56 mm** |
| Bohrbild-Raster | **58 mm × 49 mm** |
| Bohrungsdurchmesser | **Ø 2,7 mm** (4×, für M2.5) |
| Achsabstand Bohrung zur Kante | **3,5 mm** (beidseitig) |
| Zusatzbohrung | **Ø 3 mm** (nahe der rechten Befestigungsbohrung auf der GPIO-Seite) |

Das Raster 58 × 49 mm ist seit dem Modell B+ unverändert – Halterungen und Standoffs
für Pi 3B+/4B passen mechanisch auch auf den Pi 5.

### Bohrbild als Skizze

```
 Ursprung = untere linke Ecke der Platine, Blick von oben
 (40-Pin-Header oben, USB/Ethernet rechts)

   y
   ↑
56 ┌───────────────────────────────────────────────┐
   │  ○ (3.5, 52.5)                 ○ (61.5, 52.5) │ ← 40-Pin-Header
   │                                               │
   │                                               │
   │                                               │  → USB / Ethernet
   │                                               │     (rechts, ragen
   │  ○ (3.5,  3.5)                 ○ (61.5,  3.5) │      3 mm über)
 0 └───────────────────────────────────────────────┘
   0                                              85  → x
      ↑        ↑              ↑
    USB-C   HDMI 0         HDMI 1
    11.2     25.8           39.2

   Bohrungsraster:  Δx = 58 mm   Δy = 49 mm   Ø 2,7 mm
```

### Verschraubung

- **Schraube:** M2.5 (Ø 2,7 mm Bohrung)
- **Standoffs:** Nylon oder Messing; Metall-Standoffs nur mit Isolierscheibe, da rund um
  die Bohrungen Leiterbahnen und Bauteile liegen.
- **Anzugsmoment:** handfest. Zu hohes Moment verzieht die Platine und kann die
  Lötstellen der randnahen Buchsen belasten.

---

## Steckerpositionen für Gehäuseausschnitte

Alle Werte sind **Mittenmasse** aus der Zeichnung RP-008347-DS-1.

### Anschlusskante (Unterkante), gemessen ab linker Kante

| Anschluss | Mitte |
|-----------|-------|
| USB-C (Power, 5 V/5 A PD) | **11,2 mm** |
| Micro-HDMI 0 | **25,8 mm** |
| Micro-HDMI 1 | **39,2 mm** |

Weiteres Referenzmass dieser Kante: 29 mm ab linker Kante (siehe Zeichnung).

### Rechte Kante (USB/Ethernet), gemessen ab Unterkante

| Anschluss | Mitte |
|-----------|-------|
| Gigabit Ethernet (RJ45) | **10,2 mm** |
| USB-Doppelbuchse unten (USB 3.0) | **29,1 mm** |
| USB-Doppelbuchse oben (USB 3.0 / 2.0) | **47 mm** |

### Praxisregel für Ausschnitte

Ausschnitte mindestens **+0,5 mm pro Seite** gegenüber dem Nennmass ausführen. Die
Zeichnung nennt ausdrücklich Bauteil- und Fertigungstoleranzen; bei FDM-3D-Druck kommen
Schrumpf und Elefantenfuss dazu (praktisch eher **+0,8 bis +1,0 mm** pro Seite einplanen
und am Testdruck nachmessen).

---

## Höhenprofil & Überstände

### Überstand der Buchsen

| Mass | Wert |
|------|------|
| Überstand USB-/Ethernet-Buchsen über die 85-mm-Kante | **3 mm** |

➜ Der reale Platzbedarf in x-Richtung beträgt damit **88 mm**, nicht 85 mm. Das ist der
häufigste Fehler bei selbst konstruierten Gehäusen und Rack-Halterungen.

### Bauteilhöhen an der Anschlusskante (über der Leiterplattenoberseite)

| Bauteil | Höhe |
|---------|------|
| USB-C-Buchse | **3,2 mm** |
| Micro-HDMI-Buchsen | **3,4 mm** |
| Höchste Bauteile dieser Kante | **4,4 mm** |
| Weitere Bauteile | 4,1 mm |

Zusätzlich ist an der linken Kante ein Überstand von **0,45 mm** bemasst.

➜ Für eine Blende oder Frontplatte an der Anschlusskante gilt: die Öffnungen müssen
mindestens bis **4,4 mm über der Platinenoberseite** frei sein.

---

## Offizieller Bumper

Der Raspberry Pi 5 Bumper (Teil **RP-006236-DD-1**) ist eine aufsteckbare Unterschale aus
**TPE**, die die Platinenunterseite abdeckt und die Lötseite gegen leitfähige Oberflächen
isoliert. Sie liegt vielen Pi-5-Bundles bei und wird oft übersehen, obwohl sie die
Aussenmasse verändert.

### Masse

| Mass | Wert |
|------|------|
| Aussenmass | **89,6 mm × 60,6 mm** |
| Gesamthöhe (inkl. mittlerer Erhebung) | **7,0 mm** |
| Höhe am Rand | **5,1 mm** |
| Innenkontur | 84,3 mm / 84,7 mm × 55,6 mm / 56,2 mm |
| Wandstärke (Schnitt C-C) | **2,20 mm** |
| Dome/Randhöhe (Schnitte A-A / C-C) | 5,30 mm bzw. 5,55 mm |
| Auflagedome | Ø 2,80 mm typ., Höhe 4,30 mm / 3,80 mm typ. |
| Bohrbild der Dome | **58,00 mm × 49,00 mm** (deckungsgleich mit der Platine) |
| Weitere Masse | 54,1 mm, 10,0 mm, 11,3 mm, 2,20 mm |
| Material | **TPE** |

### Toleranzen laut Zeichnung

| Angabe | Toleranz |
|--------|----------|
| Linear, allgemein | ± 0,5 mm |
| Linear, 1 Nachkommastelle | ± 0,2 mm |
| Linear, 2 Nachkommastellen | ± 0,1 mm |
| Winkel | ± 0,5° |

### Konsequenzen für den Projektbau

1. **Gehäuseinnenmass:** Mit Bumper braucht der Pi **89,6 × 60,6 mm** statt 85 × 56 mm.
   Ein Gehäuse, das exakt auf die Platine ausgelegt ist, passt mit Bumper nicht mehr.
2. **Bauhöhe:** Der Bumper legt die Platine ca. **2,2 mm** höher (Wandstärke unter der
   Platine). Bei Frontplatten und Steckerausschnitten muss dieser Versatz eingerechnet
   werden, sonst sitzen USB-C und HDMI zu tief.
3. **HAT-Stacking:** Die Standard-Abstandshalter der HAT-Kits sind auf die nackte Platine
   ausgelegt. Bei aufgestecktem Bumper stimmen weder Schraubenlänge noch
   Header-Eingriffstiefe – **Bumper vor der HAT-Montage entfernen** oder längere
   Standoffs verwenden.
4. **Thermik:** TPE ist ein Isolator. Der Bumper behindert die Wärmeabgabe nach unten;
   bei Dauerlast (Hailo, Ollama) ist der Active Cooler damit noch wichtiger.
5. **Nicht mit Kühlkörper-Cases kombinieren:** Alu-Gehäuse (Flirc, Argon) setzen auf der
   nackten Platine auf.

---

## Offizielles Raspberry Pi Case

Quelle: **Raspberry Pi Case for Raspberry Pi 5, RP-008159-DS-1 (April 2024)**.

Vierteiliges Klickgehäuse (Basis, Rahmen, Deckel, Lüftereinheit) mit integriertem,
temperaturgeregeltem Lüfter.

| Eigenschaft | Wert |
|-------------|------|
| **Aussenmasse** | **98,5 × 70,3 × 33 mm** |
| Material | ABS (Basis, Rahmen, Deckel), PC (Lüftereinheit) |
| Lüfter-Versorgung | 5 V über den **4-Pin-FAN-Header** des Pi 5 |
| Lüfterregelung | PWM mit Tachosignal |
| Max. Luftstrom | **2,79 CFM** |
| Max. Drehzahl | **8000 U/min ± 15 %** |
| Kühlkörper | **12 × 17 × 4 mm**, selbstklebend, auf den CPU-Absatz |
| Zubehör | vier Silikonfüsse |
| Produktionszusage | mindestens bis **Januar 2036** |

### Was das Gehäuse kann – und was nicht

- **Deckel abnehmbar:** legt Lüfter, Montagepunkte und einen Durchbruch für Kabel
  (u.a. GPIO) frei. Ein Flachbandkabel nach aussen ist also vorgesehen.
- **Stapelbar:** Montagepunkte in der transparenten Lüfterabdeckung und auf der
  Unterseite der Basis erlauben, mehrere Gehäuse zu stapeln.
- **HATs möglich, aber nicht ohne Zukauf:** Nur mit **Abstandshaltern und
  GPIO-Header-Verlängerungen**, die *nicht* im Lieferumfang sind.
- **Lüftereinheit entnehmbar:** Die Lüftereinheit lässt sich aus dem weissen Rahmen
  ausklipsen, wenn das Gehäuse ohne Lüfter genutzt werden soll.
- **Power-Button** des Gehäuses bedient den Power-Button des Pi 5.
- **Für M.2:** Dafür gibt es den **M.2 HAT+ Compact**, der den Gehäuselüfter frei lässt –
  unterstützt aber nur 2230. Siehe `pcie.md`.

### Montagehinweise aus der Anleitung

1. Kühlkörper auf den erhöhten Abschnitt der CPU kleben und **andrücken**.
2. Die Platine sitzt **unter der Kunststofflasche an der SD-Karten-Seite**. Sie muss flach
   in der Basis liegen und die Anschlüsse müssen zu den Öffnungen fluchten.
3. **Beim Anschluss des Lüfterkabels auf die Steckrichtung achten** – der Stecker muss
   richtig herum in den mit `FAN` beschrifteten 4-Pin-Anschluss.
4. Lüfterkabel vollständig einstecken.

### Warnungen

- **Nur für den Raspberry Pi 5.**
- Nur in gut belüfteter Umgebung betreiben, das Gehäuse **nicht abdecken**.
- Keine Feuchtigkeit, keine leitfähige Unterlage im Betrieb, keine externe Wärmequelle.
- **Den Lüfter im Betrieb nicht berühren.**

---

## Stapelhöhen & HAT-Kompatibilität

Die mechanische Zeichnung liefert die Basiswerte, aus denen sich der Platzbedarf ergibt:

```
Aufbau von unten nach oben (x-y-Fussabdruck):

  Bumper (optional)      89,6 × 60,6 mm    +2,2 mm unter der Platine
  Pi 5 Platine           85 × 56 mm        (Buchsen +3 mm nach rechts → 88 mm)
  Bauteile Oberseite     max. 4,4 mm an der Anschlusskante
  40-Pin-Header          Standoffs des HAT-Kits massgebend
  HAT / Active Cooler    herstellerabhängig
```

### Regeln

- **Fussabdruck immer mit 88 × 56 mm rechnen** (Buchsenüberstand), mit Bumper
  **89,6 × 60,6 mm**.
- **M.2 HAT+ (Hailo, NVMe):** Belegt den 40-Pin-Header mechanisch und blockiert
  GPIO-Zugriff. Für Audio deshalb USB statt I2S-HAT planen (siehe `component-catalog.md`).
  Abmessungen: 65 × 56,5 mm (Standard), Bohrbild 58 × 49 mm wie beim Pi.
- **Active Cooler + M.2 HAT+ Standard:** Kein Konflikt – der beiliegende **16-mm-Stacking-Header**
  ist genau dafür bemessen, dass der HAT über dem montierten Active Cooler sitzt.
  Bei HATs von Drittanbietern dagegen die Bauhöhe prüfen, viele kollidieren mit dem
  Lüfterkörper.
- **Offizielles Gehäuse:** Dafür gibt es den **M.2 HAT+ Compact** (L-förmig, bis 71,5 mm
  breit), der den integrierten Gehäuselüfter frei lässt – unterstützt aber nur 2230.
- **PCIe-FFC:** Maximal 50 mm lang. Im Gehäuse einen Kabelweg vorsehen, der ohne
  Verlängerung auskommt. Details: `pcie.md`.
- **Kamerakabel:** Die 22-Pin-FFC-Kabel des Pi 5 haben einen engen Biegeradius. Im
  Gehäuse mindestens 10 mm Kabelweg vorsehen, sonst reisst die Zugentlastung des
  Steckers.

---

## Umgebungsbedingungen & Gehäusebelüftung

### Offizielle Werte aus dem Product Brief

| Parameter | Wert |
|-----------|------|
| **Betriebstemperatur (Umgebung)** | **0 °C bis 70 °C** |
| MTBF (Ground Benign) | **93 800 Stunden** (≈ 10,7 Jahre) |
| Produktionszusage | mindestens bis **Januar 2036** |

⚠️ **Zubehör kann diese Grenze senken.** Der M.2 HAT+ ist nur für **0–50 °C** spezifiziert.
Für das Gesamtsystem gilt immer die niedrigste Grenze aller verbauten Komponenten –
ein Pi 5 mit M.2 HAT+ ist ein 0–50-°C-System. Siehe `pcie.md`.

> **Wichtige Unterscheidung:** Die 0–70 °C sind die zulässige **Umgebungstemperatur**.
> Die in `hardware-specs.md` genannten 80/85 °C sind die **SoC-Sperrschichttemperaturen**,
> ab denen gedrosselt wird. Beide Grenzen müssen eingehalten werden – ein Gehäuse in
> praller Sonne kann die Umgebungsgrenze reissen, lange bevor `vcgencmd measure_temp`
> auffällig wird.

### Konsequenzen für Projekte

- **Aussenprojekte:** Unter 0 °C ist der Pi 5 ausserhalb der Spezifikation. Für
  Wetterstationen im Winter Gehäuseheizung, Innenaufstellung oder ein anderes Board
  einplanen; ausserdem Kondenswasser berücksichtigen.
- **Geschlossene Gehäuse:** Die Innentemperatur liegt bei Volllast deutlich über der
  Raumtemperatur. Bei 25 °C Raumtemperatur und einem dichten Gehäuse sind 45–55 °C innen
  realistisch – das Budget bis 70 °C ist schneller aufgebraucht als erwartet.
- **Langzeitprojekte:** MTBF und Produktionszusage bis 2036 sind belastbare Argumente für
  Beschaffungen im Schul- und Verwaltungsumfeld (Ersatzteilversorgung, Abschreibungsdauer).

---

## Offizielle Sicherheits- und Handhabungshinweise

Direkt aus dem Product Brief – diese Punkte gehören in jede Projektdokumentation:

**Warnungen**
- Das Produkt in einer **gut belüfteten Umgebung** betreiben. Wird ein Gehäuse verwendet,
  darf dieses **nicht abgedeckt** werden.
- Im Betrieb sicher befestigen oder auf eine **stabile, ebene, nicht leitfähige**
  Unterlage legen; kein Kontakt mit leitfähigen Gegenständen.
- Der Anschluss **inkompatibler Geräte** kann die Konformität beeinträchtigen, das Board
  beschädigen und die Garantie erlöschen lassen.
- Alle Peripheriegeräte müssen den Normen des Einsatzlandes entsprechen und
  entsprechend gekennzeichnet sein.

**Sicherheitshinweise**
- Nicht Wasser oder Feuchtigkeit aussetzen; im Betrieb nicht auf leitfähige Oberflächen
  legen.
- Keiner externen Wärmequelle aussetzen.
- Kühl und trocken lagern.
- Beim Handhaben mechanische und elektrische Beschädigung von Platine und Steckern
  vermeiden.
- **Im Betrieb die Platine nicht berühren** bzw. nur an den Kanten anfassen (ESD-Schutz).

**Konformität:** Vollständige Liste der lokalen und regionalen Produktzulassungen unter
[pip.raspberrypi.com](https://pip.raspberrypi.com).

---

## Checkliste Gehäusedesign / 3D-Druck

- [ ] Innenmass ≥ **88 × 56 mm** (Platine inkl. 3 mm Buchsenüberstand)
- [ ] Mit Bumper: Innenmass ≥ **89,6 × 60,6 mm**
- [ ] Bohrbild **58 × 49 mm**, Ø 2,7 mm, 3,5 mm von den Kanten
- [ ] Standoffs isolierend oder mit Isolierscheibe
- [ ] Ausschnitte Anschlusskante: USB-C 11,2 mm / HDMI 0 25,8 mm / HDMI 1 39,2 mm ab links
- [ ] Ausschnitte rechte Kante: Ethernet 10,2 mm / USB 29,1 mm / USB 47 mm ab unten
- [ ] Ausschnitthöhe an der Anschlusskante ≥ 4,4 mm über der Platinenoberseite
- [ ] Toleranzzugabe +0,5 mm (Spritzguss) bzw. +0,8–1,0 mm (FDM) pro Seite
- [ ] Lüftungsöffnungen vorhanden, Gehäuse nicht abgedeckt (offizielle Warnung)
- [ ] Luftweg für Active Cooler frei (Ansaugung oben, Auslass seitlich)
- [ ] Umgebungstemperatur im Betrieb bleibt in 0–70 °C
- [ ] Kabelweg für 22-Pin-FFC ≥ 10 mm Biegeradius
- [ ] Zugentlastung für USB-C-Kabel (5 A PD, steife Leitung)
- [ ] Material nicht leitfähig; keine Metallspäne aus der Nachbearbeitung im Gehäuse

---

## Was die Zeichnungen NICHT enthalten

Diese Werte sind in RP-008347-DS-1 und RP-006237-DD-1 **nicht** bemasst und müssen am
physischen Board oder beim Zubehörhersteller ermittelt werden:

- Leiterplattendicke
- Höhe des 40-Pin-Headers und der Bauteile auf der Platinenoberseite ausserhalb der
  Anschlusskante
- Höhe und Fussabdruck des Active Coolers
- Position und Höhe des Lüfter-Anschlusses sowie des PoE+-Headers
- Höhe der Bauteile auf der Platinenunterseite (Micro-SD-Slot)
- Gewicht

➜ Wenn ein Projekt auf einen dieser Werte angewiesen ist: **nachmessen und den Messwert
im `plan.md` dokumentieren**, nicht schätzen.

---

## Weitere Ressourcen

- [Raspberry Pi 5 Product Brief](https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-product-brief.pdf)
- [Raspberry Pi 5 Mechanical Drawing](https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-mechanical-drawing.pdf)
- [Raspberry Pi 5 Bumper Mechanical Drawing](https://datasheets.raspberrypi.com/case/raspberry-pi-5-bumper-mechanical-drawing.pdf)
- [Produktzulassungen (PIP)](https://pip.raspberrypi.com)
- [Raspberry Pi Documentation – Hardware](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)
