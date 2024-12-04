docker build -t ssl-proxy:latest .
docker tag ssl-proxy:latest docker.io/mtyszczak/ssl-proxy:latest
docker push docker.io/mtyszczak/ssl-proxy:latest
