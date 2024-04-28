platform=$(uname)
SCRIPT_DIR=$(pwd)

current_dir=$(dirname "$0")

cd "$current_dir"

echo "Running script in directory: $(pwd)"

response=$(curl -s -X GET http://localhost:31003/api)
if [[ "$response" == *"\"health\":\"ok\""* ]]; then
    echo "Response received: health is ok"
else
    if [ "$platform" == "Linux" ]; then
       docker-compose -f updated-docker-compose.yaml down
       docker-compose -f updated-docker-compose.yaml up -d

    elif [ "$platform" == "Darwin" ]; then
       docker compose -f updated-docker-compose.yaml down
       docker compose -f updated-docker-compose.yaml up -d
    fi
fi