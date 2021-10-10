#!/bin/bash

###############################################################################

# Description    :  This script designed for IT Admins without MDM, this was last tested on macOS Catalina
#                   Downloads and installs base user apps
# 					Copies needed files for the New User script as well, example provided for using a local NAS
#                   Success and Error messages are echoed based on the return code on the command used.

# Author         :  Miah Bentley

# Version        :  1.8

# Date           :  2021.10.10

###############################################################################

# Color variables, because I like pretty scripts
NC='\033[0m' #No Color
LR='\033[1;31m' #Light Red
LG='\033[1;32m' #Light Green
LP='\033[1;35m' #Light Purple
LC='\033[1;36m' #Light Cyan

# Retry Function to retry Commands
function retry {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1))
    if [ $count -lt $retries ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  return 0
}

# Validating admin permission is required to run script
read -p "This script must be run as an Admin. Continue? (y/n)? " CHOICE
if [ "$CHOICE" = "y" ]
then
    echo -e "${LP}Let's get this party started${NC}"
else
    echo -e "${LR}Bye Felicia${NC}"
    exit 1
fi

# Determines user location for NAS address
# Used if you have multiple offices with separate NAS addresses
# Replace letter with office name for clarity
read -p "Which location are you in? (A/B/C) " LOCATION
if [ "$LOCATION" = "A" ]
then
    echo -e "You've chosen ${LP}A${NC}"
elif [ "$LOCATION" = "B" ]
then
	echo -e "You've chosen ${LP}B${NC}"
elif [ "$LOCATION" = "C" ]
then
	echo -e "You've chosen ${LP}C${NC}"
else
    echo -e "${LR}Invalid location, please restart${NC}"
    exit 1
fi

# Determines user name for NAS login
# Intent here was to allow users to set secret files locally with their NAS credentials
# Also defines username used for NAS connection
# Replace numbers with usernames for authorized users in nas
read -p "Enter your username for the NAS (specify format for username ex. mbentley) " USER
if [ "$USER" = "1" ]
then
    echo -e "You've chosen ${LP}1${NC}"
elif [ "$USER" = "2" ]
then
	echo -e "You've chosen ${LP}2${NC}"
elif [ "$USER" = "3" ]
else
    echo -e "${LR}Invalid User, please restart${NC}"
    exit 1
fi

# Makes NAS Address based on Location
# We had different nameschemas for the NAS in each office
# If your offices have standars, this could probably just be changed to variable names rather than an if statement
if [ "$LOCATION" = "A" ]
then
    NAS=A/Helpdesk
elif [ "$LOCATION" = "B" ]
then
	NAS=B/Helpdesk
elif [ "$LOCATION" = "C" ]
then
	NAS=C/Helpdesk
else
    echo -e "${LR}Invalid location, please restart${NC}"
    exit 1
fi

###############################################################################
# Running base user settings
# Review settings and adjust as needed
# Leaving as examples/placeholders for visibility

# Setting Hot Corner to disable screensaver
echo -e "${LR}Setting Bottom Left Hot Corner to disable screen saver. Use this while copying/downloading software.${NC}"
defaults write com.apple.dock wvous-bl-corner -int 6 &&
defaults write com.apple.dock wvous-bl-modifier -int 0 &&
killall Dock &&

# Making Mount point for NAS
echo -e "${LP}Making Mount for NAS${NC}"

cd ~/Desktop &&
mkdir Mount &&

if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS${NC}"
else
	echo -e "${LR}ERROR${NC}"
fi

# Mounting to NAS
# Mounts using the username provided earlier at the NAS address
# This can be addjusted to pass the password from the secrets file as well to make this more automated
# This retries 3 times, in my experience with our specific NAS, this was the only command that worked but it was intermittent
echo -e "${LP}Mounting to NAS, this may take a couple minutes.${NC}" 
echo -e "${LR}When prompted, enter your NAS password.${NC}"
retry 3 mount_smbfs //${USER}@${NAS} ~/Desktop/Mount &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} NAS Mount Successful"
else
	echo -e "${LR}ERROR:${NC} Something went wrong mounting to the NAS, I'm sorry :("
	exit 2
fi

# Starting copy from NAS to Desktop
echo -e "${LP}Copying software from NAS to /Desktop${NC}"

## If new versions are needed and the name is changed on the installer, change the file name to match in the path here
# Copy Example DMG
cp ~/Desktop/Mount/onboarding_software/Example.dmg ~/Desktop &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Example.dmg Copied"
else
	echo -e "${LR}ERROR:${NC} Failed to Copy Example.dmg"
fi

# Copy onboarding library for new user
# In our case, I created plist files for various settings and stored these in the NAS
# This ensured we could have a fresh OS install but copy relevant settings 
echo -e "${LP}Copying onboarding_library to /Desktop, this one takes a while${NC}"
cp -r ~/Desktop/Mount/onboarding_library ~/Desktop &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} onboarding_library Copied"
else
	echo -e "${LR}ERROR:${NC} Failed to Copy onboarding_library"
fi

# Copy scripts for new user
# There were some additional scripts that would need to be run after a reboot, this was where those scripts were stored
echo -e "${LP}Copying scripts to /Desktop, this one takes a while${NC}"
cp -r ~/Desktop/Mount/scripts ~/Desktop &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Scripts Copied"
else
	echo -e "${LR}ERROR:${NC} Failed to Copy Scripts"
fi

echo -e "${LP}Starting downloads to /Desktop${NC}"

# Executing Example Script from scripts folder
# Some scripts were kept separate, either for maintenance sake or order of operations
echo -e "${LP}Executing Example Script${NC}"
cd ~/Desktop/scripts/ &&
sudo ./example.sh 

# Below are some examples of downloading fresh versions of some of the tools we would need
# If the download path is no longer working, the download path can be changed to the new download path

# Download Printer Drivers (10/22/19 release version 10.19.1 w/support for Catalina)
curl -O http://downloads.canon.com/bicg2019/drivers/mac/UFRII_v10.19.1_Mac.zip &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Printer Drivers Downloaded"
	open UFRII_v10.19.1_Mac.zip && rm UFRII_v10.19.1_Mac.zip
else
	echo -e "${LR}ERROR:${NC} Failed to Download Printer Drivers"
fi

# Download GPG Suite (change with version release, unable to find dynamic link)
curl -O https://releases.gpgtools.org/GPG_Suite-2019.2.dmg &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} GPG Suite Downloaded"
else
	echo -e "${LR}ERROR:${NC} Failed to Download GPG Suite"
fi

# Download current copy of google chrome
curl -O https://dl.google.com/chrome/mac/stable/CHFA/googlechrome.dmg &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Google Chrome Downloaded"
else
	echo -e "${LR}ERROR:${NC} Failed to Download Google Chrome"
fi

# Download current copy of slack
curl -O https://downloads.slack-edge.com/mac_releases/Slack-4.4.2-macOS.dmg &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Slack Downloaded"
else
	echo -e "${LR}ERROR:${NC} Failed to Download Slack"
fi

echo -e "${LP}Starting to install software${NC}"
echo -e "${LR}DO NOT RESPOND YES UNTIL ALL IMAGES HAVE FINISHED OPENING${NC}"
# Opening all .dmg files on the Desktop, depending on the machine, this could take a bit
retry 3 open *.dmg &&

# Prompt to let the machine finish downloading all disk images
read -p "Are you ready to install the applications? (y/n)? " INSTALL

# Ensures admin is ready (all dmgs have opened)
until [[ $INSTALL = "y" ]]; do
	echo -e "${LR} It sounds like you aren't ready yet${NC}"
	read -p "Are you ready to install the applications? (y/n)? " INSTALL
done

# When updated, an app may change its installer info but not very likely, these may need updating in the future
# Installing Chrome
sudo cp -R "/Volumes/Google Chrome/Google Chrome.app" /Applications &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Google Chrome Installed"
	sudo hdiutil detach "/Volumes/Google Chrome" && rm -f ~/Desktop/googlechrome.dmg
else
	echo -e "${LR}ERROR:${NC} Failed to Install Google Chrome"
fi

# Installing Slack
sudo cp -R "/Volumes/Slack.app/Slack.app" /Applications &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Slack Installed"
	sudo hdiutil detach "/Volumes/Slack.app" && rm -f  ~/Desktop/Slack-4.4.2-macOS.dmg
else
	echo -e "${LR}ERROR:${NC} Failed to Install Slack"
fi

# Installing GPG
sudo installer -package "/Volumes/GPG Suite/Install.pkg" -target "/Volumes/Macintosh HD" &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} GPG Suite Installed"
	sudo hdiutil detach "/Volumes/GPG Suite" && rm -f  ~/Desktop/GPG_Suite-2019.2.dmg
else
	echo -e "${LR}ERROR:${NC} Failed to Install GPG Suite, trying something else."
fi

# Installing Printer Drivers
sudo installer -package "/Volumes/mac-UFRII-LIPSLX-v10191-02/UFRII_LT_LIPS_LX_Installer.pkg" -target "/Volumes/Macintosh HD" &&
if [ "$?" -eq "0" ]
then
	echo -e "${LG}SUCCESS:${NC} Printer Drivers Installed"
	sudo hdiutil detach "/Volumes/mac-UFRII-LIPSLX-v10191-02" && rm -f  ~/Desktop/UFRII_v10.19.1_Mac.dmg
else
	echo -e "${LR}ERROR:${NC} Failed to Install Printer Drivers"
fi

# Promts to see if admin would like to execute new user script
# We had a separate script for creating a new user
# This allowed us to prep machines with this script, then days/weeks later, run the new user script manually
# Or, if we were ready, prep the machine and create the new user in one go
read -p "Would you like to create a new user right now? (y/n)? " CHOICE
if [ "$CHOICE" = "y" ]
then
    echo -e "${LP}Starting script for new user${NC}"
    sudo ./create-new-user-catalina.sh
else
    echo -e "${LR}Bye Felicia${NC}"
    exit 2
fi

echo -e "${LC}Software Setup Script Completed, You're Welcome :P${NC}"

exit 0
