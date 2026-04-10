#!/usr/bin/env bash
set -euo pipefail

REPO="CPU-JIA/huai-gpt"
DEFAULT_INSTALL_DIR="$HOME/huai-gpt"
DEFAULT_THREADS="20"
DEFAULT_CPA_BASE_URL="https://cpa.jia4u.de/_cpa-gateway"
DEFAULT_CPA_TOKEN="z_zZmdBGHgW03loh3UG5FGqtZCooHhBCZKN9r1aEVt0"
DEFAULT_MAIL_API_URL="https://email.jia4u.de"
DEFAULT_MAIL_API_KEY="tm_admin_5f1d664a997c53875172c615f94f5c913d60e8e39dad54d0"

INSTALL_DIR="$DEFAULT_INSTALL_DIR"
THREADS="$DEFAULT_THREADS"
START_BACKGROUND=1
CPA_BASE_URL="$DEFAULT_CPA_BASE_URL"
CPA_TOKEN="$DEFAULT_CPA_TOKEN"
MAIL_API_URL="$DEFAULT_MAIL_API_URL"
MAIL_API_KEY="$DEFAULT_MAIL_API_KEY"
PRIMARY_RATIO=""
SECONDARY_BASE_URL=""
SECONDARY_TOKEN=""
ALL_PRIMARY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="${2:-}"
      shift 2
      ;;
    --threads)
      THREADS="${2:-}"
      shift 2
      ;;
    --background)
      START_BACKGROUND=1
      shift
      ;;
    --no-start)
      START_BACKGROUND=0
      shift
      ;;
    --cpa-base-url)
      CPA_BASE_URL="${2:-}"
      shift 2
      ;;
    --cpa-token)
      CPA_TOKEN="${2:-}"
      shift 2
      ;;
    --primary-ratio)
      PRIMARY_RATIO="${2:-}"
      shift 2
      ;;
    --cpa-secondary-base-url)
      SECONDARY_BASE_URL="${2:-}"
      shift 2
      ;;
    --cpa-secondary-token)
      SECONDARY_TOKEN="${2:-}"
      shift 2
      ;;
    --all-primary)
      ALL_PRIMARY=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

OS="$(uname -s)"
ARCH="$(uname -m)"
if [[ "$OS" != "Linux" ]]; then
  echo "Only Linux installer is supported by this script for now." >&2
  exit 1
fi
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
  echo "Unsupported architecture: $ARCH" >&2
  exit 1
fi

ASSET_URL="https://github.com/$REPO/releases/latest/download/huai-gpt-linux-amd64.tar.gz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$INSTALL_DIR"
curl -fsSL "$ASSET_URL" -o "$TMP_DIR/huai-gpt-linux-amd64.tar.gz"
tar -xzf "$TMP_DIR/huai-gpt-linux-amd64.tar.gz" -C "$TMP_DIR"
SRC_DIR="$TMP_DIR/huai-gpt-linux-amd64"
cp -a "$SRC_DIR"/. "$INSTALL_DIR"/
chmod +x "$INSTALL_DIR/huai-gpt" "$INSTALL_DIR/huai-gpt.sh"

export INSTALL_DIR CPA_BASE_URL CPA_TOKEN MAIL_API_URL MAIL_API_KEY PRIMARY_RATIO SECONDARY_BASE_URL SECONDARY_TOKEN ALL_PRIMARY
python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path(os.environ["INSTALL_DIR"]) / "config.json"
cfg = json.loads(p.read_text(encoding="utf-8"))
cfg["cpa_upload_enabled"] = True
cfg["cpa_base_url"] = os.environ["CPA_BASE_URL"].rstrip("/")
cfg["cpa_api_key"] = os.environ["CPA_TOKEN"]
cfg["mail"]["api_base"] = os.environ["MAIL_API_URL"].rstrip("/")
cfg["mail"]["api_key"] = os.environ["MAIL_API_KEY"]
all_primary = os.environ.get("ALL_PRIMARY", "0") == "1"
secondary_url = os.environ.get("SECONDARY_BASE_URL", "").strip()
secondary_token = os.environ.get("SECONDARY_TOKEN", "").strip()
ratio = os.environ.get("PRIMARY_RATIO", "").strip()
if all_primary or not (secondary_url and secondary_token):
    cfg["cpa_secondary_enabled"] = False
    cfg["cpa_primary_ratio"] = 100
else:
    cfg["cpa_secondary_enabled"] = True
    cfg["cpa_secondary_base_url"] = secondary_url.rstrip("/")
    cfg["cpa_secondary_api_key"] = secondary_token
    cfg["cpa_primary_ratio"] = int(ratio or 70)
p.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"configured: {p}")
PY

if [[ "$START_BACKGROUND" == "1" ]]; then
  "$INSTALL_DIR/huai-gpt.sh" start "$THREADS"
else
  echo "installed to $INSTALL_DIR"
  echo "start manually: $INSTALL_DIR/huai-gpt.sh start $THREADS"
fi

echo "control script: $INSTALL_DIR/huai-gpt.sh"
echo "status: $INSTALL_DIR/huai-gpt.sh status"
echo "logs:   $INSTALL_DIR/huai-gpt.sh logs -f"
echo "cpa base: $CPA_BASE_URL"
if [[ "$ALL_PRIMARY" == "1" || -z "$SECONDARY_BASE_URL" || -z "$SECONDARY_TOKEN" ]]; then
  echo "upload routing: 100% primary"
else
  echo "upload routing: ${PRIMARY_RATIO:-70}% primary / $((100-${PRIMARY_RATIO:-70}))% secondary"
fi
