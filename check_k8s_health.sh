#!/bin/bash

while true
do
  response=$(curl -k --write-out "%{http_code}\n" --silent --output ./curl-out "https://k8s.lan.chtm.me:6443/healthz?verbose=true")
  if [ $response -ne 200  ]; then
     exit 1
  else
     echo "$(date) ok" > ./last-check-time.log
  fi
  sleep 1
done