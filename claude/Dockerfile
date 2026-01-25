FROM debian:bookworm-slim

ARG UID=501
ARG GID=20

RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create user with matching UID/GID
RUN groupadd -g $GID claude || true \
    && useradd -m -u $UID -g $GID claude

USER claude

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/claude/.local/bin:$PATH"

WORKDIR /workspace

ENTRYPOINT ["claude"]
