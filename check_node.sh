#!/bin/bash
platform=$(uname)
SCRIPT_DIR=$(pwd)
LOG_FILE="/var/log/cyberfly_node.log"

current_dir=$(dirname "$0")

cd "$current_dir"

echo "Running script in directory: $(pwd)"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "script execution starts"

response=$(curl -s -X GET http://localhost:31003/api)
if [[ "$response" == *"\"health\":\"ok\""* ]]; then
    echo "Response received: health is ok"
else
    log "Node might be down. Trying to bring it up."

    if [ "$platform" == "Linux" ]; then
        echo "Starting node on Linux"
        docker-compose -f updated-docker-compose.yaml down
        docker-compose -f updated-docker-compose.yaml up -d
    elif [ "$platform" == "Darwin" ]; then
        echo "Starting node on Darwin (Mac)"
        docker compose -f updated-docker-compose.yaml down
        docker compose -f updated-docker-compose.yaml up -d
    else
        echo "Unsupported platform: $platform"
        log "Unsupported platform: $platform"
    fi
fi
