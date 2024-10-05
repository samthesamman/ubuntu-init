# ubuntu-init

fetch this file with
curl -O https://raw.githubusercontent.com/samthesamman/ubuntu-init/refs/heads/master/init.sh

example:

sh ./init.sh -u chan,dockernas -g users,dockernas -U 1026,1031 -G 100,65538 -k <ssh-key> -d -l -i <loki-driver-address> -e "https://hs.grumpledumps.com" -a <auth_key>

more full example:

sudo bash ./init.sh -u chan,dockernas -g users,dockernas -U 1026,1031 -G 100,65538 -k "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCv8ML905dPtLLM/OhbV8+7fIyRtyfU6JYz8K45xP+VfTT9dn09kZ4WHsHYguAncmrpdNrfDvQ1U+rCs9gVk5OrVP21C1Mxv1OK/0eCIjA/C9OmWsW4NB7b7VMea+u//G34jE5lgI9kyHtwKOHCTQOJUOZdudq0ZTthijXbVSpWFkCwiKSEeStQpW7C8M8e2l3G/niXWWpGiqrr8ruDHOE2ahGJBwFgdTYyJ4JGI3kyfYzFVRWw7IJFFi+g+CZv41aOBBtFw+BHVCFfv65uqQWQPcWgUa5P5YC85aYfWFDuOvEQRcnnThS+cGj9AjmiLY/HpJFhN+MKLO+T8LZicJPF chankruse@Chans-MacBook-Pro.local" -d -l -i "100.64.0.3" -e "https://hs.grumpledumps.com" -a e54d1b2e1fbcfdb2e0...