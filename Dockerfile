FROM debian:forky-20261005-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git ripgrep fd-find sqlite3 zsh neovim tmux htop procps less python3 nodejs npm unzip \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -s /usr/bin/zsh root

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

# rclone is not packaged in Debian testing (forky): install the upstream static binary
ARG RCLONE_VERSION=1.69.3
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
        amd64) rclone_arch=amd64 ;; \
        arm64) rclone_arch=arm64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    base="https://downloads.rclone.org/v${RCLONE_VERSION}"; \
    rclone_zip="rclone-v${RCLONE_VERSION}-linux-${rclone_arch}.zip"; \
    curl -fsSLo /tmp/rclone.zip "${base}/${rclone_zip}"; \
    curl -fsSLo /tmp/rclone.sha256sum "${base}/SHA256SUMS"; \
    expected="$(awk -v f="${rclone_zip}" '$2 == f {print $1}' /tmp/rclone.sha256sum)"; \
    actual="$(sha256sum /tmp/rclone.zip | awk '{print $1}')"; \
    [ -n "${expected}" ]; \
    [ "${expected}" = "${actual}" ]; \
    unzip -j -o /tmp/rclone.zip "*/rclone" -d /usr/local/bin; \
    rm -f /tmp/rclone.zip /tmp/rclone.sha256sum; \
    env -u RCLONE_VERSION rclone version

ENV SHELL=/usr/bin/zsh
CMD ["zsh", "-l"]
