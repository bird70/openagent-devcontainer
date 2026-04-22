#!/usr/bin/env bash
set -euo pipefail

export PATH="/home/vscode/.opencode/bin:/home/vscode/.bun/bin:/home/vscode/.local/bin:$PATH"

WORKSPACE="/workspaces/openagent-devcontainer"

# --- Git credential helper ---
# Override the Windows gh.exe credential helper (from host .gitconfig) with
# the in-container gh CLI so pushes work as the correct GitHub account.
gh_bin="$(which gh 2>/dev/null || true)"
if [[ -n "$gh_bin" ]]; then
  git config --global credential.https://github.com.helper ""
  git config --global --add credential.https://github.com.helper "${gh_bin} auth git-credential"
  git config --global credential.https://gist.github.com.helper ""
  git config --global --add credential.https://gist.github.com.helper "${gh_bin} auth git-credential"
fi

# --- Python venv ---
uv venv "${WORKSPACE}/venv"

if [[ -f "${WORKSPACE}/requirements.txt" ]]; then
  uv pip install -r "${WORKSPACE}/requirements.txt"
  uv pip install pip-audit
  pip-audit || true
fi

# Auto-activate venv in new terminals (idempotent)
if ! grep -q "venv/bin/activate" ~/.bashrc 2>/dev/null; then
  echo "source ${WORKSPACE}/venv/bin/activate 2>/dev/null || true" >> ~/.bashrc
fi

# --- Oh-My-OpenAgent / OpenCode bootstrap ---
# opencode is baked into the image; bootstrap will detect it and skip install.
# OMO_INSTALL_OPENCODE_IF_MISSING=1 is kept as a fallback for local dev builds
# that don't use the devcontainer image.
OMO_INSTALL_OPENCODE_IF_MISSING=1 bash "${WORKSPACE}/scripts/bootstrap-oh-my-openagent.sh" || true

# Deploy the versioned Copilot-only model config (overwrite what bootstrap wrote)
mkdir -p ~/.config/opencode "${WORKSPACE}/.opencode"
cp "${WORKSPACE}/.devcontainer/oh-my-openagent.json" ~/.config/opencode/oh-my-openagent.json
cp "${WORKSPACE}/.devcontainer/oh-my-openagent.json" "${WORKSPACE}/.opencode/oh-my-openagent.json"

# Refresh model cache (opencode must be on PATH)
opencode models --refresh || true
