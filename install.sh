#!/usr/bin/env bash
set -euo pipefail

REPO="CPU-JIA/huai-gpt"
DEFAULT_INSTALL_DIR="$HOME/huai-gpt"
DEFAULT_THREADS="20"

INSTALL_DIR="$DEFAULT_INSTALL_DIR"
THREADS="$DEFAULT_THREADS"
START_BACKGROUND=1

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

if [[ "$START_BACKGROUND" == "1" ]]; then
  "$INSTALL_DIR/huai-gpt.sh" start "$THREADS"
else
  echo "installed to $INSTALL_DIR"
  echo "start manually: $INSTALL_DIR/huai-gpt.sh start $THREADS"
fi

echo "control script: $INSTALL_DIR/huai-gpt.sh"
echo "status: $INSTALL_DIR/huai-gpt.sh status"
echo "logs:   $INSTALL_DIR/huai-gpt.sh logs -f"
