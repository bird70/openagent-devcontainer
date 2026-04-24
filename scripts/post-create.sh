#!/usr/bin/env bash
set -euo pipefail

export PATH="/home/vscode/.opencode/bin:/home/vscode/.bun/bin:/home/vscode/.local/bin:$PATH"

# Resolve workspace dynamically so this script works after repo folder renames.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Git credential helper ---
# Use GITHUB_TOKEN directly so git push/pull always uses the repo-owner account
# (bird70) regardless of which gh account is active for Copilot.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  # Use single quotes so $GITHUB_TOKEN is evaluated at credential-request time,
  # not hardcoded at post-create time.  This way a refreshed token works without
  # re-running post-create.sh.
  git config --global --replace-all credential.https://github.com.helper \
    '!f() { echo username=x-access-token; echo password=$GITHUB_TOKEN; }; f'
  git config --global --replace-all credential.https://gist.github.com.helper \
    '!f() { echo username=x-access-token; echo password=$GITHUB_TOKEN; }; f'
else
  # Fallback: use gh CLI credential helper (works in local dev without GITHUB_TOKEN)
  gh_bin="$(which gh 2>/dev/null || true)"
  if [[ -n "$gh_bin" ]]; then
    git config --global --replace-all credential.https://github.com.helper "${gh_bin} auth git-credential"
    git config --global --replace-all credential.https://gist.github.com.helper "${gh_bin} auth git-credential"
  fi
fi

# --- GitHub Copilot auth ---
# Copilot requires an OAuth token (not a PAT) — only interactive gh auth login
# creates one.  We check if any active gh account has Copilot access by probing
# the Copilot models endpoint; if not, we print a one-time setup reminder.
# The Copilot account with Claude model access must be logged in via the device flow.
# Run once in a terminal after container creation:
#   gh auth login --hostname github.com   # follow the device flow, select your Copilot-enabled account
if ! gh api /copilot_internal/v2/token --silent >/dev/null 2>&1; then
  cat <<'EOF'

  ┌─────────────────────────────────────────────────────────────────────────┐
  │  GitHub Copilot login required (one-time setup)                         │
  │                                                                         │
  │  PATs cannot be used for Copilot — an OAuth session is needed.          │
  │  Run the following in a terminal, then reopen opencode:                 │
  │                                                                         │
  │    gh auth login --hostname github.com                                  │
  │                                                                         │
  │  Sign in with your GitHub Copilot-enabled account.                      │
  │  This grants Claude opus/sonnet model access via GitHub Copilot.        │
  └─────────────────────────────────────────────────────────────────────────┘

EOF
fi

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

# Ensure the github-copilot provider is declared in opencode.json so opencode
# picks up the gh CLI OAuth token automatically (no API key required).
_oc_cfg=~/.config/opencode/opencode.json
if [[ -f "$_oc_cfg" ]]; then
  python3 - "$_oc_cfg" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
if 'provider' not in cfg:
    cfg['provider'] = {}
cfg['provider']['github-copilot'] = cfg['provider'].get('github-copilot', {})
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
PYEOF
fi
unset _oc_cfg

# Refresh model cache (opencode must be on PATH)
opencode models --refresh || true
