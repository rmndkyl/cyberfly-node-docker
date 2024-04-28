#!/bin/bash

# Function to install yq on Linux
install_yq_linux() {
    sudo apt update
    sudo apt install -y jq   # Install jq (required by yq)
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
# Check if yq is already installed
if ! command -v yq &> /dev/null; then
    # yq command not found, determine the platform and install yq


    if [ "$platform" == "Linux" ]; then
        echo "Detected Linux platform. Installing yq..."
        install_yq_linux
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
    docker-compose -f updated-docker-compose.yaml up
elif [ "$platform" == "Darwin" ]; then
    docker compose pull
    docker compose -f updated-docker-compose.yaml up
    
else
    echo "Unsupported platform: $platform"
    exit 1
fi