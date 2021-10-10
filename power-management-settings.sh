#!/bin/bash

###############################################################################

# Description    :  Script designed to update PMSET values for users running Mojave/Catalina (10.14.X - 10.15.X)
# 					This solves for unexpected shutdowns when the machine is not in use after enabling filevault
#                   Suggested to review values and modify as needed

# Author         :  Miah Bentley

# Version        :  1.4

# Date           :  2021.10.10

###############################################################################

# Color variables, because I like pretty scripts
NC='\033[0m' #No Color
LR='\033[1;31m' #Light Red
LG='\033[1;32m' #Light Green
LP='\033[1;35m' #Light Purple
LC='\033[1;36m' #Light Cyan

# Success and Error messages are echoed based on the return code on the command used.

read -rp "This script must be run as an Admin. Continue (y/n)? " CHOICE
if [ "$CHOICE" = "y" ]
then
	echo -e "${LP}YAAAAS! Let's do this!${NC}";
else
	echo -e "${LR}Booooo, come back later.${NC}"
	exit 0
fi
	
#When a Mac using FileVault encryption is placed into standby mode, 
#a FileVault key is stored in EFI so that it can quickly come out of standby mode when woken from deep sleep. 
#This is set to 1 so OS X will automatically destroy the FileVault key when it’s placed in power-saving standby mode, 
#preventing the stored key from being a potential weak point or attack target. 
if sudo pmset -a DestroyFVKeyOnStandby 1; 
then
	echo -e "${LG}SUCCESS:${NC} DestroyFVKeyOnStandby set to 1"
else
	echo -e "${LR}ERROR:${NC} Setting DestroyFVKeyOnStandby failed"
fi

#specifies the delay, in seconds, before writing the hibernation image to disk and powering off memory for standby; 
#(Use an argument of 0 to set the idle time to never)
#Setting Value to 30 hours, machine can be expected to shutdown over the weekend but not overnight.
#*Note: In Mac OSX Mojave, you have standbydelayhigh and standbydelaylow. 
#These allow you to vary your standby time based on battery percentage. 
#High will be used when your battery is over 50% and Low will be used when the batter is under 50%.
if sudo pmset -a standbydelaylow 108000;
then
	echo -e "${LG}SUCCESS:${NC} standbydelaylow set to 108000"
else
	echo -e "${LR}ERROR:${NC} Setting standbydelaylow failed"
fi

if sudo pmset -a standbydelayhigh 108000;
then
	echo -e "${LG}SUCCESS:${NC} standbydelayhigh set to 108000"
else
	echo -e "${LR}ERROR:${NC} Setting standbydelayhigh failed"
fi

#The time in minutes before hard disks are spun down and put to sleep; 
#(Use an argument of 0 to set the idle time to never)
if sudo pmset -a disksleep 120;
then
	echo -e "${LG}SUCCESS:${NC} disksleep set to 120"
else
	echo -e "${LR}ERROR:${NC} Setting disksleep failed"
fi

#is the time in minutes to system sleep; 
#(Use an argument of 0 to set the idle time to never)

if sudo pmset -a sleep 90;
then
	echo -e "${LG}SUCCESS:${NC} sleep set to 90"
else
	echo -e "${LR}ERROR:${NC} Setting sleep failed"
fi

# is the time in minutes before the display is put to sleep; 
#0 indicates that the display is never put to sleep
if sudo pmset -a displaysleep 10;
then
	echo -e "${LG}SUCCESS:${NC} displaysleep set to 10"
else
	echo -e "${LR}ERROR:${NC} Setting displaysleep failed"
fi

echo -e "${LC}Script Completed, You're Welcome :P${NC}"

exit 0
