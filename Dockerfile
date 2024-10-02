FROM alpine:3.20

LABEL version="1.0"
LABEL description="Nginx reverse proxy server for multiple services"

RUN apk --update --no-cache add \
  nginx \
  openssl \
  bash \
  apache2-utils \
  sudo

WORKDIR /www/

COPY ./entrypoint.sh ./

STOPSIGNAL SIGTERM

ENTRYPOINT /www/entrypoint.sh
