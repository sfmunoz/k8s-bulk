# k8s-bulk

**k8s-bulk** is a minimal Kubernetes utility image published to GHCR. It's a generic
Debian-based image with a few CLI tools baked in, designed for general
housekeeping, operators, and ad-hoc tasks inside a cluster.

Base image: `debian:forky-20261005-slim`
Registry: `ghcr.io/sfmunoz/k8s-bulk`

The base is Debian *testing* (forky), pinned to a dated snapshot tag: reproducible,
but security updates only land when the tag is bumped.

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

`python3` and `nodejs` are the bundled runtimes, and `nodejs` comes with `npm`.
Install any other language runtime at runtime.

`zsh` is the login shell for `root`, with zsh defaults (no configuration is shipped).

`tmux` and `zellij` are registered in `/etc/shells`, so either can be set as a login
shell.

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
