# Check 'README.md' for usage instructions

FROM python:3.14.2-alpine3.23

LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk

RUN pip install --no-cache-dir requests kubernetes kopf vultr-python

RUN apk add --no-cache rclone

CMD python3
