# k8s-bulk

**k8s-bulk** is a minimal Kubernetes utility image published to GHCR. It's a generic
Alpine-based Python image with a few CLI tools baked in, designed for general
housekeeping, operators, and ad-hoc tasks inside a cluster.

Base image: `python:3.14.6-alpine3.24`
Registry: `ghcr.io/sfmunoz/k8s-bulk`

## Installed packages

| Package | Purpose |
|---------|---------|
| rclone  | Cloud storage sync (S3, GCS, etc.) |
| curl    | HTTP requests, API calls, health checks |
| sqlite  | Lightweight local data queries |

All other Python packages (kubernetes, kopf, vultr-python, Jinja2, paramiko,
requests) have been **removed** to keep the image slim. Install at runtime if
needed.

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

Tag format: `v<semver>` — e.g. `v2.0.0`, `v2.0.1-rc.1`.

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
docker pull ghcr.io/sfmunoz/k8s-bulk:v2.0.1
```
