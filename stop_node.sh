#!/bin/bash
crontab -r
docker compose -f updated-docker-compose.yaml down