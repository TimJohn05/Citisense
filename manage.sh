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
    echo -e "${CYAN}Running interactive prediction test...${RESET}"
    "$PYTHON_BIN" -c "
import pickle
sent = pickle.load(open('$ML_DIR/saved_models/sentiment_model.pkl', 'rb'))
cat = pickle.load(open('$ML_DIR/saved_models/category_model.pkl', 'rb'))
urg = pickle.load(open('$ML_DIR/saved_models/urgency_model.pkl', 'rb'))

while True:
    try:
        text = input('\nEnter Taglish complaint (or Ctrl+C to exit): ')
        if not text.strip(): continue
        print(f'  Category:  [{cat.predict([text])[0]}]')
        print(f'  Sentiment: [{sent.predict([text])[0]}]')
        print(f'  Urgency:   [{urg.predict([text])[0]}]')
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
