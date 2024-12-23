#!/bin/bash
sudo docker-compose -f updated-docker-compose.yaml down
sudo docker-compose -f updated-docker-compose.yaml up --force-recreate -d 
