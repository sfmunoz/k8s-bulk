# k8s-bulk — Agent Guide

For project overview, installed packages, build instructions, CI/CD release
process, and references, see [README.md](README.md).

## Commit style

This repo uses **lowercase imperative** messages with a `<file-or-area>:`
prefix. No conventional-commit prefixes (`feat:`, `fix:`, etc.).

Examples:
```
Dockerfile: sqlite package installed
README.md: 'Devel' section added
.github/workflows: add docker-build.yml to build and push image to GHCR on tag push
```

## CI/CD pitfalls

The `org.opencontainers.image.description` label is populated from the git tag
annotation. Since `actions/checkout@v4` does not create local tag refs by default,
the workflow explicitly fetches the annotated tag with `git fetch origin tag`
before reading it. Without that step, `git tag -l` returns empty and the GHCR
description falls through to the last commit message.
