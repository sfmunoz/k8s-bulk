# Check 'README.md' for usage instructions

FROM python:3.14.2-alpine3.23

LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk

RUN pip install --no-cache-dir requests kubernetes kopf vultr-python

RUN apk add --no-cache rclone curl

RUN curl -L -o /usr/local/bin/butane https://github.com/coreos/butane/releases/download/v0.25.1/butane-x86_64-unknown-linux-gnu \
  && chmod 755 /usr/local/bin/butane \
  && sha256sum -c <(echo "c9bf44bed655215384fca24c3ebf2b547965d9c522cf959e735201c5f97ea467  /usr/local/bin/butane")

CMD python3
