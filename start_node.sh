#!/bin/bash
#disable bash history


function install_linux_docker(){
	if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
		echo -e "ERROR: OS version $(lsb_release -si) not supported"
		echo -e "Ubuntu 20.04 LTS is the recommended OS version .. please re-image and retry installation"
		echo -e "Installation stopped..."
		echo
		exit
	fi
	
	echo -e "Update and upgrade system..."
	apt update -y && apt upgrade -y 
	cron_check=$(systemctl status cron 2> /dev/null | grep 'active' | wc -l)
	if [[ "$cron_check" == "0" ]]; then
		echo -e "Installing crontab..."
		sudo apt-get install -y cron > /dev/null 2>&1
	fi
	echo -e "Installing docker..."
	echo -e "Architecture: $(dpkg --print-architecture)"      
	if [[ -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
		sudo rm /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
	fi
	if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
		sudo rm /etc/apt/sources.list.d/docker.list > /dev/null 2>&1 
	fi
	if [[ $(lsb_release -d) = *Debian* ]]; then
		sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
		sudo apt-get update -y  > /dev/null 2>&1
		sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1 
		sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1
		#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - > /dev/null 2>&1
		#sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /dev/null 2>&1
		curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
		sudo apt-get update -y  > /dev/null 2>&1
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1  
	else
		sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
		sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1  
		sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1  
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
		#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
		#sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null 2>&1
		sudo apt-get update -y  > /dev/null 2>&1
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1
	fi
	echo -e "====================================================="
	echo -e "Running through some checks..."
	echo -e "====================================================="
	if sudo docker run hello-world > /dev/null 2>&1; then
		echo -e "Docker is installed"
	else
		echo -e "Docker did not installed"
	fi
}



# Function to install yq on Linux
install_yq_linux_amd64() {
    sudo apt update
    sudo apt install -y jq   
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
}

install_yq_linux_arm64() {
    sudo apt update
    sudo apt install -y jq   
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_arm64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
}

# Function to install yq on macOS
install_yq_macos() {
    brew install yq   # Install yq using Homebrew
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 k:address node_priv_key"
    exit 1
fi
kadena_address="$1"
node_priv_key="$2"



# Define the regex pattern
pattern="^k:[0-9a-f]{64}$"
priv_key_pattern="[0-9a-f]{64}$"


# Use grep to check if the input string matches the pattern
if echo "$kadena_address" | grep -qE "$pattern"; then
    echo "Valid kadena address"
else
    echo "Invalid Kadena address"
    exit 1
fi

# Use grep to check if the input string matches the pattern
if echo "$node_priv_key" | grep -qE "$priv_key_pattern"; then
    echo "Valid node secret key"
else
    echo "Invalid secret key"
    exit 1
fi


platform=$(uname)
# Check if yq is already installed
if ! command -v yq &> /dev/null; then
    # yq command not found, determine the platform and install yq


    if [[ "$platform" == "Linux" ]]; then
       arch=$(dpkg --print-architecture)
       if ! command -v docker &> /dev/null; then
          install_linux_docker
       fi
       if [[ "$arch" == "amd64" ]]; then
          echo "Detected Linux amd64 platform. Installing yq..."
          install_yq_linux_amd64
        else
          echo "Detected Linux arm64 platform. Installing yq..."
          install_yq_linux_arm64
        fi
    elif [[ "$platform" == "Darwin" ]]; then
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
yq ".services.cyberflynode.environment[0]=\"KADENA_ACCOUNT=$kadena_address\"" cyberfly-docker-compose.yaml > temp.yaml
yq ".services.cyberflynode.environment[1]=\"NODE_PRIV_KEY=$node_priv_key\"" temp.yaml > updated-docker-compose.yaml
rm temp.yaml
docker-compose -f updated-docker-compose.yaml pull
docker-compose -f updated-docker-compose.yaml down
docker-compose -f updated-docker-compose.yaml up --force-recreate -d
