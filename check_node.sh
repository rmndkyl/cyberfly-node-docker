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
    log "Node might be down. try to up it"
    if [ "$platform" == "Linux" ]; then
       docker-compose -f updated-docker-compose.yaml down
       docker-compose -f updated-docker-compose.yaml up -d

    elif [ "$platform" == "Darwin" ]; then
       docker compose -f updated-docker-compose.yaml down
       docker compose -f updated-docker-compose.yaml up -d
    fi
fi