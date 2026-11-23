# Check 'README.md' for usage instructions

FROM debian:forky-20261104-slim

# make apt minimal by default, including for installs done at runtime
RUN printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' \
    > /etc/apt/apt.conf.d/99no-recommends

# Packages are installed in three groups, most stable first: a change to a group
# only invalidates that group's layer and the ones below it.
# 'ping' is the first diagnostic anyone reaches for when a container "has no network";
# curl/getent only answer DNS and TCP, not ICMP. Debian's iputils-ping ships no file
# capability, so 'ping' only works where net.ipv4.ping_group_range is wide open (Docker's
# default); in a pod (default '1 0') it fails as a non-root user. Set the capability
# explicitly: libcap2-bin stays for getcap at runtime.
# 'inetutils-telnet' provides 'telnet' (the 'telnet' package is an empty dummy):
# client only, and only good for "does this TCP port answer".
# 'tini' is PID 1 (see ENTRYPOINT below): no Docker '--init' and no Kubernetes
# equivalent exist, so the reaper has to ship in the image.
RUN apt-get update \
    && apt-get install -y ca-certificates curl iputils-ping libcap2-bin inetutils-telnet git openssh-client unzip bzip2 less procps sudo systemd-standalone-sysusers tini \
    && setcap cap_net_raw+ep /usr/bin/ping \
    && getcap /usr/bin/ping | grep -qx '/usr/bin/ping cap_net_raw=ep' \
    && ping -c1 -W1 127.0.0.1 \
    && telnet --help | grep -q '^Usage: telnet' \
    && tini --version \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y python3 nodejs npm python3-venv \
    && rm -rf /var/lib/apt/lists/*

# shell, editor and interactive tools: the most likely to be dropped
RUN apt-get update \
    && apt-get install -y zsh neovim tmux htop ripgrep fd-find sqlite3 rsync \
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

# restic is no longer in Debian testing (forky): it was removed on 2026-11-10 and
# 0.20.0-1 stays blocked in unstable, so install the upstream release instead.
ARG RESTIC_VERSION=0.20.0
ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
        amd64) restic_arch=amd64 ;; \
        arm64) restic_arch=arm64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}"; \
    restic_bz2="restic_${RESTIC_VERSION}_linux_${restic_arch}.bz2"; \
    curl -fsSLo "/tmp/${restic_bz2}" "${base}/${restic_bz2}"; \
    curl -fsSLo /tmp/restic.sha256sum "${base}/SHA256SUMS"; \
    expected="$(awk -v f="${restic_bz2}" '$2 == f {print $1}' /tmp/restic.sha256sum)"; \
    actual="$(sha256sum "/tmp/${restic_bz2}" | awk '{print $1}')"; \
    [ -n "${expected}" ]; \
    [ "${expected}" = "${actual}" ]; \
    bunzip2 -c "/tmp/${restic_bz2}" > /usr/local/bin/restic; \
    rm -f "/tmp/${restic_bz2}" /tmp/restic.sha256sum; \
    chmod 0755 /usr/local/bin/restic; \
    env -u RESTIC_VERSION restic version

ARG DESCRIPTION=
LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk
LABEL org.opencontainers.image.description="${DESCRIPTION}"

# user config: oh-my-zsh (pinned commit) and npm prefix seeded into /etc/skel so
# every user created below (and any user created at runtime) gets its own copy
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
    printf 'prefix=${HOME}/.npm-global\n' > /etc/skel/.npmrc; \
    printf '\n# npm -g installs into $HOME\nexport PATH="$HOME/.npm-global/bin:$PATH"\n' >> /etc/skel/.zshrc; \
    cp -al /root/.oh-my-zsh /etc/skel/.oh-my-zsh

# zellij config (pinned commit) seeded into /etc/skel, so zellij starts with the
# same keybindings/layouts for every user instead of its built-in defaults; only
# the config itself is seeded, not the repo's LICENSE/README
ARG ZELLIJ_CONFIG_COMMIT=7af5add6785c7ad2eb1bc50835cbbb1cba852192
RUN set -eux; \
    git init -q /tmp/zellij-config; \
    git -C /tmp/zellij-config remote add origin https://github.com/sfmunoz/zellij-config.git; \
    git -C /tmp/zellij-config fetch -q --depth 1 origin "${ZELLIJ_CONFIG_COMMIT}"; \
    git -C /tmp/zellij-config checkout -q -B main "${ZELLIJ_CONFIG_COMMIT}"; \
    install -d -m 0755 /etc/skel/.config/zellij/layouts; \
    install -m 0644 /tmp/zellij-config/config.kdl /etc/skel/.config/zellij/config.kdl; \
    install -m 0644 /tmp/zellij-config/layouts/default.kdl /etc/skel/.config/zellij/layouts/default.kdl; \
    rm -rf /tmp/zellij-config; \
    test -s /etc/skel/.config/zellij/config.kdl; \
    test -s /etc/skel/.config/zellij/layouts/default.kdl; \
    env -u ZELLIJ_CONFIG_COMMIT HOME=/etc/skel zellij setup --check \
    | tee /tmp/zellij-check.out; \
    grep -qxF '[CONFIG DIR]: "/etc/skel/.config/zellij"' /tmp/zellij-check.out; \
    grep -qxF '[CONFIG FILE]: Well defined.' /tmp/zellij-check.out; \
    rm -f /tmp/zellij-check.out

# '/bin/sh' -> bash: Debian points it to dash, which lacks bashisms such as '$RANDOM'
# and silently degrades instead of failing. 'bash' is already in the base image.
RUN ln -sf bash /bin/sh \
    && [ "$(readlink -f /bin/sh)" = /usr/bin/bash ] \
    && [ "$(/bin/sh -c 'echo {1..3}')" = "1 2 3" ]

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

# tini as PID 1: reaps orphans reparented to PID 1 and, with '-g' (tini >= 0.19),
# forwards SIGTERM to the child's process group instead of just the direct child;
# it also propagates the child's exit code. No '-s': tini is already PID 1 here.
# 'ENTRYPOINT' means overriding only 'CMD' keeps the init: in Kubernetes use
# 'args', not 'command' (which replaces the ENTRYPOINT).
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]

CMD ["zsh", "-l"]
