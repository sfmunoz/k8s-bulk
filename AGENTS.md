# k8s-bulk — Agent Guide

## Overview

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

## Build

```sh
docker build -t ghcr.io/sfmunoz/k8s-bulk:devel .
```

No special build args. Standard `docker build` from repo root.

## Commit style

This repo uses **lowercase imperative** messages with a `<file-or-area>:`
prefix. No conventional-commit prefixes (`feat:`, `fix:`, etc.).

Examples:
```
Dockerfile: sqlite package installed
README.md: 'Devel' section added
.github/workflows: add docker-build.yml to build and push image to GHCR on tag push
```

## CI/CD

- **Trigger**: push of a `v*` tag (e.g. `v0.1.0`)
- **Action**: builds and pushes to GHCR with two tags:
  - `ghcr.io/sfmunoz/k8s-bulk:<semver>` (version stripped of `v`)
  - `ghcr.io/sfmunoz/k8s-bulk:latest`
- **Permissions**: `packages: write`
- **No cache** (`no-cache: true`) — always clean build

## References

- [GHCR package page](https://github.com/sfmunoz/k8s-bulk/pkgs/container/k8s-bulk)
- [GitHub Container Registry docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Related: postgres-image](https://github.com/sfmunoz/postgres-image)
- [Related: anki-sync-server](https://github.com/sfmunoz/anki-sync-server)
- [k8s-playground issue #131 — CRD + operator example](https://github.com/sfmunoz/k8s-playground/issues/131)
