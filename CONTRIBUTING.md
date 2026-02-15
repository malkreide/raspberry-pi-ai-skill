# Beitragen zum Raspberry Pi AI Skill

Vielen Dank für dein Interesse, zum Raspberry Pi AI Skill beizutragen! Dieses Dokument enthält Richtlinien für Beiträge.

## 🤝 Wie kann ich beitragen?

### Fehler melden

Wenn du einen Fehler findest:

1. **Prüfe**, ob der Fehler bereits [gemeldet wurde](https://github.com/malkreide/raspberry-pi-ai-skill/issues)
2. **Erstelle** ein neues Issue mit dem Template "Bug Report"
3. **Beschreibe** das Problem so detailliert wie möglich:
   - Raspberry Pi Modell und OS-Version
   - Vollständige Fehlermeldung
   - Schritte zur Reproduktion
   - Erwartetes vs. tatsächliches Verhalten

### Features vorschlagen

Für neue Funktionen oder Verbesserungen:

1. **Erstelle** ein Issue mit dem Template "Feature Request"
2. **Erkläre** den Use Case und den Mehrwert
3. **Diskutiere** mit der Community über die Implementierung

### Dokumentation verbessern

Dokumentation ist genauso wichtig wie Code:

- Tippfehler korrigieren
- Unklare Abschnitte verbessern
- Neue Beispiele hinzufügen
- Tutorials erweitern

### Code beitragen

1. **Fork** das Repository
2. **Erstelle** einen Feature-Branch (`git checkout -b feature/neue-funktion`)
3. **Mache** deine Änderungen
4. **Teste** deine Änderungen gründlich
5. **Commit** mit aussagekräftiger Nachricht
6. **Push** zu deinem Fork
7. **Erstelle** einen Pull Request

## 📝 Coding-Standards

### Markdown

- Verwende Schweizer Rechtschreibung (ß → ss, etc.)
- Halte Zeilen auf ~100 Zeichen (für bessere Lesbarkeit)
- Verwende aussagekräftige Überschriften
- Füge Code-Beispiele in Fenced Code Blocks ein

### Beispiele

- Alle Code-Beispiele müssen auf Raspberry Pi 4/5 getestet sein
- Verwende `gpiozero` statt `RPi.GPIO`
- Kommentiere komplexe Abschnitte
- Gib Strombudgets und Sicherheitshinweise an

### Stil

```markdown
# Gutes Beispiel

## GPIO LED-Steuerung

**Hardware:**
- Raspberry Pi 5 (4 GB)
- LED + 220Ω Vorwiderstand
- Jumper Wires

**Code:**
```python
from gpiozero import LED
from time import sleep

led = LED(17)  # GPIO 17 verwenden

try:
    while True:
        led.on()
        sleep(1)
        led.off()
        sleep(1)
except KeyboardInterrupt:
    led.close()
```

**Sicherheitshinweise:**
- ⚠️ Max. 16 mA pro GPIO-Pin
- Vorwiderstand obligatorisch (220Ω bei 3.3V)
```

## 🧪 Testing

### Vor dem Pull Request

Stelle sicher, dass:

- [ ] Alle Markdown-Links funktionieren
- [ ] Code-Beispiele auf Pi 4 oder Pi 5 getestet wurden
- [ ] Keine Tippfehler vorhanden sind
- [ ] Sicherheitshinweise vorhanden sind (wo relevant)
- [ ] Schweizer Rechtschreibung verwendet wird

### Testing-Tools

```bash
# Markdown-Linting (optional)
npm install -g markdownlint-cli
markdownlint *.md docs/*.md

# Link-Checking (optional)
npm install -g markdown-link-check
markdown-link-check README.md
```

## 🌳 Branch-Strategie

- `main` – Stabile Version, immer deploybar
- `develop` – Entwicklungs-Branch (optional)
- `feature/*` – Feature-Branches
- `fix/*` – Bugfix-Branches
- `docs/*` – Dokumentations-Branches

## 💬 Commit-Messages

Verwende aussagekräftige Commit-Messages:

```
✅ Gut:
"Füge Hailo-8L Troubleshooting-Abschnitt hinzu"
"Korrigiere GPIO-Pinout-Tabelle für Pi 5"
"Update Ollama Performance-Benchmarks"

❌ Schlecht:
"Update"
"Fix"
"Changes"
```

### Format

```
<typ>: <kurze Beschreibung>

[Optionale ausführliche Beschreibung]

[Optionale Referenzen zu Issues]
```

**Typen:**
- `feat:` – Neues Feature
- `fix:` – Bugfix
- `docs:` – Dokumentation
- `style:` – Formatierung
- `refactor:` – Code-Umstrukturierung
- `test:` – Tests
- `chore:` – Wartung

## 🔍 Review-Prozess

1. **Pull Request** wird erstellt
2. **Automatische Checks** laufen (wenn konfiguriert)
3. **Code Review** durch Maintainer
4. **Diskussion** und ggf. Anpassungen
5. **Merge** in `main`

### Was wir prüfen

- Korrektheit der technischen Informationen
- Schweizer Rechtschreibung
- Vollständigkeit der Sicherheitshinweise
- Konsistenz mit bestehendem Content
- Qualität der Code-Beispiele

## 🎯 Prioritäten

### Hohe Priorität

- Fehlerkorrekturen
- Sicherheits-Updates
- Pi 5-spezifische Dokumentation
- Hailo-8L Integration

### Mittlere Priorität

- Neue Sensoren/Aktoren
- Erweiterte Beispiele
- Performance-Optimierungen

### Niedrige Priorität

- Kosmetische Änderungen
- Nice-to-have Features

## 🏆 Anerkennung

Alle Contributors werden in der [README.md](README.md) aufgeführt. Grössere Beiträge werden speziell hervorgehoben.

## 📧 Fragen?

- **Allgemeine Fragen:** [GitHub Discussions](https://github.com/malkreide/raspberry-pi-ai-skill/discussions)
- **Bugs:** [GitHub Issues](https://github.com/malkreide/raspberry-pi-ai-skill/issues)
- **Direkter Kontakt:** [E-Mail einfügen]

## 📄 Lizenz

Durch Beiträge stimmst du zu, dass deine Arbeit unter der [MIT License](LICENSE) lizenziert wird.

---

**Vielen Dank fürs Beitragen! 🙏**
