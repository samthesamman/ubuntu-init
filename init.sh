#!/bin/bash

# Default variables
DOCKER_INSTALL=false
LOKI_INSTALL=false
HEADSCALE_INSTALL=false
HEADSCALE_URL=""
HEADSCALE_AUTHKEY=""
LOKI_IP="localhost"  # Default value for Loki IP

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -u, --users <user1,user2,...>       Comma-separated list of users to create."
    echo "  -g, --groups <group1,group2,...>     Comma-separated list of groups to create."
    echo "  -U, --user-ids <uid1,uid2,...>       Comma-separated list of user IDs."
    echo "  -G, --group-ids <gid1,gid2,...>      Comma-separated list of group IDs."
    echo "  -k, --ssh-key <public-key>           Public SSH key to add."
    echo "  -d, --install-docker                  Install Docker."
    echo "  -l, --install-loki                    Install Loki Docker driver."
    echo "  -e, --headscale-url <url>            Headscale endpoint URL."
    echo "  -a, --headscale-authkey <authkey>    Headscale auth key."
    echo "  -i, --loki-ip <ip-address>           IP address for Loki."
    echo "  -h, --help                            Show this help message."
    exit 1
}

# Parse command-line arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -u | --users )          shift
                                USERS=$1
                                ;;
        -g | --groups )         shift
                                USER_GROUPS=$1
                                ;;
        -U | --user-ids )       shift
                                USER_IDS=$1
                                ;;
        -G | --group-ids )      shift
                                GROUP_IDS=$1
                                ;;
        -k | --ssh-key )        shift
                                SSH_KEY=$1
                                ;;
        -d | --install-docker ) DOCKER_INSTALL=true
                                ;;
        -l | --install-loki )   LOKI_INSTALL=true
                                ;;
        -e | --headscale-url )  shift
                                HEADSCALE_URL=$1
                                ;;
        -a | --headscale-authkey ) shift
                                HEADSCALE_AUTHKEY=$1
                                ;;
        -i | --loki-ip )        shift
                                LOKI_IP=$1
                                ;;
        -h | --help )           usage
                                ;;
        * )                     usage
    esac
    shift
done

# Create groups if specified
if [ ! -z "$USER_GROUPS" ]; then
    IFS=',' read -r -a group_array <<< "$USER_GROUPS"
    IFS=',' read -r -a gid_array <<< "${GROUP_IDS:-}"
    for i in "${!group_array[@]}"; do
        group="${group_array[i]}"
        gid="${gid_array[i]:-}"
        if ! getent group "$group" > /dev/null; then
            echo "Adding group: $group"
            groupadd -g "$gid" "$group"
        else
            echo "group $group already exists"
        fi
    done
fi

# Create users if specified
if [ ! -z "$USERS" ]; then
    IFS=',' read -r -a user_array <<< "$USERS"
    IFS=',' read -r -a uid_array <<< "${USER_IDS:-}"
    IFS=',' read -r -a gid_array <<< "${GROUP_IDS:-}"

    for i in "${!user_array[@]}"; do
        user="${user_array[i]}"
        group="${group_array[i]}"
        uid="${uid_array[i]:-}"
        gid="${gid_array[i]:-}"

        if ! id "$user" > /dev/null 2>&1; then
            echo "Adding user: $user; uid: $uid; gid:$gid"

            if [ ! -z "$gid" ]; then
                useradd -m -u "$uid" -g "$gid" "$user" -s /bin/bash
            else
                useradd -m -u "$uid" "$user" -s /bin/bash
            fi

            # Prompt for the password
            echo "Enter password for user $user:"
            passwd "$user"

            if [ "$user" == "chan" ]; then
                echo "Adding $user to the sudo group and adm..."
                usermod -aG sudo "$user"
                usermod -aG adm "$user"
            fi

            # Create .ssh directory and authorized_keys file
            if [ ! -z "$SSH_KEY" ]; then
                mkdir -p "/home/$user/.ssh"
                echo "$SSH_KEY" >> "/home/$user/.ssh/authorized_keys"
                chown -R "$user:$group" "/home/$user/.ssh"
                chmod 700 "/home/$user/.ssh"
                chmod 600 "/home/$user/.ssh/authorized_keys"
            fi
        else
            echo "user $user already exists"
        fi
    done
fi

# Install Docker if specified
if [ "$DOCKER_INSTALL" = true ]; then
    if ! command -v docker &> /dev/null; then
        echo "Downloading Docker installation script..."
        curl -fSL https://get.docker.com -o install-docker.sh
        
        echo "Running Docker installation script..."
        sh install-docker.sh

        groupadd docker

        # Add all users to the 'docker' group
        if [ ! -z "$USERS" ]; then
            IFS=',' read -r -a user_array <<< "$USERS"
            for user in "${user_array[@]}"; do
                usermod -aG docker "$user"
                echo "Added $user to the docker group."
            done
        fi

        echo "Docker installed successfully."
    else
        echo "Docker is already installed."
    fi
fi

# Install Loki Docker driver if specified
if [ "$LOKI_INSTALL" = true ]; then
    if [ "$DOCKER_INSTALL" = true ]; then
        docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
        
        # Restart Docker to apply changes
        systemctl restart docker

        echo "Loki Docker driver installed."
    else
        echo "Docker must be installed to use the Loki Docker driver."
    fi
else
    if [ "$DOCKER_INSTALL" = true ]; then
        # Update Docker daemon to use Loki as the default logging driver
        echo "Updating Docker daemon configuration to set journald as the default logging driver..."
        if [ ! -d "/etc/docker" ]; then
            mkdir /etc/docker
        fi
    
    cat <<EOF > /etc/docker/daemon.json
{
    "log-driver": "journald",
    "log-opts": {
        "tag": "{{.Name}}"
    }
}
EOF

        # Restart Docker to apply changes
        systemctl restart docker

        echo "Journald driver set."
    else
        echo "Docker must be installed to use the Loki Docker driver."
    fi
fi

# Set up Headscale client if specified
if [ ! -z "$HEADSCALE_URL" ] && [ ! -z "$HEADSCALE_AUTHKEY" ]; then
    echo "Downloading Tailscale client..."
    
    curl -fSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list

    apt-get update
    apt-get install -y tailscale

    echo "Setting up Tailscale client..."
    # Assuming the headscale binary is available
    tailscale up --login-server "$HEADSCALE_URL" --authkey "$HEADSCALE_AUTHKEY"
fi

echo "Script completed."