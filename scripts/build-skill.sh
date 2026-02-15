#!/bin/bash

# Build Script für raspberry-pi-ai.skill
# Erstellt eine .skill-Datei (ZIP) aus den Markdown-Dokumenten

set -e  # Exit bei Fehler

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
SKILL_NAME="raspberry-pi-ai"
OUTPUT_FILE="$PROJECT_ROOT/${SKILL_NAME}.skill"

echo "🔨 Building ${SKILL_NAME}.skill..."
echo ""

# Aufräumen
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR/$SKILL_NAME"

# Kern-Dateien kopieren
echo "📄 Copying core files..."
cp "$PROJECT_ROOT/SKILL.md" "$BUILD_DIR/$SKILL_NAME/"
cp "$PROJECT_ROOT/debugging-playbook.md" "$BUILD_DIR/$SKILL_NAME/"

# Prüfen ob Dateien existieren
if [ ! -f "$BUILD_DIR/$SKILL_NAME/SKILL.md" ]; then
    echo "❌ Error: SKILL.md not found!"
    exit 1
fi

if [ ! -f "$BUILD_DIR/$SKILL_NAME/debugging-playbook.md" ]; then
    echo "❌ Error: debugging-playbook.md not found!"
    exit 1
fi

# ZIP erstellen
echo "📦 Creating .skill archive..."
cd "$BUILD_DIR"
zip -r "$OUTPUT_FILE" "$SKILL_NAME" > /dev/null

# Aufräumen
cd "$PROJECT_ROOT"
rm -rf "$BUILD_DIR"

# Validierung
if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✅ Success!"
    echo "   Output: $OUTPUT_FILE"
    echo "   Size: $SIZE"
    echo ""
    echo "📤 Upload to Claude:"
    echo "   1. Open https://claude.ai"
    echo "   2. Go to Settings → Skills"
    echo "   3. Click 'Upload Skill'"
    echo "   4. Select $OUTPUT_FILE"
else
    echo "❌ Error: Build failed!"
    exit 1
fi
