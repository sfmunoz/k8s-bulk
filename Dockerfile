# Check 'README.md' for usage instructions

FROM debian:forky-20261005-slim

# make apt minimal by default, including for installs done at runtime
RUN printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' \
    > /etc/apt/apt.conf.d/99no-recommends

# systemd-standalone-sysusers satisfies openssh-client's sysusers dependency
# without dragging in the full systemd package
RUN apt-get update \
    && apt-get install -y ca-certificates curl git ripgrep fd-find sqlite3 zsh neovim tmux htop procps less python3 nodejs npm unzip openssh-client systemd-standalone-sysusers sudo \
    && rm -rf /var/lib/apt/lists/*

# zellij is not packaged in Debian testing: install the upstream static musl binary
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

ARG DESCRIPTION=
LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk
LABEL org.opencontainers.image.description="${DESCRIPTION}"

# oh-my-zsh: pinned commit, installed for root and seeded into /etc/skel so every
# user created below (and any user created at runtime) gets its own copy
ARG OMZ_COMMIT=964ddf789b022b6958b27d02d7fa54f552de21e9
RUN set -eux; \
    git init -q /root/.oh-my-zsh; \
    git -C /root/.oh-my-zsh remote add origin https://github.com/ohmyzsh/ohmyzsh.git; \
    git -C /root/.oh-my-zsh fetch -q --depth 1 origin "${OMZ_COMMIT}"; \
    git -C /root/.oh-my-zsh checkout -q -B master "${OMZ_COMMIT}"; \
    cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc; \
    sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="fino"/' /root/.zshrc; \
    grep -qxF 'ZSH_THEME="fino"' /root/.zshrc; \
    cp -a /root/.zshrc /etc/skel/.zshrc; \
    cp -al /root/.oh-my-zsh /etc/skel/.oh-my-zsh

# bulk is the runtime user: fixed numeric UID/GID (1000 is the first regular
# user on Debian) so Kubernetes can verify it with runAsNonRoot.
# after the labels, so a changing DESCRIPTION does not rebuild earlier layers
RUN groupadd --gid 1000 bulk \
    && useradd --uid 1000 --gid bulk --shell /usr/bin/zsh --create-home bulk \
    && usermod -s /usr/bin/zsh root \
    && printf 'bulk ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/bulk \
    && chmod 0440 /etc/sudoers.d/bulk \
    && visudo -c

# zsh is the default shell for interactive sessions
ENV SHELL=/usr/bin/zsh

# everything at runtime runs unprivileged; use 'docker run -u 0' when root is needed
USER 1000:1000
WORKDIR /home/bulk

CMD ["zsh", "-l"]
