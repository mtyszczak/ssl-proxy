# Simple docker & nginx-based ssl-proxy for multiple services

## Quick reference

- **Source repository**: [ssl-proxy](https://github.com/mtyszczak/ssl-proxy)

Protect any HTTP service with HTTPS!
> An Nginx & Docker-based HTTPS/SSL reverse proxy.

### Table of Contents

1. [Features](#features)
2. [Getting Started](#getting-started)
3. [Examples](#examples)
4. [Arguments / Configuration](#arguments)

## Features

- Up-to-date Nginx & Alpine Linux.
- Fast HTTP2 TLS-enabled reverse proxy
- Advanced CORS Support (w/ credentials, auto hostname, smart headers)
- Automatic **WebSockets Support**
- NPN/ALPN Application-Layer Protocol Negotiation [test here](https://tools.keycdn.com/http2-test)
- TLS Forward Secrecy, PFS (aka Perfect Forward Secrecy).
- Supports Optional Username & Password (stored using bcrypt at 14+ rounds) or Alternately an `.htpasswd` file can be volume mounted. (Multiple named users)
- Great for securing a Docker Registry, Rancher server, Wordpress, etc

## Getting Started

### Requirements

> 1. [Generate a HTTPS/SSL certificate using letsencrypt.](https://github.com/justsml/63d2884e1cd88d6785999a2eb09cf48e)

To provide secure, proxied access to local HTTP service:

1. Requires any working HTTP service (for UPSTREAM_TARGET.) (Supports **local, in-docker, even remote**).
2. Start an instance of `mtyszczak/ssl-proxy:latest` as shown below.

## Examples

### Secure Docker Registry Example

```sh
# Create an ssl-proxy to point at the registry's port 5000 (via UPSTREAM_TARGET option - see below.)
docker run -d --restart=on-failure:5 \
  --name ssl-proxy \
  -p 5000:5000 \
  -e 'SERVER_NAME=hub.example.com' \
  -e 'UPSTREAM_TARGET_0=docker-registry:5000' \
  -e 'HTTPS_PORT_0=5000' \
  -e 'CERT_PUBLIC_PATH=/certs/fullchain.pem' \
  -e 'CERT_PRIVATE_PATH=/certs/privkey.pem' \
  -e "ADD_HEADER_0='Docker-Distribution-Api-Version' 'registry/2.0' always" \
  -v '/certs:/certs:ro' \
  --link 'docker-registry:docker-registry' \
  mtyszczak/ssl-proxy:latest
```

### Secure Rancher Server Example using Docker Compose

```yaml
version: '2'
services:
  ssl-proxy:
    image: mtyszczak/ssl-proxy:latest
    environment:
    - HTTPS_PORT_0=8080
    - SERVER_NAME=rancher.example.com
    - UPSTREAM_TARGET_0=rancher-server:8080
    - CERT_PUBLIC_PATH=/certs/fullchain.pem
    - CERT_PRIVATE_PATH=/certs/privkey.pem
    volumes:
    - /certs:/certs:ro
    links:
    - 'rancher-server:rancher-server'
    ports: [ '8080:8080' ]
  rancher-server:
    image: rancher/server:latest
    expose: [ '8080' ]
    volumes:
    - /data/rancher/mysql:/var/lib/mysql
```

## Arguments

| Name                   | Required | Default | Notes
|------------------------|----------|---------|-----------------------
| CERT_PUBLIC_PATH       |    🔘    | `/certs/fullchain.pem` | Bind-mount certificate files to container path `/certs` - Or override path w/ this var
| CERT_PRIVATE_PATH      |    🔘    | `/certs/privkey.pem` | Bind-mount certificate files to container path `/certs` - Or override path w/ this var
| SERVER_NAME            |    🚩    |         | Primary domain name. Not restricting
| CORS_ORIGIN            |    🔘    | `$SERVER_NAME` | CORS origin to use for `Access-Control-Allow-Origin` header
| CORS_METHODS           |    🔘    | `'GET, POST, PUT, DELETE, HEAD, OPTIONS'` | CORS allowed methods to use for `Access-Control-Allow-Methods` header
| CORS_HEADERS           |    🔘    | `'Sec-WebSocket-Extensions,Sec-WebSocket-Key,Sec-WebSocket-Protocol,Sec-WebSocket-Version,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,x-api-action-links,x-api-csrf,x-api-no-challenge,X-Forwarded-For,X-Real-IP'` | CORS allowed headers to use for `Access-Control-Allow-Headers` header
| UPSTREAM_TARGET_x      |    🚩    |         | HTTP target host:port. Typically an internally routable address. e.g. `localhost:9090` or `rancher-server:8080`. Replace `x` with proper index (starts with `0`, e.g. `UPSTREAM_TARGET_0=localhost:9090`, `UPSTREAM_TARGET_1=localhost:9091` and so on)
| HTTPS_PORT_x           |    🚩    |  `443`  | Needed for URL rewriting. Replace `x` with the proper index (starts with `0`, e.g. `HTTPS_PORT_0=80`, `HTTPS_PORT_1=1000` and so on)
| INJECT_SSL_REDIRECT    |    🔘    |         | Set to `true` to inject default HTTP port `80` listening and redirect to `$HTTPS_PORT_1`
| USERNAME               |    🔘    | `admin` | Both PASSWORD and USERNAME must be set in order to use Basic authorization
| PASSWORD               |    🔘    |         | Both PASSWORD and USERNAME must be set in order to use Basic authorization
| PASSWD_PATH            |    🔘    | `/etc/nginx/.htpasswd` | Alternate auth support (don't combine with USERNAME/PASSWORD) Bind-mount a custom path to `/etc/nginx/.htpasswd`
| SSL_VERIFY_CLIENT      |    🔘    |         | Set to verify client certificates (may be `on`, `off`, `optional`, or `optional_no_ca`). If set and not `optional_no_ca`, CERT_CLIENT_PATH must be set
| CERT_CLIENT_PATH       |    🔘    |         | Needed for client certificate verification. This cert must be PEM-encoded and contain the trusted CA and Intermediate CA certs
| ADD_HEADER_x_y         |    🔘    |         | Useful for tagging routes in your infrastructure. Replace `x` with the proper index for upstream target and `y` with proper index for the header (both start with `0`, e.g. `ADD_HEADER_0_0="A: 10"`)
| ADD_PROXY_HEADER_x_y   |    🔘    |         | Useful for providing metadata to the upstream server. Replace `x` with the proper index for upstream target and `y` with proper index for the header (both start with `0`, e.g. `ADD_PROXY_HEADER_0_0="A: 10"`)
| SERVER_NAMES_HASH_SIZE |    🔘    |  `32`   | Maximum size of server name. Set it to 64/128/... if nginx fails to start with `could not build server_names_hash, you should increase server_names_hash_bucket_size` error message
| PROXY_HEADER_HOST      |    🔘    | `'$http_host'` | The host value that will be set in the request header. Defaults to the nginx variable, `'$host'`. Set this value (e.g., to the nginx variable, `'$http_host'`) if including the port number in the `Host` header is important
| RATE_LIMIT             |    🔘    |   `8`   | Requests per second (throttled_site:10m)
| RATE_LIMIT             |    🔘    |   `8`   | Requests per second (throttled_site:10m)
| TLS_PROTOCOLS          |    🔘    |   `TLSv1 TLSv1.1 TLSv1.2`   | Supported TLS protocols for the nginx configuration
| EXPIRES_DEFAULT        |    🔘    |         | [Supported](https://nginx.org/en/docs/http/ngx_http_headers_module.html) `expires` configuration for the nginx
| LOW_LATENCY            |    🔘    |         | Set to `true` to disable proxy buffering
