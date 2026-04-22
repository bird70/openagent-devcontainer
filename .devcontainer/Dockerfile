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

# Install Bun from the official GitHub release (avoids curl|bash at runtime)
RUN BUN_VERSION="1.2.13" && \
  curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" -o /tmp/bun.zip && \
  unzip -q /tmp/bun.zip -d /tmp/bun-extract && \
  mkdir -p ${BUN_INSTALL}/bin && \
  mv /tmp/bun-extract/bun-linux-x64/bun ${BUN_INSTALL}/bin/bun && \
  chmod +x ${BUN_INSTALL}/bin/bun && \
  rm -rf /tmp/bun.zip /tmp/bun-extract

# Symlink bun as 'node' so Node.js scripts work without a full Node install
RUN ln -sf ${BUN_INSTALL}/bin/bun ${BUN_INSTALL}/bin/node

# Add ~/.local/bin to PATH for uv-managed tools
ENV PATH=/home/${USERNAME}/.local/bin:${PATH}

# Install uv from the official GitHub release (avoids curl|bash at runtime)
RUN UV_VERSION="0.11.7" && \
  curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz" -o /tmp/uv.tar.gz && \
  tar -xzf /tmp/uv.tar.gz -C /tmp && \
  mkdir -p /home/${USERNAME}/.local/bin && \
  mv /tmp/uv-x86_64-unknown-linux-gnu/uv /home/${USERNAME}/.local/bin/uv && \
  mv /tmp/uv-x86_64-unknown-linux-gnu/uvx /home/${USERNAME}/.local/bin/uvx && \
  chmod +x /home/${USERNAME}/.local/bin/uv /home/${USERNAME}/.local/bin/uvx && \
  rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-gnu

# Install opencode from the official GitHub release (baked into image, avoids runtime curl|bash)
RUN OPENCODE_VERSION="1.14.20" && \
  curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64-baseline-musl.tar.gz" -o /tmp/opencode.tar.gz && \
  tar -xzf /tmp/opencode.tar.gz -C /tmp && \
  mv /tmp/opencode /home/${USERNAME}/.local/bin/opencode && \
  chmod +x /home/${USERNAME}/.local/bin/opencode && \
  rm -f /tmp/opencode.tar.gz

# Install TypeScript LSP via bun
RUN bun install -g \
  typescript \
  typescript-language-server

# Install Python LSP server globally via uv tool
RUN uv tool install python-lsp-server

WORKDIR /workspaces
