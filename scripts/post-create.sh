#!/usr/bin/env bash
set -euo pipefail

export PATH="/home/vscode/.opencode/bin:/home/vscode/.bun/bin:/home/vscode/.local/bin:$PATH"

WORKSPACE="/workspaces/openagent-devcontainer"

# --- Git credential helper ---
# Use GITHUB_TOKEN directly so git push/pull always uses the repo-owner account
# (bird70) regardless of which gh account is active for Copilot.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  git config --global --replace-all credential.https://github.com.helper \
    "!f() { echo username=x-access-token; echo password=${GITHUB_TOKEN}; }; f"
  git config --global --replace-all credential.https://gist.github.com.helper \
    "!f() { echo username=x-access-token; echo password=${GITHUB_TOKEN}; }; f"
else
  # Fallback: use gh CLI credential helper (works in local dev without GITHUB_TOKEN)
  gh_bin="$(which gh 2>/dev/null || true)"
  if [[ -n "$gh_bin" ]]; then
    git config --global --replace-all credential.https://github.com.helper "${gh_bin} auth git-credential"
    git config --global --replace-all credential.https://gist.github.com.helper "${gh_bin} auth git-credential"
  fi
fi

# --- GitHub Copilot auth ---
# Log gh CLI in as the Copilot-capable account (niwacolours, has Claude models).
# COPILOT_GITHUB_TOKEN should be a PAT for tilmann.steinmetz@niwa.co.nz with
# the 'copilot' scope.  Falls back to GITHUB_TOKEN if not set.
_copilot_token="${COPILOT_GITHUB_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -n "$_copilot_token" ]]; then
  echo "$_copilot_token" | gh auth login --hostname github.com --with-token 2>/dev/null || true
fi
unset _copilot_token

# --- Python venv ---
uv venv --allow-existing "${WORKSPACE}/venv"

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
# Also reinstall if the baked-in binary can't execute (e.g. musl binary on glibc host).
if command -v opencode >/dev/null 2>&1 && ! opencode --version >/dev/null 2>&1; then
  echo "opencode binary is present but cannot execute — reinstalling correct variant..."
  rm -f "$(command -v opencode)"
  hash -d opencode 2>/dev/null || true  # clear bash's command path cache
fi
OMO_INSTALL_OPENCODE_IF_MISSING=1 bash "${WORKSPACE}/scripts/bootstrap-oh-my-openagent.sh" || true

# Deploy the versioned Copilot-only model config (overwrite what bootstrap wrote)
mkdir -p ~/.config/opencode "${WORKSPACE}/.opencode"
cp "${WORKSPACE}/.devcontainer/oh-my-openagent.json" ~/.config/opencode/oh-my-openagent.json
cp "${WORKSPACE}/.devcontainer/oh-my-openagent.json" "${WORKSPACE}/.opencode/oh-my-openagent.json"

# Refresh model cache (opencode must be on PATH)
opencode models --refresh || true
