# k8s-bulk

**k8s-bulk** is a minimal Kubernetes utility image published to GHCR. It's a generic
Debian-based image with a few CLI tools baked in, designed for general
housekeeping, operators, and ad-hoc tasks inside a cluster.

Base image: `debian:forky-20261005-slim`
Registry: `ghcr.io/sfmunoz/k8s-bulk`

The base is Debian *testing* (forky), pinned to a dated snapshot tag: reproducible,
but security updates only land when the tag is bumped.

`apt` runs with `Install-Recommends` and `Install-Suggests` disabled, so packages
installed at runtime stay minimal.

## Installed packages

| Package | Purpose |
|---------|---------|
| ca-certificates | TLS trust store for curl and rclone |
| rclone  | Cloud storage sync (S3, GCS, etc.; upstream static binary) |
| curl    | HTTP requests, API calls, health checks |
| git     | Version control |
| ripgrep | Fast recursive search (`rg`) |
| fd-find | Fast file finder (binary `fdfind`) |
| sqlite3 | Lightweight local data queries |
| zsh     | Interactive shell with completion and theming |
| neovim  | Modal text editor |
| tmux    | Terminal multiplexer |
| htop    | Interactive process viewer |
| procps  | Process and system utilities (ps, top, free, vmstat) |
| less    | Pager for viewing files |
| openssh-client | SSH client (`ssh`, `scp`, `sftp`; no server) |
| python3 | Python 3 interpreter |
| zellij  | Terminal workspace and multiplexer (upstream static binary) |
| nodejs  | Node.js 24 LTS runtime and npm (Debian package) |
| unzip   | Extract ZIP archives (used to install rclone) |
| sudo    | Run commands as root (granted to `bulk`, see below) |
| oh-my-zsh | zsh framework (upstream git, pinned commit; seeded into `/etc/skel`) |

`python3` and `nodejs` are the bundled runtimes, and `nodejs` comes with `npm`.
Install any other language runtime at runtime.

`zsh` is the login shell for `root` and `bulk`.

oh-my-zsh is installed for `root` in `/root/.oh-my-zsh` with the stock
`templates/zshrc.zsh-template` as `/root/.zshrc`, with `ZSH_THEME` set to `fino`. The same tree
is seeded into `/etc/skel` (hardlinked in the image), so every user created afterwards
— `bulk`, and any user created at runtime with `useradd -m` — gets its own copy in its
home directory, owned by that user. The template sets `ZSH="$HOME/.oh-my-zsh"`, so each
user loads their own copy.

Consequences:

- A new home directory costs ~16 MB more than stock `/etc/skel`.
- `.git` is kept, so `omz update` works; the commit is pinned by the `OMZ_COMMIT` build
  arg, so an in-place `git pull` can diverge from the pinned commit.

`tmux` and `zellij` are registered in `/etc/shells`, so either can be set as a login
shell.

## User

Everything runs as the unprivileged user `bulk` (UID/GID `1000:1000`), with
`/home/bulk` as its home directory and working directory. The numeric UID is set
explicitly so Kubernetes accepts `runAsNonRoot: true`, which can only verify a
numeric user.

`sudo` is installed and granted to `bulk` passwordless, via `/etc/sudoers.d/bulk`
(mode `0440`):

```sh
sudo apt-get update && sudo apt-get install -y <package>
```

That rule is `NOPASSWD:ALL`, so `USER 1000:1000` is the default user, not a security
boundary: any process running as `bulk` can become root. Use it knowingly, and do not
combine it with `--security-opt=no-new-privileges` — that blocks the `setuid` bit on
`/usr/bin/sudo` and makes `sudo` fail.

Without `sudo` (for example in a restricted pod), root is still reachable from outside:

```sh
# docker
docker run --rm -u 0 -it ghcr.io/sfmunoz/k8s-bulk:devel
```

```yaml
# Kubernetes: override the user for a single container
securityContext:
  runAsUser: 0
```

Runtime installs that do not need root should still land in `$HOME`
(`npm config set prefix ~/.npm-global`, `pip install --user`); `/usr/local` and `/etc`
are root-owned.

When mounting a volume, make it writable for UID `1000`, either with `chown 1000:1000`
or Kubernetes `securityContext.fsGroup`.

## References

- [https://github.com/sfmunoz/k8s-bulk/pkgs/container/k8s-bulk](https://github.com/sfmunoz/k8s-bulk/pkgs/container/k8s-bulk)
- [https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [https://github.com/sfmunoz/postgres-image](https://github.com/sfmunoz/postgres-image)
- [https://github.com/sfmunoz/anki-sync-server](https://github.com/sfmunoz/anki-sync-server)
- [crd + operator: create simple example](https://github.com/sfmunoz/k8s-playground/issues/131)

## Devel

```sh
docker build -t ghcr.io/sfmunoz/k8s-bulk:devel .
```

Dockerfile layers are ordered by stability, most stable first: every `RUN` below a
changed one is rebuilt and re-pushed. Keep the three apt groups (core, runtimes, tools)
as they are — merging them makes any single package change rebuild the whole 550 MB of
packages. Measured on a package removal: 116 s merged vs 25 s split (warm cache).

`ARG DESCRIPTION`, `LABEL`s, oh-my-zsh and the user creation come last because
`DESCRIPTION` changes on every release.

## Docker build

The CI workflow (`.github/workflows/docker-build.yml`) builds and pushes to
GHCR when a `v*` tag is pushed.

Tag format: `vX.Y.Z`, with `vX.Y.Z-rc.N` for pre-releases.

```sh
# Create an annotated tag (the annotation becomes the GHCR image description)
git tag -a v<version> -m "Brief release summary"

# Push the tag to trigger the CI workflow
git push origin v<version>
```

The tag annotation is read by the CI workflow and injected as the
`org.opencontainers.image.description` label via the `DESCRIPTION` build arg
— so **write a meaningful annotation**, not a throwaway commit message.

On push, the workflow builds with `no-cache: true` and pushes two tags to GHCR:

- `ghcr.io/sfmunoz/k8s-bulk:<version>` (tag stripped of the `v` prefix)
- `ghcr.io/sfmunoz/k8s-bulk:latest`

## Docker pull

```sh
docker pull ghcr.io/sfmunoz/k8s-bulk:X.Y.Z
```
