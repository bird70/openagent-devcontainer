FROM mcr.microsoft.com/devcontainers/python:3.13-bookworm

ARG USERNAME=vscode

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (Python dev tools already in base image)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  fd-find \
  git \
  jq \
  socat \
  bubblewrap \
  less \
  procps \
  ripgrep \
  bubblewrap \
  socat \
  unzip \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

ENV BUN_INSTALL=/home/${USERNAME}/.bun
ENV PATH=${BUN_INSTALL}/bin:${PATH}

# Install Bun from official GitHub release
RUN BUN_VERSION="1.3.14" && \
  curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" -o /tmp/bun.zip && \
  unzip -q /tmp/bun.zip -d /tmp/bun-extract && \
  mkdir -p ${BUN_INSTALL}/bin && \
  mv /tmp/bun-extract/bun-linux-x64/bun ${BUN_INSTALL}/bin/bun && \
  chmod +x ${BUN_INSTALL}/bin/bun && \
  rm -rf /tmp/bun.zip /tmp/bun-extract

# Symlink bun as 'node' for Node.js script compatibility
RUN ln -sf ${BUN_INSTALL}/bin/bun ${BUN_INSTALL}/bin/node

# Add ~/.local/bin to PATH for uv-managed tools
ENV PATH=/home/${USERNAME}/.local/bin:${PATH}

# Install uv from official GitHub release
RUN UV_VERSION="0.11.18" && \
  curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz" -o /tmp/uv.tar.gz && \
  tar -xzf /tmp/uv.tar.gz -C /tmp && \
  mkdir -p /home/${USERNAME}/.local/bin && \
  mv /tmp/uv-x86_64-unknown-linux-gnu/uv /home/${USERNAME}/.local/bin/uv && \
  mv /tmp/uv-x86_64-unknown-linux-gnu/uvx /home/${USERNAME}/.local/bin/uvx && \
  chmod +x /home/${USERNAME}/.local/bin/uv /home/${USERNAME}/.local/bin/uvx && \
  rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-gnu

# Install Opencode
RUN OPENCODE_VERSION="1.14.20" && \
  curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64-baseline.tar.gz" -o /tmp/opencode.tar.gz && \
  tar -xzf /tmp/opencode.tar.gz -C /tmp && \
  mv /tmp/opencode /home/${USERNAME}/.local/bin/opencode && \
  chmod +x /home/${USERNAME}/.local/bin/opencode && \
  rm -f /tmp/opencode.tar.gz

# Install LSP servers globally via npm/bun
RUN bun install -g \
  vscode-json-languageserver \
  yaml-language-server \
  bash-language-server \
  dockerfile-language-server-nodejs \
  typescript \
  typescript-language-server \
  pyright

# Install Python LSP server globally via uv tool
RUN uv tool install python-lsp-server

WORKDIR /workspaces
