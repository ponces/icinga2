#!/bin/bash

docker build . -t ponces/icinga2:latest
docker stop icinga2
docker rm icinga2
docker run -d -p 25:25 -p 80:80 -p 3000:3000 -h icinga2 \
           -e CMF_SERVICES_USER="$CMF_SERVICES_USER" \
           -e CMF_SERVICES_PASS="$CMF_SERVICES_PASS" \
           -v $(pwd)/msmtp/aliases:/etc/aliases:ro \
           -v $(pwd)/msmtp/msmtprc:/etc/msmtprc:ro \
           --name icinga2 -t ponces/icinga2:latest
sleep 30
xdg-open http://localhost/icingaweb2
xdg-open http://localhost:3000
