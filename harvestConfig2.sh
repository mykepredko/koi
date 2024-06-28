#! /bin/bash

# Part of automating the process of creating the initial Katapult/Klipper firmware image on a host 

# This script performs the following actions:
# - Checks to see that a destination filename is provided
# - Reads the contents of ~/klipper/.config into a variable
#   - If nothing, then message and return
# - Reads the contents of ~/Katapult/.config into a variable
#   - If nothing, then message and return
# - Stores the two variables into the destination filename

# To execute the script from Github, use the Linux command line statement:
#  bash <(curl -s https://raw.githubusercontent.com/mykepredko/koi/main/harvestConfig2.sh) configFileName


# Written by: myke predko
# Last Update: 2023.10.17

# Questions and problems to be reported at https://klipper.discourse.group

# This software has only been tested on Raspberry Pi 4B and CM4 as well as the BTT CB1

# Users of this software run at their own risk as this software is "As Is" with no Warranty or Guarantee.  


# Echo Colour Specifications
echoGreen(){
    echo -e "\e[32m${1}\e[0m"
}
echoRed(){
    echo -e "\e[31m${1}\e[0m"
}
echoBlue(){
    echo -e "\e[34m${1}\e[0m"
}
echoYellow(){
    echo -e "\e[33m${1}\e[0m"
}


# Mainline code follows
echoYellow "Flash Katapult and klipper into main controller board"

if [ "$1" == "" ]; then
  echoRed "No destination filename specified"
  exit 1
fi

klipperConfig=$(<~/klipper/.config)
if [ klipperConfig == "" ]; then
  echoRed "No `~/klipper/.config` file"
  exit 1
fi
# echo "$klipperConfig"

NEWLINE=$'\n'
klipperConfigAfter=${klipperConfig#*"CONFIG_INITIAL_PINS"}
klipperConfigBefore=${klipperConfig%"CONFIG_CANBUS_FREQUENCY="*}
klipperConfigFinal=$klipperConfigBefore"CONFIG_CANBUS_FREQUENCY=%%%000${NEWLINE}CONFIG_INITIAL_PINS"$klipperConfigAfter

katapultConfig=$(<~/Katapult/.config)
if [ katapultConfig == "" ]; then
  echoRed "No `~/Katapult/.config` file"
  exit 1
fi
# echo "$katapultConfig"

katapultConfigAfter=${katapultConfig#*"CONFIG_INITIAL_PINS"}
katapultConfigBefore=${katapultConfig%"CONFIG_CANBUS_FREQUENCY="*}
katapultConfigFinal=$katapultConfigBefore"CONFIG_CANBUS_FREQUENCY=%%%000${NEWLINE}CONFIG_INITIAL_PINS"$katapultConfigAfter

echoYellow "Creating file $1.menuconfig"
echo -e "klipper=\n$klipperConfigFinal\n" > $1.menuconfig
echo -e "Katapult=\n$katapultConfigFinal" >> $1.menuconfig
