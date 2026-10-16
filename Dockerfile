# Check 'README.md' for usage instructions

FROM debian:13.7-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates rclone curl sqlite3 zsh neovim tmux htop procps less python3 \
    && rm -rf /var/lib/apt/lists/*

# zsh is the login shell for root
RUN usermod -s /usr/bin/zsh root

# zellij is not packaged in Debian 13: install the upstream static musl binary
ARG ZELLIJ_VERSION=0.45.1
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
        amd64) zellij_arch=x86_64 ;; \
        arm64) zellij_arch=aarch64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}"; \
    curl -fsSLo /tmp/zellij.tar.gz "${base}/zellij-${zellij_arch}-unknown-linux-musl.tar.gz"; \
    curl -fsSLo /tmp/zellij.sha256sum "${base}/zellij-${zellij_arch}-unknown-linux-musl.sha256sum"; \
    tar -xzf /tmp/zellij.tar.gz -C /usr/local/bin zellij; \
    expected="$(awk '{print $1}' /tmp/zellij.sha256sum)"; \
    actual="$(sha256sum /usr/local/bin/zellij | awk '{print $1}')"; \
    [ "${expected}" = "${actual}" ]; \
    rm -f /tmp/zellij.tar.gz /tmp/zellij.sha256sum; \
    grep -qxF /usr/local/bin/zellij /etc/shells || echo /usr/local/bin/zellij >> /etc/shells; \
    zellij --version

# Debian 13 ships nodejs 20.19, which is out of support: install the current LTS
ARG NODE_VERSION=24.22.0
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
        amd64) node_arch=x64 ;; \
        arm64) node_arch=arm64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    base="https://nodejs.org/dist/v${NODE_VERSION}"; \
    node_tarball="node-v${NODE_VERSION}-linux-${node_arch}.tar.gz"; \
    curl -fsSLo /tmp/node.tar.gz "${base}/${node_tarball}"; \
    curl -fsSLo /tmp/node.sha256sum "${base}/SHASUMS256.txt"; \
    expected="$(awk -v f="${node_tarball}" '$2 == f {print $1}' /tmp/node.sha256sum)"; \
    actual="$(sha256sum /tmp/node.tar.gz | awk '{print $1}')"; \
    [ -n "${expected}" ]; \
    [ "${expected}" = "${actual}" ]; \
    tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1; \
    rm -f /tmp/node.tar.gz /tmp/node.sha256sum; \
    node --version; \
    npm --version

ARG DESCRIPTION=
LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk
LABEL org.opencontainers.image.description="${DESCRIPTION}"

# zsh is the default shell for interactive sessions
ENV SHELL=/usr/bin/zsh
CMD ["zsh", "-l"]
