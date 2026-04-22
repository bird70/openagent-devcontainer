FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG USERNAME=vscode

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  fd-find \
  git \
  jq \
  less \
  procps \
  ripgrep \
  unzip \
  python3.11 \
  python3-pip \
  python3.11-venv && \
  update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
  update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 && \
  ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
  rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

ENV BUN_INSTALL=/home/${USERNAME}/.bun
ENV PATH=${BUN_INSTALL}/bin:${PATH}

RUN curl -fsSL https://bun.sh/install | bash

# Symlink bun as 'node' so Node.js scripts (e.g. opencode) work without a full Node install
RUN ln -sf ${BUN_INSTALL}/bin/bun ${BUN_INSTALL}/bin/node

# Add ~/.local/bin to PATH for uv-managed tools
ENV PATH=/home/${USERNAME}/.local/bin:${PATH}

# Install uv (fast Python package/venv manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install TypeScript LSP via bun
RUN bun install -g \
  typescript \
  typescript-language-server

# Install Python LSP server globally via uv tool
RUN uv tool install python-lsp-server

WORKDIR /workspaces
