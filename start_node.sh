#!/bin/bash

# Function to install yq on Linux
install_yq_linux_amd64() {
    sudo apt update
    sudo apt install -y jq   
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
}

install_yq_linux_arm4() {
    sudo apt update
    sudo apt install -y jq   
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_arm64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
}

# Function to install yq on macOS
install_yq_macos() {
    brew install yq   # Install yq using Homebrew
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 k:address"
    exit 1
fi
kadena_address="$1"


# Define the regex pattern
pattern="^k:[0-9a-f]{64}$"

# Use grep to check if the input string matches the pattern
if echo "$kadena_address" | grep -qE "$pattern"; then
    echo "Valid kadena address"
else
    echo "Invalid Kadena address"
    exit 1
fi


platform=$(uname)
arch=$(arch)
# Check if yq is already installed
if ! command -v yq &> /dev/null; then
    # yq command not found, determine the platform and install yq


    if [ "$platform" == "Linux" ]; then
       if [ "$arch" == "arm64"]; then
          echo "Detected Linux arm64 platform. Installing yq..."
          install_yq_linux_arm4
        else
          echo "Detected Linux amd64 platform. Installing yq..."
          install_yq_linux_amd64
        fi
    elif [ "$platform" == "Darwin" ]; then
        echo "Detected macOS platform. Installing yq..."
        install_yq_macos
    else
        echo "Unsupported platform: $platform"
        exit 1
    fi

    # Verify yq installation
    echo "yq installation complete. Version:"
    yq --version
else
    echo "yq is already installed. Skipping installation."
    echo "Current yq version:"
    yq --version
fi
yq ".services.cyberfly_node.environment[0]=\"KADENA_ACCOUNT=$kadena_address\"" docker-compose.yaml > updated-docker-compose.yaml

if [ "$platform" == "Linux" ]; then
    docker-compose pull
    docker-compose -f updated-docker-compose.yaml down
    docker-compose -f updated-docker-compose.yaml up -d
elif [ "$platform" == "Darwin" ]; then
    docker compose pull
    docker compose -f updated-docker-compose.yaml down
    docker compose -f updated-docker-compose.yaml up -d
    
else
    echo "Unsupported platform: $platform"
    exit 1
fi

# Get the current working directory
SCRIPT_DIR=$(pwd)

# Path to the script you want to run
SCRIPT_PATH="$SCRIPT_DIR/check_node.sh"
chmod +x $SCRIPT_PATH

# Check if the cronjob already exists
if ! crontab -l | grep -q "$SCRIPT_PATH"; then
    # Add the cronjob to run the script every minute
    (echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/bin/docker")| crontab -
    (crontab -l ; echo "* * * * * $SCRIPT_PATH > /tmp/cronjob.log 2>&1" ) | crontab -
    echo "Cronjob added successfully."
else
    echo "Cronjob already exists. No action needed."
fi