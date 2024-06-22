#!/bin/bash
sudo crontab -r
sudo docker compose -f updated-docker-compose.yaml down
