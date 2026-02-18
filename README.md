🌐 **English** | [Deutsch](README.de.md)

# Raspberry Pi AI Skill 🤖

**Claude AI Skill for Professional Raspberry Pi Development with Edge AI Integration**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-C51A4A?logo=raspberry-pi)](https://www.raspberrypi.com/)
[![Claude AI](https://img.shields.io/badge/Claude-AI%20Skill-5436DA)](https://www.anthropic.com/claude)

*Developed by Hayal*

---

## 📋 Overview

This Claude AI Skill supports the systematic development of robust, secure, and performant Raspberry Pi projects with a focus on Edge AI. It acts as a **Senior Embedded Systems Architect** and combines best practices from embedded systems, Linux administration, electrical engineering, and machine learning.

### 🎯 Key Features

- **Project Workflow**: Structured process from requirements analysis to deployment
- **Hardware Integration**: GPIO, I2C, SPI, cameras, sensors, HATs
- **Edge AI**: Ollama, Hailo-8L NPU, TensorFlow Lite
- **Systematic Debugging**: Isolation method, common pitfalls catalog, escalation paths
- **Safety**: Proactive validation of critical parameters (voltage, current, temperature)
- **Pi 5 Support**: Specific support for RP1 chip, PCIe Gen 3, Mini-CSI

## 🚀 Quick Start

### Installation in Claude

1. **Download the skill file:**
   - Download: [raspberry-pi-ai.skill](https://github.com/malkreide/raspberry-pi-ai-skill/releases/latest/download/raspberry-pi-ai.skill)

2. **Upload to Claude:**
   - Open [claude.ai](https://claude.ai)
   - Navigate to Settings → Skills
   - Click "Upload Skill"
   - Select `raspberry-pi-ai.skill`

3. **Activate the skill:**
   - The skill is now available in all conversations
   - Claude will automatically detect when it is relevant

### Usage

The skill is automatically activated when you say things like:

```
"I want to set up a Raspberry Pi 5 with a camera and Ollama"
"My GPIO sensor isn't working"
"How do I integrate the Hailo-8L NPU?"
"Create a build plan for an AI camera"
```

## 📚 Documentation

### Core Files

- **[SKILL.md](SKILL.md)** – Main skill definition with workflows and checklists
- **[debugging-playbook.md](debugging-playbook.md)** – Systematic debugging framework

### References

- **[hardware-specs.md](docs/hardware-specs.md)** – Raspberry Pi 4/5 specifications, GPIO pinouts, power budgets
- **[edge-ai.md](docs/edge-ai.md)** – Ollama, Hailo-8L, TFLite setup and best practices
- **[component-catalog.md](docs/component-catalog.md)** – Recommended components with suppliers

### Templates

- **[plan-template.md](templates/plan-template.md)** – Project build plan template

## 🛠️ Features in Detail

### Think-Hard Hierarchy

The skill adapts analysis depth to complexity:

| Level | Trigger | Action |
|-------|---------|--------|
| 1 | CLI commands, package management | Direct execution |
| 2 | Multi-component, sensor fusion | Create plan, check power/pins |
| 3 | Async, kernel, security | Analyze race conditions, memory leaks |
| 4 | NPU pipelines, quantization | Check tensor ops, bandwidth, thermal |

### Isolation Method

Core principle: **Never debug hardware and software at the same time.**

1. **Test hardware in isolation** → GPIO blink, I2C scan, camera test
2. **Test software in isolation** → Mock data, library imports
3. **Test the interface** → Permissions, device nodes, venv

### Safety Checklists

Proactive validation of critical parameters:

- ✅ 3.3V GPIO tolerance (no 5V signals!)
- ✅ Power budget: Pi + peripherals < 80% PSU capacity
- ✅ Thermal management: Active cooler for Pi 5
- ✅ Inductive loads: Flyback diodes for motors/relays

## 🎓 Developed for Education

This skill was developed by **Hayal** to:

- Support teachers integrating Raspberry Pi in their classrooms
- Guide students in learning embedded systems systematically
- Make best practices from professional embedded development accessible
- Bridge the gap between theory and practice

## 📖 Examples

### Example 1: GPIO LED Control

**User:** "Create a script that blinks an LED on GPIO17"

**Claude (with skill):**

```python
# Pre-Flight Check:
# - GPIO17 is free (not used by HAT)
# - LED + resistor dimensioned (220Ω for 3.3V)

from gpiozero import LED
from time import sleep

led = LED(17)

try:
    while True:
        led.on()
        sleep(1)
        led.off()
        sleep(1)
except KeyboardInterrupt:
    led.close()
```

### Example 2: Hailo-8L NPU Setup

**User:** "How do I install the Hailo-8L on the Pi 5?"

**Claude (with skill):**

1. Enable PCIe Gen 3 in `/boot/firmware/config.txt`
2. Mount active cooler (NPU + Pi 5 = ~15W additional load)
3. Install Hailo drivers
4. Set up thermal monitoring
5. Validate with `hailortcli fw-control identify`

*→ Details in [edge-ai.md](docs/edge-ai.md)*

## 🔧 Development

### Build Your Own .skill File

```bash
# Clone the repository
git clone https://github.com/malkreide/raspberry-pi-ai-skill.git
cd raspberry-pi-ai-skill

# Build the skill file
./scripts/build-skill.sh

# Output: raspberry-pi-ai.skill
```

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📊 Use Cases

### Education

- Computer science classes (secondary level)
- STEM programs
- Raspberry Pi workshops
- Maker projects

### Prototyping

- IoT proof-of-concepts
- Edge AI experiments
- Sensor networks
- Robotics projects

### Production (Limited)

- Embedded dashboards
- Data acquisition
- Local AI inference
- Monitoring systems

## ⚠️ Known Limitations

- **Pi 5 Mini-CSI:** Camera cable incompatibility with Pi 4 cables
- **PEP 668:** Bookworm blocks system-wide pip installs → use venv
- **RP1 Chip:** Older HATs/libraries may be incompatible
- **Thermal:** Pi 5 requires active cooler for sustained loads

## 📜 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

- **Development:** Hayal Oezkan
- **AI Framework:** Anthropic Claude
- **Hardware:** Raspberry Pi Foundation
- **Community:** Raspberry Pi Forums, GitHub Contributors

## 📞 Contact & Support

- **Issues:** [GitHub Issues](https://github.com/malkreide/raspberry-pi-ai-skill/issues)
- **Discussions:** [GitHub Discussions](https://github.com/malkreide/raspberry-pi-ai-skill/discussions)

---

**Made with ❤️ in Zürich**

[LinkedIn](https://www.linkedin.com/in/hayaloezkan/) • [Documentation](docs/) • [Contributing](CONTRIBUTING.md)
