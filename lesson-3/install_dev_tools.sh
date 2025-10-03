#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="install.log"
PY_MIN_VER=3.9

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

version_ge() {
  # Порівняння версій: 1 якщо $1 >= $2
  printf '%s\n%s\n' "$2" "$1" | sort -C -V
}

log "Початок встановлення інструментів..."

# Docker
if command_exists docker; then
  log "Docker вже встановлено: $(docker --version)"
else
  log "Docker не знайдено. Спроба встановлення..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    log "macOS: встановіть Docker Desktop вручну: https://docs.docker.com/desktop/"
  else
    if command_exists apt-get; then
      sudo apt-get update -y
      sudo apt-get install -y ca-certificates curl gnupg
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update -y
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo usermod -aG docker "$USER" || true
    else
      log "Невідома ОС. Встановіть Docker вручну."
    fi
  fi
fi

# Docker Compose
if command_exists docker && docker compose version >/dev/null 2>&1; then
  log "Docker Compose (v2) доступний: $(docker compose version)"
else
  if command_exists docker-compose; then
    log "docker-compose (v1) встановлено: $(docker-compose --version)"
  else
    log "Docker Compose не знайдено. На нових системах іде разом з Docker (docker compose)."
  fi
fi

# Python
if command_exists python3; then
  PY_VER=$(python3 -c 'import sys; print("%d.%d"%sys.version_info[:2])')
  if version_ge "$PY_VER" "$PY_MIN_VER"; then
    log "Python3 вже встановлено: $PY_VER"
  else
    log "Python3 версія $PY_VER < $PY_MIN_VER. Спроба оновлення..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      log "macOS: встановіть Python через Homebrew: brew install python@3.11"
    elif command_exists apt-get; then
      sudo apt-get update -y && sudo apt-get install -y python3 python3-pip
    else
      log "Встановіть Python вручну (pyenv або пакетний менеджер)."
    fi
  fi
else
  log "Python3 не знайдено. Встановлюю..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    log "macOS: brew install python"
  elif command_exists apt-get; then
    sudo apt-get update -y && sudo apt-get install -y python3 python3-pip
  else
    log "Встановіть Python вручну."
  fi
fi

# pip
if command_exists pip3; then
  log "pip3: $(pip3 --version)"
else
  log "pip3 не знайдено. Встановлюю..."
  if command_exists apt-get; then
    sudo apt-get install -y python3-pip
  else
    python3 -m ensurepip --upgrade || true
  fi
fi

# Python пакети
ensure_pkg() {
  local pkg="$1"; shift
  if python3 - <<PY 2>/dev/null; then
import importlib; import sys
sys.exit(0 if importlib.util.find_spec("$pkg") else 1)
PY
  then
    log "Python пакет '$pkg' вже встановлено"
  else
    log "Встановлюю пакет '$pkg'..."
    pip3 install "$pkg" "$@"
  fi
}

# Встановлюємо ML-бібліотеки (CPU)
ensure_pkg pillow
# PyTorch + torchvision (CPU index)
pip3 install --upgrade --index-url https://download.pytorch.org/whl/cpu torch torchvision || true

# Django (за вимогою перевірки)
ensure_pkg django

# Перевірка версій
log "Перевірка версій після встановлення:"
command -v docker >/dev/null 2>&1 && docker --version | tee -a "$LOG_FILE" || true
command -v docker-compose >/dev/null 2>&1 && docker-compose --version | tee -a "$LOG_FILE" || true
command -v python3 >/dev/null 2>&1 && python3 --version | tee -a "$LOG_FILE" || true
command -v pip3 >/dev/null 2>&1 && pip3 --version | tee -a "$LOG_FILE" || true
python3 -c "import django,torch,torchvision,PIL; print('django', django.get_version()); print('torch', torch.__version__); print('torchvision', torchvision.__version__); import PIL; print('Pillow', PIL.__version__)" 2>/dev/null | tee -a "$LOG_FILE" || true

log "Готово. Можливо, потрібен relogin для групи docker."

