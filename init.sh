#!/bin/bash

# Default variables
DEFAULT_PASSWORD="password123"
DOCKER_INSTALL=false
LOKI_INSTALL=false
HEADSCALE_INSTALL=false
HEADSCALE_URL=""
HEADSCALE_AUTHKEY=""

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
                                GROUPS=$1
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
        -h | --help )           usage
                                ;;
        * )                     usage
    esac
    shift
done

# Create groups if specified
if [ ! -z "$GROUPS" ]; then
    IFS=',' read -r -a group_array <<< "$GROUPS"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" > /dev/null; then
            groupadd "$group"
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
        uid="${uid_array[i]:-}"
        gid="${gid_array[i]:-}"

        if ! id "$user" > /dev/null 2>&1; then
            if [ ! -z "$gid" ]; then
                useradd -m -p "$(openssl passwd -1 $DEFAULT_PASSWORD)" -u "$uid" -g "$gid" "$user" -s /bin/bash
            else
                useradd -m -p "$(openssl passwd -1 $DEFAULT_PASSWORD)" -u "$uid" "$user" -s /bin/bash
            fi

            # Create .ssh directory and authorized_keys file
            if [ ! -z "$SSH_KEY" ]; then
                mkdir -p "/home/$user/.ssh"
                echo "$SSH_KEY" >> "/home/$user/.ssh/authorized_keys"
                chown -R "$user:$user" "/home/$user/.ssh"
                chmod 700 "/home/$user/.ssh"
                chmod 600 "/home/$user/.ssh/authorized_keys"
            fi
        fi
    done
fi

# Install Docker if specified
if [ "$DOCKER_INSTALL" = true ]; then
    if ! command -v docker &> /dev/null; then
        apt-get update
        apt-get install -y docker.io
        systemctl start docker
        systemctl enable docker
    fi
fi

# Install Loki Docker driver if specified
if [ "$LOKI_INSTALL" = true ]; then
    if [ "$DOCKER_INSTALL" = true ]; then
        docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
    else
        echo "Docker must be installed to use the Loki Docker driver."
    fi
fi

# Set up Headscale client if specified
if [ ! -z "$HEADSCALE_URL" ] && [ ! -z "$HEADSCALE_AUTHKEY" ]; then
    echo "Setting up Headscale client..."
    # Assuming the headscale binary is available
    headscale register --url "$HEADSCALE_URL" --authkey "$HEADSCALE_AUTHKEY"
fi

echo "Script completed."
