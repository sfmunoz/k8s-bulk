# Check 'README.md' for usage instructions

FROM debian:13.7-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates rclone curl sqlite3 zsh neovim tmux htop procps \
    && rm -rf /var/lib/apt/lists/*

ARG DESCRIPTION=
LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk
LABEL org.opencontainers.image.description="${DESCRIPTION}"

CMD ["bash"]
