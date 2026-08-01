#!/bin/bash

# Build Script für raspberry-pi-ai.skill
# Erstellt eine .skill-Datei (ZIP) aus den Markdown-Dokumenten.
#
# Paket-Layout (muss zu den Pfaden in SKILL.md passen):
#   raspberry-pi-ai/SKILL.md
#   raspberry-pi-ai/references/*.md
#   raspberry-pi-ai/assets/*.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
SKILL_NAME="raspberry-pi-ai"
OUTPUT_FILE="$PROJECT_ROOT/${SKILL_NAME}.skill"

# Quellpfade, die als references/ bzw. assets/ ins Paket wandern
REFERENCES=(
    "debugging-playbook.md"
    "docs/hardware-specs.md"
    "docs/mechanical.md"
    "docs/edge-ai.md"
    "docs/component-catalog.md"
)
ASSETS=(
    "templates/plan-template.md"
)

echo "🔨 Building ${SKILL_NAME}.skill..."
echo ""

# Aufräumen
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR/$SKILL_NAME/references" "$BUILD_DIR/$SKILL_NAME/assets"

# SKILL.md
echo "📄 Copying SKILL.md..."
if [ ! -f "$PROJECT_ROOT/SKILL.md" ]; then
    echo "❌ Error: SKILL.md not found in $PROJECT_ROOT!"
    exit 1
fi
cp "$PROJECT_ROOT/SKILL.md" "$BUILD_DIR/$SKILL_NAME/"

# Referenzen
echo "📚 Copying references..."
for src in "${REFERENCES[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$src" ]; then
        echo "❌ Error: reference '$src' not found!"
        exit 1
    fi
    cp "$PROJECT_ROOT/$src" "$BUILD_DIR/$SKILL_NAME/references/"
    echo "   → references/$(basename "$src")"
done

# Assets
echo "📎 Copying assets..."
for src in "${ASSETS[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$src" ]; then
        echo "❌ Error: asset '$src' not found!"
        exit 1
    fi
    cp "$PROJECT_ROOT/$src" "$BUILD_DIR/$SKILL_NAME/assets/"
    echo "   → assets/$(basename "$src")"
done

# Validierung: Verweist SKILL.md auf Dateien, die nicht im Paket liegen?
echo ""
echo "🔎 Validating references in SKILL.md..."
MISSING=0
while read -r ref; do
    [ -z "$ref" ] && continue
    rel="${ref#/mnt/skills/user/${SKILL_NAME}/}"
    if [ ! -f "$BUILD_DIR/$SKILL_NAME/$rel" ]; then
        echo "❌ SKILL.md verweist auf '$rel' – Datei fehlt im Paket."
        MISSING=1
    fi
done < <(grep -o "/mnt/skills/user/${SKILL_NAME}/[A-Za-z0-9_./-]*\.md" "$PROJECT_ROOT/SKILL.md" | sort -u)

if [ "$MISSING" -ne 0 ]; then
    echo ""
    echo "❌ Build abgebrochen: Referenzen unvollständig."
    rm -rf "$BUILD_DIR"
    exit 1
fi
echo "   ✓ Alle in SKILL.md referenzierten Dateien sind im Paket."

# ZIP erstellen
echo ""
echo "📦 Creating .skill archive..."
rm -f "$OUTPUT_FILE"
(cd "$BUILD_DIR" && zip -r "$OUTPUT_FILE" "$SKILL_NAME" > /dev/null)

# Aufräumen
rm -rf "$BUILD_DIR"

# Ergebnis
if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✅ Success!"
    echo "   Output: $OUTPUT_FILE"
    echo "   Size: $SIZE"
    echo ""
    echo "📂 Paketinhalt:"
    unzip -Z1 "$OUTPUT_FILE" | grep -v '/$' | sed 's/^/   /'
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
