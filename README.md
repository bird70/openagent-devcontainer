# Oh My OpenAgent Secure Dev Container

This workspace is a container-first environment for using [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) safely while developing other projects.

## Security posture

The container is intentionally narrow:

- only the selected workspace folder is bind-mounted
- OpenCode config and cache live in named Docker volumes, not in the host home directory
- telemetry is disabled by default
- the container drops Linux capabilities and enables `no-new-privileges`
- there is no Docker socket mount and no privileged mode

## What is included

- Bun for the `oh-my-opencode` CLI
- common development tools like `git`, `rg`, `fd`, `jq`, and `procps`
- a bootstrap script that installs `oh-my-openagent` inside the container

## How to use

1. Open this folder in VS Code.
2. Reopen in Container.
3. On first open, the bootstrap script checks for OpenCode and then configures `oh-my-openagent`.
4. By default, if OpenCode is missing, bootstrap exits cleanly and prints next steps.
5. Optional: set `OMO_INSTALL_OPENCODE_IF_MISSING=1` in `.devcontainer/devcontainer.json` to auto-install OpenCode during post-create.
6. After OpenCode is installed, rerun `scripts/bootstrap-oh-my-openagent.sh` or run `bunx oh-my-opencode doctor`.

## Notes

The repo’s install flow expects OpenCode to exist before full verification. This container keeps the plugin setup isolated, but it does not reach into your host system to install or modify OpenCode outside the dev environment.

## Installation flow source

The bootstrap script follows the oh-my-openagent installation guide:

- https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/refs/heads/dev/docs/guide/installation.md
