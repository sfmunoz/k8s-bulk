# Check 'README.md' for usage instructions

FROM python:3.13.10-alpine3.22

LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk

RUN pip install --no-cache-dir requests kubernetes kopf

CMD python3
