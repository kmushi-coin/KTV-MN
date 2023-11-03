#!/bin/bash
# KTV Masternode Setup Script V2.0.1 for Ubuntu 22.04 LTS
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash KTV-MN.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=36599
RPC=36600

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'ktvd' > /dev/null; then
        echo -e "${YELLOW}Intento de detener ktvd${NC}"
        ktv-cli stop
        sleep 30
        if pgrep -x 'ktvd' > /dev/null; then
            echo -e "${RED}ktvd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 ktvd
            sleep 30
            if pgrep -x 'ktvd' > /dev/null; then
                echo -e "${RED}Can't stop ktvd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
clear

echo -e "${GREEN} ------- KTV MASTERNODE INSTALLER V2.0.1--------+
 |                                                  |
 |                                                  |::
 |       The installation will install and run      |::
 |        the masternode under a user ktv.          |::
 |                                                  |::
 |        This version of installer will setup      |::
 |                                                  |::
 |                                                  |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::S${NC}"

stop_daemon

read -e -p "Enter your private key:" genkey;
read -e -p "Confirm your private key: " genkey2;

#Confirming match
if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a"
else
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    curl -s https://api4.my-ip.io/v2/ip.txt > ip.txt
    publicip=$(head -n 1 ip.txt)
    rm -rf ip.txt
    if [ -n "$publicip" ]; then
        echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
    else
        echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
        clear_stdin
        read -e -p "Enter VPS Public IP Address: " publicip
        if [ -z "$publicip" ]; then
            echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
            exit 1
        fi
    fi
fi

echo -e "${GREEN}Updating system and installing required packages...${NC}"
sudo apt update -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt install wget nano htop -y
sudo rm /etc/apt/apt.conf.d/20apt-esm-hook.conf
sudo pro config set apt_news=false

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Installing Daemon
cd ~
rm -rf /usr/local/bin/ktv*
wget https://kmushicoin.co/download/ktv-x86_64-linux-gnu.tar.gz
tar -xzvf ktv-x86_64-linux-gnu.tar.gz
rm ktv-x86_64-linux-gnu.tar.gz
mv ktv* /usr/local/bin
rm -rf qt
wget https://github.com/kmushi-coin/kmushicoin-source/raw/master/util/fetch-params.sh
bash fetch-params.sh
rm fetch-params.sh
sleep 5

#Create datadir
if [ ! -f ~/.ktv/ktv.conf ]; then
    sudo mkdir ~/.ktv
fi

wget https://kmushicoin.co/download/bootstrap.dat -O ~/.ktv/bootstrap.dat

cd ~
clear

echo -e "${YELLOW}Creating ktv.conf...${NC}"
# Create ktv.conf
cat <<EOF > ~/.ktv/ktv.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
rpcport=$RPC
port=$PORT
listen=1
server=1
daemon=1

logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip:$PORT
masternodeaddr=$publicip:$PORT
masternodeprivkey=$genkey
EOF
sleep 5
#Finally, starting daemon with new ktv.conf

wget https://github.com/kmushi-coin/KTV-MN/raw/main/ktvd.service -O /etc/systemd/system/ktvd.service
systemctl daemon-reload
systemctl enable ktvd.service --now

sleep 5

systemctl status ktvd.service

echo -e "========================================================================
${GREEN}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
======================================================================== \a"
sleep 5
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s
echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${GREEN}Node just started, not yet activated${NC} or
    ${GREEN}Node is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in ktv.conf:
${GREEN}cat ~/.ktv/ktv.conf${NC}
Here is your ktv.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${NC}-------------------------------------------------
NOTE: To edit ktv.conf, first stop the ktvd daemon,
then edit the ktv.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the ktvd daemon back up:
to stop:              ${GREEN}ktv-cli stop${NC}
to start:             ${GREEN}ktvd${NC}
to edit:              ${GREEN}nano ~/.ktv/ktv.conf${NC}
to check mn status:   ${GREEN}ktv-cli getmasternodestatus${NC}
to init mn local:     ${GREEN}ktv-cli startmasternode local false${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================
"