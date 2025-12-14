# k8s-bulk

**k8s-bulk** is a Kubernetes image meant to be used for multiple purposes: general housekeeping, operators, whatever may come up, ...

- [References](#references)
- [Docker pull](#docker-pull)
- [Docker build](#docker-build)
- [Docker push](#docker-push)

## References

- [https://github.com/sfmunoz/k8s-bulk/pkgs/container/k8s-bulk](https://github.com/sfmunoz/k8s-bulk/pkgs/container/k8s-bulk)
- [https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [https://github.com/sfmunoz/postgres-image](https://github.com/sfmunoz/postgres-image)
- [crd + operator: create simple example](https://github.com/sfmunoz/k8s-playground/issues/131)

## Docker pull
```
docker pull ghcr.io/sfmunoz/k8s-bulk:git-abcdefg
```

## Docker build
```
docker build \
  -t ghcr.io/sfmunoz/k8s-bulk:v1.0.0 \
  -t ghcr.io/sfmunoz/k8s-bulk:v1.0 \
  -t ghcr.io/sfmunoz/k8s-bulk:v1 \
  -t ghcr.io/sfmunoz/k8s-bulk:git-abcdefg \
  -t ghcr.io/sfmunoz/k8s-bulk:latest \
  .
```

## Docker push
```
docker push --all-tags ghcr.io/sfmunoz/k8s-bulk
```
