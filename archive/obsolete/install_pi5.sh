
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

TARGET_USER=${SUDO_USER:-$(id -un)}
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release python3 python3-venv python3-pip rclone

if ! command -v docker >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian     $(. /etc/os-release && echo $VERSION_CODENAME) stable" |     tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
fi

if ! getent group docker >/dev/null; then
  groupadd docker
fi
if ! id -nG "$TARGET_USER" | grep -qw docker; then
  usermod -aG docker "$TARGET_USER" || true
  ADDED_TO_DOCKER_GROUP=1
else
  ADDED_TO_DOCKER_GROUP=0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -f ".env.example" && ! -f ".env" ]]; then
  cp .env.example .env
fi

if [[ -f ".env" ]]; then
  if grep -q '^QDRANT_API_KEY=change-me' .env; then
    RAND=$(head -c 24 /dev/urandom | base64 | tr -d '=+/')
    sed -i "s|^QDRANT_API_KEY=change-me|QDRANT_API_KEY=${RAND}|" .env
  fi
fi

if [[ -f "docker-compose.yml" ]]; then
  docker compose --env-file .env up -d
fi

for i in {1..60}; do
  if curl -fsS http://127.0.0.1:6333/ -o /dev/null; then
    break
  fi
  sleep 2
done

if [[ -f "requirements.txt" ]]; then
  VENV=".venv"
  if [[ ! -d "$VENV" ]]; then
    python3 -m venv "$VENV"
  fi
  # shellcheck disable=SC1091
  source "$VENV/bin/activate"
  pip install --upgrade pip
  pip install -r requirements.txt
fi

if [[ -f ".env" ]]; then
  set +u
  # shellcheck disable=SC1091
  source .env
  set -u
  if [[ -n "${OPENAI_API_KEY:-}" && "$OPENAI_API_KEY" != "sk-..." ]]; then
    python -m src.ingest || true
    python -m src.query "smoketest escalation" || true
  fi
fi

if [[ -d "systemd" ]]; then
  install -m 0644 systemd/qdrant-snapshot-sync.service /etc/systemd/system/qdrant-snapshot-sync.service
  install -m 0644 systemd/qdrant-snapshot-sync.timer /etc/systemd/system/qdrant-snapshot-sync.timer
  systemctl daemon-reload
  if command -v rclone >/dev/null 2>&1; then
    REMOTES=$(rclone listremotes 2>/dev/null || true)
    if [[ -f ".env" ]]; then
      set +u
      # shellcheck disable=SC1091
      source .env
      set -u
    fi
    if [[ -n "${RCLONE_REMOTE:-}" && "$REMOTES" == *"${RCLONE_REMOTE%:}"* ]]; then
      systemctl enable --now qdrant-snapshot-sync.timer
    fi
  fi
fi

echo "Installation complete."
if [[ "${ADDED_TO_DOCKER_GROUP:-0}" -eq 1 ]]; then
  echo "User $TARGET_USER added to docker group. Log out and back in for group change to take effect."
fi
