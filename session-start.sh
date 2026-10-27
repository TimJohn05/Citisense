#!/usr/bin/env bash
# CitiSense session bootstrap — prints current state from the Obsidian memory vault.
# Usage: bash ~/SE2-Project/session-start.sh   (or place it on your PATH)

set -euo pipefail

VAULT="$HOME/Documents/MindMap/MindMap/SE-Mindmap"

echo "=============================================================="
echo " CitiSense — session bootstrap"
echo "=============================================================="
echo ""

if [[ ! -d "$VAULT" ]]; then
  echo "ERROR: Obsidian vault not found at $VAULT"
  exit 1
fi

echo "--- HANDOFF (read this first) ---------------------------------"
if [[ -f "$VAULT/Handoff.md" ]]; then
  cat "$VAULT/Handoff.md"
else
  echo "Missing: Handoff.md"
fi

echo ""
echo "--- PROJECT CONTEXT (CitiSense.md) ----------------------------"
if [[ -f "$VAULT/CitiSense.md" ]]; then
  cat "$VAULT/CitiSense.md"
else
  echo "Missing: CitiSense.md"
fi

echo ""
echo "--- DESIGN SYSTEM (Design-System.md) ---------------------------"
if [[ -f "$VAULT/Design-System.md" ]]; then
  cat "$VAULT/Design-System.md"
fi

echo ""
echo "--- GIT / CODE STATE -------------------------------------------"
if [[ -d "$HOME/SE2-Project/.git" ]]; then
  (cd "$HOME/SE2-Project" && git log --oneline -5 2>/dev/null || true)
fi

echo ""
echo "================================================================="
echo " Next: cd ~/SE2-Project/citisense && flutter analyze"
echo "================================================================="
