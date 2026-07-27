# Check 'README.md' for usage instructions

FROM python:3.14.6-alpine3.24

ARG DESCRIPTION=
LABEL org.opencontainers.image.source=https://github.com/sfmunoz/k8s-bulk
LABEL org.opencontainers.image.description="${DESCRIPTION}"

#RUN pip install --no-cache-dir requests

RUN apk add --no-cache rclone curl sqlite

CMD python3
