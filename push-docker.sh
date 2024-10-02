docker build -t ssl-proxy:latest .
docker tag ssl-proxy:latest repo:30095/wtdesignpl/ssl-proxy:latest
docker push repo:30095/wtdesignpl/ssl-proxy:latest
