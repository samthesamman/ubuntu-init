# ubuntu-init

fetch this file with
curl -O https://raw.githubusercontent.com/samthesamman/ubuntu-init/refs/heads/master/init.sh

example:

sh ./init.sh -u chan,dockernas -g users,dockernas -U 1026,1031 -G 100,65538 -k <ssh-key> -d -l -i <loki-driver-address> -e "https://hs.grumpledumps.com" -a <auth_key>

more full example:

sudo bash ./init.sh -u chan,dockernas -g users,dockernas -U 1026,1031 -G 100,65538 -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFyaPv5cNpkmjARTMcAbkMLacdFjqA4rJz24mqTqPxf chankruse@Chans-MacBook-Pro-14.local" -d -l -i "100.64.0.3" -e "https://hs.grumpledumps.com" -a 982e1afed3d00a81e69ef82526cfc1bd6cd13fd12e1ccfeb


sudo bash ./init.sh -u chan,dockernas -g users,dockernas -U 1026,1031 -G 100,65538 -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFyaPv5cNpkmjARTMcAbkMLacdFjqA4rJz24mqTqPxf chankruse@Chans-MacBook-Pro-14.local" -d