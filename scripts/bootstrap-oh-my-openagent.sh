#!/usr/bin/env bash

set -euo pipefail

export OMO_DISABLE_POSTHOG=1
export OMO_SEND_ANONYMOUS_TELEMETRY=0
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/vscode-cache}"

mkdir -p "$XDG_CACHE_HOME/opencode"

if ! command -v bunx >/dev/null 2>&1; then
  echo "bunx is not available in the container."
  exit 1
fi

if ! command -v opencode >/dev/null 2>&1; then
  if [[ "${OMO_INSTALL_OPENCODE_IF_MISSING:-0}" == "1" ]]; then
    echo "OpenCode is not installed. Installing from https://opencode.ai/install ..."
    curl -fsSL https://opencode.ai/install | bash
  else
    echo "OpenCode is not installed in this container yet."
    echo "Set OMO_INSTALL_OPENCODE_IF_MISSING=1 to auto-install on postCreate,"
    echo "or install manually via https://opencode.ai/docs and rerun this script."
    exit 0
  fi
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "OpenCode still not found on PATH after attempted install."
  echo "Install manually via https://opencode.ai/docs and rerun this script."
  exit 0
fi

if ! bunx oh-my-opencode install \
  --no-tui \
  --claude=no \
  --openai=no \
  --gemini=no \
  --copilot=no \
  --opencode-go=no \
  --opencode-zen=no \
  --zai-coding-plan=no \
  --kimi-for-coding=no \
  --vercel-ai-gateway=no \
  --skip-auth; then
  echo "oh-my-opencode installation failed."
  echo "You can rerun this script after checking network/auth requirements."
  exit 0
fi

bunx oh-my-opencode doctor || true
