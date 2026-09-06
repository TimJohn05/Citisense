#!/usr/bin/env bash
# ==============================================================================
# CitiSense Unified Project Manager
# Single CLI runner for App, ML/NLP pipeline, Testing, and Session Management.
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/citisense"
ML_DIR="$ROOT_DIR/ml"
PYTHON_BIN="$ML_DIR/.venv/bin/python"

# Bootstrap the ML venv on first use (uv-managed; pyproject.toml + uv.lock).
if [ ! -x "$PYTHON_BIN" ]; then
  (cd "$ML_DIR" && uv sync)
fi

# Text styles
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

function show_help() {
  echo -e "${BOLD}CitiSense Project Manager${RESET}"
  echo -e "Usage: ${CYAN}./manage.sh [command]${RESET}\n"
  echo -e "${BOLD}Session & Status:${RESET}"
  echo -e "  ${GREEN}status${RESET}         Print current session status, handoff notes, and git state"
  echo -e "  ${GREEN}check${RESET}          Run complete system health check (Flutter analyze + tests + ML verify)"
  echo ""
  echo -e "${BOLD}Flutter App:${RESET}"
  echo -e "  ${GREEN}app:run${RESET}        Run Flutter app locally on Linux desktop preview"
  echo -e "  ${GREEN}app:test${RESET}       Run Flutter test suite"
  echo -e "  ${GREEN}app:analyze${RESET}    Run Flutter static analysis"
  echo -e "  ${GREEN}app:build${RESET}      Build release APK and copy to ~/Desktop/CitiSense.apk"
  echo ""
  echo -e "${BOLD}Machine Learning & NLP:${RESET}"
  echo -e "  ${GREEN}ml:train${RESET}       Train and evaluate 11-category NLP models (Sentiment, Category, Urgency)"
  echo -e "  ${GREEN}ml:data${RESET}        Generate/augment 1,000 synthetic Taglish civic complaint samples"
  echo -e "  ${GREEN}ml:test${RESET}        Run interactive text prediction test in terminal"
  echo ""
  echo -e "${BOLD}Git & Maintenance:${RESET}"
  echo -e "  ${GREEN}git:status${RESET}     Show git status and changed files"
  echo ""
}

case "${1:-}" in
  status)
    bash "$ROOT_DIR/session-start.sh"
    ;;

  check)
    echo -e "\n${BOLD}${BLUE}=== 1. Checking Flutter Code Health ===${RESET}"
    (cd "$APP_DIR" && flutter analyze && flutter test)
    echo -e "\n${BOLD}${BLUE}=== 2. Checking ML Pipeline ===${RESET}"
    "$PYTHON_BIN" "$ML_DIR/train_model.py"
    echo -e "\n${BOLD}${GREEN}✓ All checks passed successfully!${RESET}\n"
    ;;

  app:run)
    echo -e "${CYAN}Launching CitiSense on Linux Desktop...${RESET}"
    (cd "$APP_DIR" && flutter run -d linux)
    ;;

  app:test)
    echo -e "${CYAN}Running Flutter unit & widget tests...${RESET}"
    (cd "$APP_DIR" && flutter test)
    ;;

  app:analyze)
    echo -e "${CYAN}Running Flutter static analysis...${RESET}"
    (cd "$APP_DIR" && flutter analyze)
    ;;

  app:build)
    echo -e "${CYAN}Building Android Release APK...${RESET}"
    (cd "$APP_DIR" && flutter build apk --release)
    if [ -f "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" ]; then
      cp "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" "$HOME/Desktop/CitiSense.apk"
      echo -e "${GREEN}✓ APK copied to ~/Desktop/CitiSense.apk for testing.${RESET}"
    fi
    ;;

  ml:train)
    echo -e "${CYAN}Training NLP models...${RESET}"
    "$PYTHON_BIN" "$ML_DIR/train_model.py"
    ;;

  ml:data)
    echo -e "${CYAN}Generating synthetic Taglish dataset...${RESET}"
    "$PYTHON_BIN" "$ML_DIR/generate_dataset.py"
    ;;

  ml:test)
    echo -e "${CYAN}Running interactive prediction test with TensorFlow...${RESET}"
    "$PYTHON_BIN" -c "
import os
import pickle
import numpy as np
import tensorflow as tf

models_dir = '$ML_DIR/saved_models'
sent_model = tf.keras.models.load_model(f'{models_dir}/sentiment_model.keras')
cat_model = tf.keras.models.load_model(f'{models_dir}/category_model.keras')
urg_model = tf.keras.models.load_model(f'{models_dir}/urgency_model.keras')

sent_enc = pickle.load(open(f'{models_dir}/sentiment_encoder.pkl', 'rb'))
cat_enc = pickle.load(open(f'{models_dir}/category_encoder.pkl', 'rb'))
urg_enc = pickle.load(open(f'{models_dir}/urgency_encoder.pkl', 'rb'))

def predict(model, enc, text):
    preds = model.predict(tf.constant([text], dtype=tf.string), verbose=0)[0]
    idx = np.argmax(preds)
    return enc.inverse_transform([idx])[0], preds[idx] * 100

print('\n=== CitiSense Taglish NLP Classifier ===')
while True:
    try:
        text = input('\nEnter Taglish complaint (or Ctrl+C to exit): ')
        if not text.strip(): continue
        cat, _ = predict(cat_model, cat_enc, text)
        sent, sent_conf = predict(sent_model, sent_enc, text)
        urg, _ = predict(urg_model, urg_enc, text)
        print(f'  → Category:  [{cat}]')
        print(f'  → Sentiment: [{sent}] ({sent_conf:.1f}% confidence)')
        print(f'  → Urgency:   [{urg}]')
    except (KeyboardInterrupt, EOFError):
        print('\nDone.')
        break
"
    ;;

  git:status)
    (cd "$ROOT_DIR" && git status)
    ;;

  *)
    show_help
    ;;
esac
