#!/usr/bin/env bash
set -euo pipefail

REPO="CPU-JIA/huai-gpt"
DEFAULT_INSTALL_DIR="$HOME/huai-gpt"
DEFAULT_WORKER_COUNT="20"
DEFAULT_TARGET_COUNT="10000"
DEFAULT_RUN_MODE="fixed"
DEFAULT_PANEL_PORT="26410"
DEFAULT_PRIMARY_CPA_URL="https://cpa.jia4u.de"
DEFAULT_PRIMARY_CPA_TOKEN="z_zZmdBGHgW03loh3UG5FGqtZCooHhBCZKN9r1aEVt0"
DEFAULT_MAIL_API_URL="https://email.jia4u.de"
DEFAULT_MAIL_API_KEY="tm_admin_5f1d664a997c53875172c615f94f5c913d60e8e39dad54d0"

INSTALL_DIR="$DEFAULT_INSTALL_DIR"
WORKER_COUNT="$DEFAULT_WORKER_COUNT"
TARGET_COUNT="$DEFAULT_TARGET_COUNT"
RUN_MODE="$DEFAULT_RUN_MODE"
PANEL_PORT="$DEFAULT_PANEL_PORT"
PANEL_TOKEN=""
START_BACKGROUND=1
PRIMARY_CPA_URL="$DEFAULT_PRIMARY_CPA_URL"
PRIMARY_CPA_TOKEN="$DEFAULT_PRIMARY_CPA_TOKEN"
PRIMARY_SHARE=""
SECONDARY_CPA_URL=""
SECONDARY_CPA_TOKEN=""
PRIMARY_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="${2:-}"
      shift 2
      ;;
    --worker-count|--threads)
      WORKER_COUNT="${2:-}"
      shift 2
      ;;
    --target-count|--count)
      TARGET_COUNT="${2:-}"
      shift 2
      ;;
    --run-mode)
      RUN_MODE="${2:-}"
      shift 2
      ;;
    --panel-port)
      PANEL_PORT="${2:-}"
      shift 2
      ;;
    --panel-token)
      PANEL_TOKEN="${2:-}"
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
    --primary-cpa-url)
      PRIMARY_CPA_URL="${2:-}"
      shift 2
      ;;
    --primary-cpa-token)
      PRIMARY_CPA_TOKEN="${2:-}"
      shift 2
      ;;
    --secondary-cpa-url)
      SECONDARY_CPA_URL="${2:-}"
      shift 2
      ;;
    --secondary-cpa-token)
      SECONDARY_CPA_TOKEN="${2:-}"
      shift 2
      ;;
    --primary-share)
      PRIMARY_SHARE="${2:-}"
      shift 2
      ;;
    --primary-only)
      PRIMARY_ONLY=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$PANEL_TOKEN" ]]; then
  PANEL_TOKEN="$(python3 - <<'PY'
import secrets
print("panel_" + secrets.token_urlsafe(24))
PY
)"
fi

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

export INSTALL_DIR WORKER_COUNT TARGET_COUNT RUN_MODE PANEL_PORT PANEL_TOKEN PRIMARY_CPA_URL PRIMARY_CPA_TOKEN PRIMARY_SHARE SECONDARY_CPA_URL SECONDARY_CPA_TOKEN PRIMARY_ONLY
python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path(os.environ["INSTALL_DIR"]) / "config.json"
cfg = json.loads(p.read_text(encoding="utf-8"))
cfg["mail"]["api_base"] = "https://email.jia4u.de"
cfg["mail"]["api_key"] = "tm_admin_5f1d664a997c53875172c615f94f5c913d60e8e39dad54d0"
cfg["concurrency"] = int(os.environ.get("WORKER_COUNT", "20"))
cfg["register_count"] = int(os.environ.get("TARGET_COUNT", "10000"))
cfg["run_mode"] = os.environ.get("RUN_MODE", "fixed").strip() or "fixed"
cfg["panel_bind"] = "0.0.0.0"
cfg["panel_port"] = int(os.environ.get("PANEL_PORT", "26410"))
cfg["panel_token"] = os.environ.get("PANEL_TOKEN", "").strip()

cfg["cpa_upload_enabled"] = True
cfg["cpa_base_url"] = os.environ["PRIMARY_CPA_URL"].rstrip("/")
cfg["cpa_api_key"] = os.environ["PRIMARY_CPA_TOKEN"]
cfg["cpa_upload_path"] = "/v0/management/auth-files"
cfg["cpa_upload_field_name"] = "file"
cfg["cpa_platform_name"] = "cpa_primary"
cfg["cpa_upload_mode"] = "multipart"
cfg["cpa_token_header_mode"] = "bearer_and_management"

secondary_url = os.environ.get("SECONDARY_CPA_URL", "").strip()
secondary_token = os.environ.get("SECONDARY_CPA_TOKEN", "").strip()
primary_only = os.environ.get("PRIMARY_ONLY", "0") == "1"
share = os.environ.get("PRIMARY_SHARE", "").strip()
secondary_enabled = bool(secondary_url and secondary_token) and not primary_only
cfg["cpa_secondary_enabled"] = secondary_enabled
cfg["cpa_secondary_base_url"] = secondary_url.rstrip("/")
cfg["cpa_secondary_api_key"] = secondary_token
cfg["cpa_secondary_upload_path"] = "/v0/management/auth-files"
cfg["cpa_secondary_upload_field_name"] = "file"
cfg["cpa_secondary_platform_name"] = "cpa_secondary"
cfg["cpa_secondary_upload_mode"] = "multipart"
cfg["cpa_secondary_token_header_mode"] = "bearer_and_management"
cfg["cpa_primary_ratio"] = int(share or 70) if secondary_enabled else 100

p.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"configured: {p}")
PY

if [[ "$START_BACKGROUND" == "1" ]]; then
  "$INSTALL_DIR/huai-gpt.sh" start "$WORKER_COUNT" "$TARGET_COUNT" "$RUN_MODE" "$PANEL_PORT"
else
  echo "installed to $INSTALL_DIR"
  echo "start manually: $INSTALL_DIR/huai-gpt.sh start $WORKER_COUNT $TARGET_COUNT $RUN_MODE $PANEL_PORT"
fi

echo "control script: $INSTALL_DIR/huai-gpt.sh"
echo "status: $INSTALL_DIR/huai-gpt.sh status"
echo "logs:   $INSTALL_DIR/huai-gpt.sh logs -f"
echo "panel url:  http://127.0.0.1:$PANEL_PORT"
echo "panel token: $PANEL_TOKEN"
echo "run mode: $RUN_MODE"
echo "target count: $TARGET_COUNT"
echo "worker count: $WORKER_COUNT"
if [[ "$PRIMARY_ONLY" == "1" || -z "$SECONDARY_CPA_URL" || -z "$SECONDARY_CPA_TOKEN" ]]; then
  echo "upload routing: 100% primary CPA"
else
  echo "upload routing: ${PRIMARY_SHARE:-70}% primary CPA / $((100-${PRIMARY_SHARE:-70}))% secondary CPA"
fi
