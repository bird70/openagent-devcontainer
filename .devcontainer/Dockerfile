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
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

ENV BUN_INSTALL=/home/${USERNAME}/.bun
ENV PATH=${BUN_INSTALL}/bin:${PATH}

RUN curl -fsSL https://bun.sh/install | bash

WORKDIR /workspaces
