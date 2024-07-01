#! /bin/bash

# Katapult Optimized Imaging (KOI)
#   This application provides a basic menu based approach to
#  specifying the Katapult and Klipper firmware for a 3D 
#  printer's main controller board and, optionally, a CAN
#  toolhead controller
#
# Written by: myke predko
# mykepredko@3dapothecary.xyz
# (C) Copyright 2024 for File Contents and Data Formatting

#function koiVersion {
koiVersion() {
  ver="0.01" # Initial Version to work out menu format & operation
  ver="0.02" # Increase Menu Width to 74 (from 70)
             # Get the "host" working and reading files from github
  ver="0.03" # Read through the Github files and separate out "host", "main" and "toolhead" into their own arrays at the start
             # Remove the "version" information from the "host" search criteria
             # Change the Splash Screen to all "KOI" letters
             # - Won't work with changing the color/Put in splat ("*") characters instead
             # - Goal is to have a fish outline on the splash screen
             # Figure out how to get it to work executing from "curl"
             # - Use format: "bash <(curl -s https://raw.githubusercontent.com/mykepredko/klipperScripts/main/KOI_#_##.sh)" where "#_##" is ver
  ver="0.04" # Changed repository from "klipperScripts" to "koi"
             # - Use sub folders for "host", "main" and "tool" configuration files
             # Bring in user selected host to use the same code as automatically detected host for connections
             # Provide user with list of "main" boards to choose from
  ver="0.05" # Redoing the Host and Main lists so that the displayed information comes from the file names rather reading from individual files
             # Moved virginSystemCheck method to after system selection/configuration so it can be tested on other systems
             # Provide user with ability to select the communications method between host and main
             # In "drawConfigFlow", rather than center the graphics, put everything 1 column from the left outline "##"
             #+ Provide user with ability to select the programming method for the "main" boards ("USB DFU" or "SD Card" Expected)
             # + If there is only one method, then that comes up automatically
             # + Have to figure out what to do with Embedded USB
             # Created "newLine" variable to eliminate need to add "\n" or an explicit new line in a string
             # Add "tags" to displaying strings in "drawConfigFlow" to bring in color with hopefully not too much of a processing delay
             # Came up with an integrated method for displaying which host/main communication option to use and verifying the selection
  echo "$ver"
             # Redo approach for USB Cables: Need to support rPi Zero 2W's USB OTG
}

# Command Line Options:
#  Ideally none.  All options selected from the menu
#   Adding -nvc for "No Virgin Check" to allow testing on system that are already configured

# Application Goals and Guidelines
# 1. User only has to SSH into the host once for setupHost
# 1.1. Assumes (and checks to see) that OS image does NOT have Klipper, KIAUH or Katapult
# 1.2. Would like to have Klipper Macros for Updating main and tool boards
# 1.3. If updating/changing 3D printer system, then user must run KOI again with a new 'NIX image
# 2. Standard hardware/modified hardware not supported
# 2.1. Host -> main controller [-> CAN toolhead] with embedded and U2C CAN controllers supported
# 2.2. Have to decide if multiple toolhead controllers will be supported
# 2.3. This includes the need for attaching something like ST-Link/J-Link SWD/JTAG interfaces to the boards
# 3. Will not be faster than manual process despite being automated/Error less likely
# 3.1. Automate everything that makes sense
# 3.1.1. Generate all necessary files for operation (ie "/etc/network/interfaces.d/can0")
# 3.2. Ideally bring in Klipper predefined printer.cfg files
# 3.2.1. Need to figure out how to manage tool definition
# 4. Will use ASCII graphics to help users understand process
# 5. Initial system created by myke predko using familiar parts
# 5.1. For other main and tool board files/information provided by other users/Process TBD
# 6. Katapult is loaded as Klipper bootloader
# 6.1. If DFU is available on the board, the firmware bootloader that comes with the board will be overwritten
# 7. Eliminate the need for the user to copy files onto a system for the SD Card Katapult firmware Load
# 7.1. Use host's USB port for this
# 7.2. If the host can't support this operation then it will not be used.  
# 7.2.1. What does this mean for the Raspberry Pi Zero?
# 7.3. This will use Myke Predko's "SDL" script as a basis
# 8. Totally Web based/All required application files on github
# 8.1. User does not have to load any software before executing "curl"
# 8.2. User can SSH in from default terminal programs on Windows (10 & later), Mac OS and Linux
# 8.3. TESTED - WORKS ON ALL BASIC TERMINALS PLUS TERA TERM & PUTTY
# 9. Not a "What If" tool.  The assumption is that the user has selected the hardware and has the printer ready
# 9.1. It is assumed that the main controller board will be powered by an external power supply, as it would be in the printer
# 9.2. If host to main controller is serial, then it is assumed the main controller will be powering the host
# 10. Will provide the necessary instructions for the user to carry out the imaging without outside references
# 10.1. The instructions will be parrotted to the display and a log file
# 11. Will NOT brick the user's main or toolhead controllers.
# 11.1. This does not mean that the original bootloader will not be overwritten using DFU but it can be reloaded using DFU
# 12. Avoid replicating data or code.  This is here because it seems to be something of a challenge for working with scripting languages
# 12.1. A big challenge is reading through data files and finding different pieces of data reliably
# 13. Work with assumptions to minimize choices that can result in more complexity/work by the user
# 13.1. Main Controllers that take embedded CM4/CB1/CB2 will only provide this path to the User
# 13.2. Main Controller is assumed to power host where ever possible (Serial most comfortable and USB use one wire power)
# 13.3. Main Controller with CAN interface will use this rather than a separate U2C and will be the Master

# To execute the script from Github, use the Linux command line statement:
#  bash <(curl -s https://raw.githubusercontent.com/mykepredko/koi/main/koi.sh)

# This Application requires:
# - Host Internet Connection
# - The host is connected to the main controller using USB
# - The main controller board is in DFU mode
# - The specified https://raw.githubusercontent.com/mykepredko/klipperScripts/main/*.menuconfig file exists 
# - The https://raw.githubusercontent.com/mykepredko/klipperScripts/main/can0 file exists
# - The https://raw.githubusercontent.com/mykepredko/klipperScripts/main/mcu.cfg prototype file exists

# This script performs the following actions:
# - Displays Splash Screen for two seconds
# - Saves the user's home directory
# - Does a basic system update and needed application install:
#   - sudo apt update
#   - sudo apt upgrade -y
#   - sudo apt-get upgrade -y
#   - sudo apt-get install git -y 

# - Handles the command line options
#   + Displays the Manual Page Information when specified/Check and code in place but 
#   - Checks for the presence of the board menuconfig file
#   - Checks the optional data rate to make sure it's "250", "500" or "1000"
#   - Handles Erroneous command line options
# - 'sudo apt update' and 'sudo apt upgrade -y' to ensure the latest updates are loaded into the host
# - If KIAUH is not installed, then load it in
# + If Klipper (and Moonraker & Mainsail) are NOT installed
#   + Install them using the KIAUH methods
# + Else 
#   + Perform update to Klipper, Moonraker & Mainsail using KIAUH methods

# - If Katapult not installed 
#   - Install Katapult and pyserial
# - Load in the preconfigured Klipper firmware image for the specified main controller board
#   - Add the specified Speed to the Klipper .config file
# - make the preconfigured Katapult firmware image
# - Burn Katapult formware image into the main controller using DFU
# - Burn Klipper formware image into the main controller using Katapult
#   - Save the results of "ls /dev/serial/by-id"
# - Create the 'can0' file in /etc/network/interfaces.d
#   - Located at: https://raw.githubusercontent.com/mykepredko/klipperScripts/main/can0
#   - Add  the specified Speed to the can0 file
# - Update the https://raw.githubusercontent.com/mykepredko/klipperScripts/main/mcu.cfg file in ~/printer_data/config with the following information:
#   [mcu]
#   # board=[typeFromCommandLineArgument] - use "^^^"
#   # usb_serial=[$resultsOf"ls /dev/serial/by-id"] - use "###"
#   # canbus_speed=[$canDataRate] - use "%%%" and will be updated with the reboot script
#   canbus_uuid: use "@@@" <= This will ahve to be determined at a later time
#   # home_directory=&&&
#   #restart_method: command
#   [temperature_sensor mcu_temp]
#   sensor_type: temperature_mcu
# + Install KlipperScreen information for CM4 from: https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/compute-module/cmio-display.adoc#quickstart-guide-display-only
#   + Have to determine if running a CM4
# + Install acelerometer code from: https://www.klipper3d.org/Measuring_Resonances.html#software-installation
# - Delay 5s for CAN bus UUID to become available
# - Insert in mcu.cfg
# - Prompt user to set up for "KOItoolhead" by:
#   - Connecting the toolhead PCB to the host using a USB cable
#   - Place the toolhead PCB in DFU mode
#   - Execute "KOItoolhead"


# Files to check after execution:
#  ~/printer_data/config/mcu.cfg
#  /etc/network/interfaces.d/can0
#  ~/klipper/.config
#  ~/Katapult/.config

# To Load the Bash Debugger:
# BashDB Information: https://bashdb.sourceforge.net/
# BashDB Git Repository: https://sourceforge.net/p/bashdb/code/ci/master/tree/
# To Download, Modify to work with Bash 5.1 and install BashDB:
# BashDB Download: https://sourceforge.net/projects/bashdb/files/bashdb/5.0-1.1.2/bashdb-5.0-1.1.2.tar.gz/download
# To Extract BashDB: tar -xvzf bashdb-5.0-1.1.2.tar.gz
# sudo nano ~/bashdb-5.0-1.1.2/configure 
#     Search for ".0'" using ^W and change to ".1' | '5.1')"
# ./configure
# make
# Run "./bashdb filename.sh" from the ~/bashdb-5.0-1.1.2 directory
#
# May have to run as root user: sudo su
#
# bashdb Commands
#  action     condition  edit     frame    load     run     source  unalias  
#  alias      continue   enable   handle   next     search  step    undisplay
#  backtrace  debug      eval     help     print    set     step+   untrace  
#  break      delete     examine  history  pwd      shell   step-   up       
#  clear      disable    export   info     quit     show    tbreak  watch    
#  commands   display    file     kill     return   signal  trace   watche   
#  complete   down       finish   list     reverse  skip    tty   
#
#  "s[tep]" single steps/"Steps in"
#  "n[ext]" skips over methods
#  "c[ontinue]" executes to next breakpoint or end
#  "info break" lists active breakpoints

# Some Syntax checking options:
# "bash -n ./KOI_#_##.sh" to check for Logic errors
# "bash -u ./KOI_#_##.sh -something" to check for "unbounded variables" (ie not initialized) during execution

# Questions and problems to be reported at https://klipper.discourse.group

# This software has only been tested on Raspberry Pi 4B and CM4 as well as the BTT CB1

# Users of this software run at their own risk as this software is "As Is" with no Warranty or Guarantee.  


# Code Start - Start with Set and Save Environment so defining "BLACK" isn't so jarring
set -e

originalDir="$(pwd)"
cd ~
homeDirectory=`pwd`
rootFile=`ls ~ -al`
newLine="
"



########################################################################
# Github access methods and Variables
########################################################################
hostFileLocation="https://raw.githubusercontent.com/mykepredko/koi/main/hostcfg"
mainFileLocation="https://raw.githubusercontent.com/mykepredko/koi/main/maincfg"
toolFileLocation="https://raw.githubusercontent.com/mykepredko/koi/main/toolcfg"

API_URL="https://api.github.com"
REPO_OWNER="mykepredko"
REPO_NAME="koi"
endpoint="repos/$REPO_OWNER/$REPO_NAME/contents"
hostcfgArray=""
hostcfgArraySize=0
maincfgArray=""
maincfgArraySize=0
toolcfgArray=""
toolcfgArraySize=0
getGithubContents() {
folder="$1"

  curl -s "$API_URL/$endpoint/$folder" 
}
catalogHostGithubList() {

  githubHostFile=$(getGithubContents "hostcfg")
  
  hostStart="\"name\": \""
  hostEnd="\",$newLine    \"path"
  hostcfg=""
  githubHostFile=${githubHostFile#*$hostStart}
  lastHostFileName=""
  while [ "$githubHostFile" != "$lastHostFileName" ]; do
    hostFileName=$githubHostFile
    lastHostFileName=$hostFileName
    hostFileNameCheck=""
    while [ "$hostFileName" != "$hostFileNameCheck" ]; do
      hostFileNameCheck="$hostFileName"
      hostFileName=${hostFileName%$hostEnd*}  
    done
    if [ "$hostcfg" != "" ]; then
      hostcfg="$hostcfg$newLine"
    fi
    hostcfg="$hostcfg$hostFileName"
    githubHostFile=${lastHostFileName#*$hostStart}
  done  
  
  readarray -t hostcfgArray <<< $hostcfg
  hostcfgArraySize=${#hostcfgArray[@]}
}
catalogMainGithubList() {

  githubMainFile=$(getGithubContents "maincfg")
  
  mainStart="\"name\": \""
  mainEnd="\",$newLine    \"path"
  maincfg=""
  githubMainFile=${githubMainFile#*$mainStart}
  lastMainFileName=""
  while [ "$githubMainFile" != "$lastMainFileName" ]; do
    mainFileName=$githubMainFile
    lastMainFileName=$mainFileName
    mainFileNameCheck=""
    while [ "$mainFileName" != "$mainFileNameCheck" ]; do
      mainFileNameCheck="$mainFileName"
      mainFileName=${mainFileName%$mainEnd*}  
    done
    if [ "$maincfg" != "" ]; then
      maincfg="$maincfg$newLine"
    fi
    maincfg="$maincfg$mainFileName"
    githubMainFile=${lastMainFileName#*$mainStart}
  done  
  
  readarray -t maincfgArray <<< $maincfg
  maincfgArraySize=${#maincfgArray[@]}
}
catalogToolGithubList() {

  githubToolFile=$(getGithubContents "toolcfg")
  
  toolStart="\"name\": \""
  toolEnd="\",$newLine    \"path"
  toolcfg=""
  githubToolFile=${githubToolFile#*$toolStart}
  lastToolFileName=""
  while [ "$githubToolFile" != "$lastToolFileName" ]; do
    toolFileName=$githubToolFile
    lastToolFileName=$toolFileName
    toolFileNameCheck=""
    while [ "$toolFileName" != "$toolFileNameCheck" ]; do
      toolFileNameCheck="$toolFileName"
      toolFileName=${toolFileName%$mainEnd*}  
    done
    if [ "$toolcfg" != "" ]; then
      toolcfg="$toolcfg$newLine"
    fi
    toolcfg=$"$toolcfg$toolFileName"
    githubtoolFile=${lastToolFileName#*$mainStart}
  done  
  
  readarray -t toolcfgArray <<< $toolcfg
  toolcfgArraySize=${#toolcfgArray[@]}
}



########################################################################
# Display (Constant) Variables and Methods
########################################################################
BLACK='\e[0;30m'
RED='\e[0;31m'
GREEN='\e[0;32m'
BROWN='\e[0;33m'
BLUE='\e[0;34m'
PURPLE='\e[0;35m'
CYAN='\e[0;36m'
LIGHTGRAY='\e[0;37m'
DARKGRAY='\e[1;30m'
LIGHTRED='\e[1;31m'
LIGHTGREEN='\e[1;32m'
YELLOW='\e[1;33m'
LIGHTBLUE='\e[1;34m'
LIGHTPURPLE='\e[1;35m'
LIGHTCYAN='\e[1;36m'
WHITE='\e[1;37m'
BASE='\e[0m'

outline=$RED
highlight=$LIGHTBLUE
active=$LIGHTGRAY
inactive=$DARKGRAY
em=$YELLOW
re=$LIGHTGRAY

# Color tag definition
# %b - black, use $DARKGRAY
# %w - white, use $LIGHTGRAY (Basic color for ASCII Graphics)
# %y - yellow, use $YELLOW as baasic high light Color
# %r - red, use $RED
# %g - green, use $GREEN
# %c - Blueish/green, use $CYAN



########################################################################
# Display Methods
########################################################################
clearScreen() {
  printf "\ec"
}
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
drawHeader() {
headerName="$1"

  clearScreen
#                        111111111122222222223333333333444444444455555555556666666666
#              0123456789012345678901234567890123456789012345678901234567890123456789 
  echo -e "$outline$PHULLSTRING"
  version=$(koiVersion) 
  headerLength=${#headerName}
  versionLength=${#version}
  stringLength=$(( displayWidth - ( 4 + 4 + 4 + 2 + versionLength + headerLength )))
  echo -e "##$highlight  KOI $version ${EMPTYSTRING:0:$stringLength} ${1}  $outline##"

  echo -e "$PHULLSTRING$BASE"
}
#$# Eliminate "drawAppend()" - Just "doAppend" and if there is nothing to run, then go with that
drawAppend() {
#$# $1 strings to display

  for argument in "$@"; do
    appendString=$argument
    appendLength=${#appendString}
    stringLength=$(( displayWidth - ( 4 + 4 + 1 + appendLength )))
    echo -e "$outline##$highlight  $appendString ${EMPTYSTRING:0:$stringLength}  $outline##"
  done

  echo -e     "$PHULLSTRING$BASE"
}
doAppend() {
#$# $1 strings to display/execute

  for argument in "$@"; do
    appendString=$argument
    appendLength=${#appendString}
    if [ "!" == "${appendString:0:1}" ]; then
      appendString="${appendString:1}"
      appendLength=$(( $appendLength - 1 ))
    fi
    stringLength=$(( displayWidth - ( 4 + 4 + 1 + appendLength )))
    echo -e "$outline##$highlight  $appendString ${EMPTYSTRING:0:$stringLength}  $outline##"
  done

  echo -e     "$PHULLSTRING$BASE"
  
  for argument in "$@"; do
    appendString=$argument
    if [ "!" != "${appendString:0:1}" ]; then
      $appendString
    fi
  done
}
drawSplashScreen() {

  drawHeader "Splash Screen"
#                                     11111111112222222222333333333344444444445555555555666666666677        77
#                  01         2345678901234567890123456789012345678901234567890123456789012345678901        23 
fish1="$outline##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|...$WHITE####$inactive..|.........|.........|.........|.........$outline##
##$inactive..........|.........|.$WHITE#######$inactive.|.........|.........|.........|.........$outline##
##$inactive----------+---------+$WHITE########$inactive-+---------+---------+---------+---------$outline##
##$inactive..........|........$WHITE###########$inactive|.........|.........|.........|.........$outline##
##$inactive..........|.......$WHITE##############$inactive........|.........|.........|.........$outline##
##$inactive..........|......$WHITE################$inactive.......|.........|.........|.........$outline##
##$inactive..........|....$WHITE##################$inactive.......|.........|.........|.........$outline##
##$inactive----------+---$WHITE####################$inactive------+---------+-$WHITE#######$inactive-+-----$WHITE##$inactive--$outline##
##$inactive..........|$WHITE########################$inactive.....|......$WHITE####################$inactive...$outline##
##$inactive........$WHITE###############################$inactive.|...$WHITE######################$inactive....$outline##
##$inactive......$WHITE###########################################################$inactive.....$outline##
##$inactive.....$WHITE##########################################################$inactive.......$outline##
##$inactive----$WHITE###$inactive..$WHITE#####################################################$inactive--------$outline##
##$inactive..$WHITE#####$inactive..$WHITE####################################################$inactive.........$outline##
##$inactive..$WHITE##########################################################$inactive|.........$outline##
##$inactive..$WHITE#####################################################$inactive.....|.........$outline##
##$inactive...$WHITE###############################$inactive..$WHITE###########$inactive...|.........|.........$outline##
##$inactive----$WHITE#############################$inactive...$WHITE###########$inactive---+---------+---------$outline##
##$inactive.......$WHITE#########################$inactive....$WHITE############$inactive..|.........|.........$outline##
##$inactive..........$WHITE#####################$inactive......$WHITE###########$inactive..|.........|.........$outline##
##$inactive..........|..$WHITE###############$inactive..|.......$WHITE###########$inactive.|.........|.........$outline##
##$inactive..........|..$WHITE#####$inactive.$WHITE###########$inactive|........$WHITE###########$inactive|.........|.........$outline##
##$inactive----------+--$WHITE#####$inactive--+$WHITE############$inactive------$WHITE###########$inactive+---------+---------$outline##
##$inactive..........|..$WHITE#####$inactive..|..$WHITE###########$inactive......$WHITE###########$inactive.........|.........$outline##
##$inactive..........|..$WHITE###$inactive....|....$WHITE##########$inactive.....|.$WHITE########$inactive|.........|.........$outline##
##$inactive..........|..$WHITE##$inactive.....|.......$WHITE########$inactive....|...$WHITE#######$inactive.........|.........$outline##
##$inactive..........|.........|.........$WHITE#####$inactive.....|......$WHITE####$inactive.........|.........$outline##
##$inactive----------+---------+---------+---------+-------$WHITE###$inactive---------+---------$outline##
##$inactive..........|.........|.........|.........|.........$WHITE#$inactive.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##"
fish2="$outline##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|...$WHITE####$inactive..|.........|.........|.........|.........$outline##
##$inactive..........|.........|.$WHITE#######$inactive.|.........|.........|.........|.........$outline##
##$inactive----------+---------+$WHITE########$inactive-+---------+---------+---------+---------$outline##
##$inactive..........|........$WHITE###########$inactive|.........|.........|.........|.........$outline##
##$inactive..........|.......$WHITE##############$inactive........|.........|.........|.........$outline##
##$inactive..........|......$WHITE################$inactive.......|.........|.........|.........$outline##
##$inactive..........|....$WHITE##################$inactive.......|.........|.........|.........$outline##
##$inactive----------+---$WHITE####################$inactive------+---------+-$WHITE#######$inactive-+-----$WHITE##$inactive--$outline##
##$inactive..........|$WHITE########################$inactive.....|......$WHITE####################$inactive...$outline##
##$inactive........$WHITE###############################$inactive.|...$WHITE######################$inactive....$outline##
##$inactive......$WHITE###########################################################$inactive.....$outline##
##$inactive.....$WHITE##########################################################$inactive.......$outline##
##$inactive----$WHITE###$inactive..$WHITE#####################################################$inactive--------$outline##
##$inactive..$WHITE#####$inactive..$WHITE####################################################$inactive.........$outline##
##$inactive..$WHITE##########################################################$inactive|.........$outline##
##$inactive..$WHITE#####################################################$inactive.....|.........$outline##
##$inactive...$WHITE###############################$inactive..$WHITE###########$inactive...|.........|.........$outline##
##$inactive----$WHITE#############################$inactive...$WHITE###########$inactive---+---------+---------$outline##
##$inactive.......$WHITE#########################$inactive....$WHITE############$inactive..|.........|.........$outline##
##$inactive..........$WHITE#####################$inactive......$WHITE###########$inactive..|.........|.........$outline##
##$inactive..........|..$WHITE###############$inactive..|.......$WHITE###########$inactive.|.........|.........$outline##
##$inactive..........|........$WHITE###########$inactive|........$WHITE###########$inactive|.........|.........$outline##
##$inactive----------+---------+$WHITE############$inactive------$WHITE###########$inactive+---------+---------$outline##
##$inactive..........|.........|..$WHITE###########$inactive......$WHITE###########$inactive.........|.........$outline##
##$inactive..........|.........|....$WHITE##########$inactive.....|.$WHITE########$inactive|.........|.........$outline##
##$inactive..........|.........|.......$WHITE########$inactive....|...$WHITE#######$inactive.........|.........$outline##
##$inactive..........|.........|.........$WHITE#####$inactive.....|......$WHITE####$inactive.........|.........$outline##
##$inactive----------+---------+---------+---------+-------$WHITE###$inactive---------+---------$outline##
##$inactive..........|.........|.........|.........|.........$WHITE#$inactive.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##"
fish2="$outline##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|...$WHITE####$inactive..|.........|.........|.........|.........$outline##
##$inactive..........|.........|.$WHITE#######$inactive.|.........|.........|.........|.........$outline##
##$inactive----------+---------+$WHITE########$inactive-+---------+---------+---------+---------$outline##
##$inactive..........|........$WHITE###########$inactive|.........|.........|.........|.........$outline##
##$inactive..........|.......$WHITE##############$inactive........|.........|.........|.........$outline##
##$inactive..........|......$WHITE################$inactive.......|.........|.........|.........$outline##
##$inactive..........|....$WHITE##################$inactive.......|.........|.........|.........$outline##
##$inactive----------+---$WHITE####################$inactive------+---------+-$WHITE#######$inactive-+-----$WHITE##$inactive--$outline##
##$inactive..........|$WHITE########################$inactive.....|......$WHITE####################$inactive...$outline##
##$inactive........$WHITE###############################$inactive.|...$WHITE######################$inactive....$outline##
##$inactive......$WHITE##########.################################################$inactive.....$outline##
##$inactive.....$WHITE############.#############################################$inactive.......$outline##
##$inactive----$WHITE###$inactive..$WHITE#########.###########################################$inactive--------$outline##
##$inactive..$WHITE#####$inactive..$WHITE#########.##########################################$inactive.........$outline##
##$inactive..$WHITE################.#########################################$inactive|.........$outline##
##$inactive..$WHITE###############.#####################################$inactive.....|.........$outline##
##$inactive...$WHITE#############.#################$inactive..$WHITE###########$inactive...|.........|.........$outline##
##$inactive----$WHITE#############################$inactive...$WHITE###########$inactive---+---------+---------$outline##
##$inactive.......$WHITE#########################$inactive....$WHITE############$inactive..|.........|.........$outline##
##$inactive..........$WHITE#####################$inactive......$WHITE###########$inactive..|.........|.........$outline##
##$inactive..........|..$WHITE###############$inactive..|.......$WHITE###########$inactive.|.........|.........$outline##
##$inactive..........|........$WHITE###########$inactive|........$WHITE###########$inactive|.........|.........$outline##
##$inactive----------+---------+$WHITE############$inactive------$WHITE###########$inactive+---------+---------$outline##
##$inactive..........|.........|..$WHITE###########$inactive......$WHITE###########$inactive.........|.........$outline##
##$inactive..........|.........|....$WHITE##########$inactive.....|.$WHITE########$inactive|.........|.........$outline##
##$inactive..........|.........|.......$WHITE########$inactive....|...$WHITE#######$inactive.........|.........$outline##
##$inactive..........|.........|.........$WHITE#####$inactive.....|......$WHITE####$inactive.........|.........$outline##
##$inactive----------+---------+---------+---------+-------$WHITE###$inactive---------+---------$outline##
##$inactive..........|.........|.........|.........|.........$WHITE#$inactive.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
$PHULLSTRING$BASE"
  echo -e "$outline##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
##$inactive..........|.........|...$LIGHTRED####$inactive..|.........|.........|.........|.........$outline##
##$inactive..........|.........|.$LIGHTRED#######$inactive.|.........|.........|.........|.........$outline##
##$inactive----------+---------+$LIGHTRED########$inactive-+---------+---------+---------+---------$outline##
##$inactive..........|........$LIGHTRED##########$WHITE#$inactive|.........|.........|.........|.........$outline##
##$inactive..........|.......$LIGHTRED###########$WHITE###$inactive........|.........|.........|.........$outline##
##$inactive..........|......$LIGHTRED############$WHITE####$inactive.......|.........|......$LIGHTRED##.|.........$outline##
##$inactive..........|....$LIGHTRED############$WHITE######$inactive.......|.........|....$LIGHTRED####.|.........$outline##
##$inactive----------+---$LIGHTRED###########$WHITE#########$inactive------+---------+-$LIGHTRED#######$inactive-+-----$LIGHTRED##$inactive--$outline##
##$inactive..........|$LIGHTRED############$WHITE############$inactive.....|......$LIGHTRED####################$inactive...$outline##
##$inactive........$LIGHTRED################$WHITE#########$LIGHTRED######$inactive.|...$LIGHTRED######################$inactive....$outline##
##$inactive......$LIGHTRED##########$inactive.$LIGHTRED########$WHITE#######$LIGHTRED#################################$inactive.....$outline##
##$inactive.....$LIGHTRED############$inactive.$LIGHTRED######$WHITE#######$LIGHTRED##############$WHITE########$LIGHTRED##########$inactive.......$outline##
##$inactive----$LIGHTRED###$inactive..$LIGHTRED#########$inactive.$LIGHTRED####$WHITE########$LIGHTRED##########$WHITE###########$LIGHTRED##########$inactive--------$outline##
##$inactive..$LIGHTRED#####$inactive..$LIGHTRED#########$inactive.$LIGHTRED###$WHITE##########$LIGHTRED##########$WHITE#########$LIGHTRED##########$inactive.........$outline##
##$inactive..$LIGHTRED################$inactive.$LIGHTRED###$WHITE##########$LIGHTRED#########$WHITE#############$LIGHTRED######$inactive|.........$outline##
##$inactive..$LIGHTRED###############$inactive.$LIGHTRED#####$WHITE##########$LIGHTRED##########$WHITE##########$LIGHTRED##$inactive.....|.........$outline##
##$inactive...$LIGHTRED#############$inactive.$LIGHTRED####$WHITE###########$LIGHTRED##$inactive..$LIGHTRED########$WHITE###$inactive...|.........|.........$outline##
##$inactive----$LIGHTRED###$WHITE##$LIGHTRED###########$WHITE#########$LIGHTRED####$inactive...$LIGHTRED###########$inactive---+---------+---------$outline##
##$inactive.......$WHITE###$LIGHTRED##########$WHITE#######$LIGHTRED#####$inactive....$LIGHTRED############$inactive..|.........|.........$outline##
##$inactive..........$LIGHTRED############$WHITE#######$LIGHTRED##$inactive......$LIGHTRED###########$inactive..|.........|.........$outline##
##$inactive..........|..$LIGHTRED#######$WHITE#######$LIGHTRED#$inactive..|.......$LIGHTRED###########$inactive.|.........|.........$outline##
##$inactive..........|........$LIGHTRED###$WHITE######$LIGHTRED##$inactive|........$LIGHTRED###########$inactive|.........|.........$outline##
##$inactive----------+---------+$LIGHTRED##$WHITE#####$LIGHTRED#####$inactive------$LIGHTRED###########$inactive+---------+---------$outline##
##$inactive..........|.........|..$LIGHTRED###########$inactive......$LIGHTRED#########$WHITE##$inactive.........|.........$outline##
##$inactive..........|.........|....$LIGHTRED##########$inactive.....|.$LIGHTRED####$WHITE####$inactive|.........|.........$outline##
##$inactive..........|.........|.......$LIGHTRED########$inactive....|...$LIGHTRED####$WHITE###$inactive.........|.........$outline##
##$inactive..........|.........|.........$LIGHTRED#####$inactive.....|......$LIGHTRED####$inactive.........|.........$outline##
##$inactive----------+---------+---------+---------+-------$LIGHTRED###$inactive---------+---------$outline##
##$inactive..........|.........|.........|.........|.........$LIGHTRED#$inactive.........|.........$outline##
##$inactive..........|.........|.........|.........|.........|.........|.........$outline##
$PHULLSTRING$BASE"
}
drawError() {
errorHeaderMessage="$1"
errorString="$2"

  drawHeader "$errorHeaderMessage"
#                            1111111111222222222233333333334444444444555555555566666666667777
#                  01234567890123456789012345678901234567890123456789012345678901234567890123 
  echo -e "$outline##                                                                      ##
##  EEEEEEEEEEE   RRRRRRRR      RRRRRRRR         OOOOO      RRRRRRRR    ##
##  EEEEEEEEEEE   RRRRRRRRRR    RRRRRRRRRR     OOOOOOOOO    RRRRRRRRRR  ##
##  EEE     EEE   RRR     RRR   RRR     RRR   OOOO   OOOO   RRR     RRR ##
##  EEE           RRR     RRR   RRR     RRR   OOO     OOO   RRR     RRR ##
##  EEE           RRR     RRR   RRR     RRR   OOO     OOO   RRR     RRR ##
##  EEE            RRR   RRRR   RRR    RRR    OOO     OOO   RRR    RRR  ##
##  EEEEEE        RRRRRRRR      RRRRRRRR      OOO     OOO   RRRRRRRR    ##
##  EEEEEE        RRRRRRRR      RRRRRRRR      OOO     OOO   RRRRRRRR    ##
##  EEE           RRR RRR       RRR RRR       OOO     OOO   RRR RRR     ##
##  EEE           RRR  RRR      RRR  RRR      OOO     OOO   RRR  RRR    ##
##  EEE           RRR   RRR     RRR   RRR     OOO     OOO   RRR   RRR   ##
##  EEE     EEE   RRR    RRR    RRR    RRR    OOOO   OOOO   RRR    RRR  ##
##  EEEEEEEEEEE   RRR     RRR   RRR     RRR    OOOOOOOOO    RRR     RRR ##
##  EEEEEEEEEEE   RRR     RRR   RRR     RRR      OOOOO      RRR     RRR ##
##                                                                      ##
$PHULLSTRING"

  currentString="$errorString"
  while [[ $currentString != "" ]]; do
    read -a currentStringArray <<< $currentString
    currentStringArraySize=${#currentStringArray[@]}
    i=0
    currentString=""
    currentStringLength=0
    currentWord=${currentStringArray[$i]}
    currentWordLength=${#currentWord}
    while [ $displayWidth -gt $(( $currentStringLength + $currentWordLength + 6 )) ] && [ $i -lt $currentStringArraySize ]; do
      currentString="$currentString $currentWord"
      currentStringLength=${#currentString}
      i=$(( $i + 1 ))
      currentWord=${currentStringArray[$i]}
      currentWordLength=${#currentWord}
    done
    stringLength=$(( $displayWidth - ( 4 + 1 + $currentStringLength )))
    echo -e     "##$highlight $currentString${EMPTYSTRING:0:stringLength}$outline##"
    currentString=""
    while [ $i -lt $currentStringArraySize ]; do
      if [[ $currentString != "" ]]; then
        currentString="$currentString ${currentStringArray[$i]}"
      else 
        currentString="${currentStringArray[$i]}"
      fi
      i=$(( $i + 1 ))
    done
  done

  echo -e     "$PHULLSTRING$BASE"
}




########################################################################
# Host, Main & Toolhead Configuration Variables
########################################################################
hostCPUInfo=""
hostFileContents=""
hostMainConnection=""
menuMCU=""
menuMCUName=""
menuCANBUS=""
menuToolhead=""
menuToolheadName=""




########################################################################
# Configuration Display Variables and 
########################################################################
#                      1111111111222222222233333333334444444444555555555566666666667777
#            01234567890123456789012345678901234567890123456789012345678901234567890123
EMPTYSTRING="                                                                          "
PHULLSTRING="##########################################################################"
displayWidth=${#EMPTYSTRING}
CONNECTIONNoConnection=" $inactive        //          $outline##"
CONNECTIONUSB="         USB         $outline##"
CONNECTIONSerial="        Serial       $outline##"
PROGNoProg=" |$inactive PROG            "
PROGDFU=" | DFU             | $outline##"
PROGSDCard=" | SD Card         | $outline##"
PROGMSS=" | USB MSS         | $outline##"
outlinePoundPound="$outline##"
systemDiagram="                     $outlinePoundPound
 +- host ----------+ $outlinePoundPound
 | NAME            | $outlinePoundPound
 +--------+--------+ $outlinePoundPound
          |          $outlinePoundPound
CONNECTION
AFTERCONNECTION
 +- main ----------+ $outlinePoundPound
 | NAME            | $outlinePoundPound
 | VER X.XX        | $outlinePoundPound
 | MCU             | $outlinePoundPound
 | PROG            | $outlinePoundPound
 +--------+--------+ $outlinePoundPound
CANB1
CANB2
CANB3
 +- toolhead ------+ $outlinePoundPound
 | NAME            | $outlinePoundPound
 | VER X.XX        | $outlinePoundPound
 | MCU             | $outlinePoundPound
 | PROG            | $outlinePoundPound
 +-----------------+ $outlinePoundPound
                     $outlinePoundPound"
readarray -t systemDiagramArray <<< $systemDiagram
systemDiagramArraySize=${#systemDiagramArray[@]}
confirmationPromptList="Quit
Yes
No"
drawConfigFlowReturn=""
i=${systemDiagramArray[0]}
leftWidth=$(( ${#i} - ${#outlinePoundPound} ))
rightWidth=$(( ${#EMPTYSTRING} - ( $leftWidth + 6 ) )) # "6" is three times "##"
drawConfigFlow() {
configHeader="$1"
drawConfigGraphic="$2"
promptString="$3"
inputPrompts="$4"

  systemDiagramArrayFirstElement=${systemDiagramArray[0]}
  outlinePoundPound="$outline##"
  leftWidth=$(( ${#systemDiagramArrayFirstElement} - ${#outlinePoundPound} ))
  rightWidth=$(( ${#EMPTYSTRING} - ( $leftWidth + 6 ) )) # "6" is three times "##"
  leftLineSpace=$(( ${#systemDiagramArrayFirstElement} - ( ${#outlinePoundPound} + 6 ) ))

  readarray -t drawConfigGraphicArray <<< $drawConfigGraphic
  drawConfigGraphicArraySize=${#drawConfigGraphicArray[@]}
  
  readarray -t inputPromptsArray <<< "$inputPrompts"
  inputPromptsArraySize=${#inputPromptsArray[@]}
  
  i=0
  graphicWidth=0
  while [ $i -lt $drawConfigGraphicArraySize ]; do
    currentLine="${drawConfigGraphicArray[$i]}"
    currentWidth=$(( ${#currentLine} + 1 ))
    actualWidth=$currentWidth
    j=0
    while [ $j -lt $currentWidth ]; do
      if [[ ${currentLine:$j:1} == "%" ]]; then
        j=$(( $j + 2 ))
        actualWidth=$(( $actualWidth - 2 ))
      else
        j=$(( $j + 1 ))
      fi
    done
    if [[ $graphicWidth -lt $actualWidth ]]; then
      graphicWidth=$actualWidth
    fi
    i=$(( $i + 1 ))
  done

  drawHeader "$configHeader"
  connectionColor="$inactive"
  
  if [[ $graphicWidth -gt $rightWidth ]]; then
    echo -e "ERROR: Graphic is too wide for the window"
    exit 1
  fi
  
  i=0
  segmentNumber=0
  drawConfigGraphicLines=$systemDiagramArraySize
  if [[ $systemDiagramArraySize -lt $drawConfigGraphicArraySize ]]; then
    drawConfigGraphicLines=$(( $drawConfigGraphicArraySize + 2 ))
  elif [[ $systemDiagramArraySize -eq $drawConfigGraphicArraySize ]]; then
    drawConfigGraphicLines=$(( $drawConfigGraphicArraySize + 2 ))
  fi  
  while [ $i -lt $drawConfigGraphicLines ]; do
    if [[ $i -ge $systemDiagramArraySize ]]; then
      currentLine="$outline##${systemDiagramArray[0]}"
    else
      currentLinePrefix="${systemDiagramArray[$i]}"
      currentLinePrefix="${currentLinePrefix:0:5}"
      if [[ $currentLinePrefix == "     " ]]; then
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
      elif [[ $currentLinePrefix == " +- h" ]]; then
        if [[ "$menuHostDisplayName" != "" ]]; then
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
      elif [[ $currentLinePrefix == " +- m" ]]; then
        if [[ "$mainDisplayName" == "" ]]; then
          connectionColor=$inactive
        else
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        segmentNumber=1
      elif [[ $currentLinePrefix == " +- t" ]]; then
        if [[ "$menuToolheadName" == "" ]]; then
          connectionColor=$inactive
        else
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        segmentNumber=2
      elif [[ $currentLinePrefix == " +---" ]]; then
        if [ $segmentNumber -eq 0 ]; then
          if [[ "$menuHostDisplayName" == "" ]]; then
            connectionColor=$inactive
          else
            connectionColor=$active
          fi
        elif [ $segmentNumber -eq 1 ]; then
          if [[ "$mainDisplayName" == "" ]]; then
            connectionColor=$inactive
          else
            connectionColor=$active
          fi
        else 
          if [[ "$menuToolheadName" == "" ]]; then
            connectionColor=$inactive
          else
            connectionColor=$active
          fi
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
      elif [[ $currentLinePrefix == " | NA" ]]; then
        if [[ "$connectionColor" == "$inactive" ]]; then
          currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        elif [[ $segmentNumber -eq 0 ]]; then
          lineNameWidth=${#hostName}
          lineRight=$(( $leftLineSpace - $lineNameWidth  ))
          currentLine="$outline##$connectionColor | $hostName${EMPTYSTRING:0:$lineRight} | $outline##"
        elif [[ $segmentNumber -eq 1 ]]; then
          lineNameWidth=${#mainDisplayName}
          lineRight=$(( $leftLineSpace - $lineNameWidth  ))
          currentLine="$outline##$connectionColor | $mainDisplayName${EMPTYSTRING:0:$lineRight} | $outline##"
        else # [[ $segmentNumber -eq 2 ]]; then
          lineNameWidth=${#menuToolheadName}
          lineRight=$(( $leftLineSpace - $lineNameWidth  ))
          currentLine="$outline##$connectionColor | $menuToolheadName${EMPTYSTRING:0:$lineRight} | $outline##"
        fi
      elif [[ $currentLinePrefix == " | VE" ]]; then
        if [[ "$connectionColor" == "$inactive" ]]; then
          currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        elif [[ $segmentNumber -eq 1 ]]; then
          lineNameWidth=${#menuMainVersion}
          lineRight=$(( $leftLineSpace - ( $lineNameWidth + 4 ) ))
          currentLine="$outline##$connectionColor | VER $menuMainVersion${EMPTYSTRING:0:$lineRight} | $outline##"
        else 
          if [[ "$menuToolheadName" == "" ]]; then
            connectionColor=$inactive
          else
            connectionColor=$active
          fi
        
        fi
      elif [[ $currentLinePrefix == " | MC" ]]; then
        if [[ "$connectionColor" == "$inactive" ]]; then
          currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        elif [[ $segmentNumber -eq 1 ]]; then
          lineNameWidth=${#menuMainProcessor}
          lineRight=$(( $leftLineSpace - $lineNameWidth ))
          currentLine="$outline##$connectionColor | $menuMainProcessor${EMPTYSTRING:0:$lineRight} | $outline##"
        else 
          if [[ "$menuToolheadName" == "" ]]; then
            connectionColor=$inactive
          else
            connectionColor=$active
          fi
        
        fi
      elif [[ $currentLinePrefix == " | PR" ]]; then
        if [[ "$connectionColor" == "$inactive" ]]; then
          currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        elif [[ $segmentNumber -eq 1 ]]; then
          if [[ $mainFirmwareLoadSelected == "" ]]; then
            if [ $mainFirmwareLoadArraySize -ne 1 ]; then
              currentLine="$outline##$connectionColor$PROGNoProg$connectionColor| $outline##"
            elif [[ $mainFirmwareLoad == "DFU" ]]; then
              currentLine="$outline##$connectionColor$PROGDFU"
              mainFirmwareLoadSelected="DFU"
            elif [[ $mainFirmwareLoad == "SD Card" ]]; then
              currentLine="$outline##$connectionColor$PROGSDCard"
              mainFirmwareLoadSelected="SD Card"
            elif [[ $mainFirmwareLoad == "Thumb Drive" ]]; then
              currentLine="$outline##$connectionColor$PROGSDCard"
              mainFirmwareLoadSelected="Thumb Drive"
            else
              currentLine="$outline##$connectionColor$PROGMSS"
              mainFirmwareLoadSelected="USB MSS"
            fi
          else 
            lineNameWidth=${#mainFirmwareLoadSelected}
            lineRight=$(( $leftLineSpace - $lineNameWidth ))
            currentLine="$outline##$connectionColor | $mainFirmwareLoadSelected${EMPTYSTRING:0:$lineRight} | $outline##"
          fi
        else 
          if [[ "$menuToolheadName" == "" ]]; then
            connectionColor=$inactive
          else
            connectionColor=$active
          fi
        
        fi
      elif [[ $currentLinePrefix == "CONNE" ]]; then
        if [[ "$hostMainConnection" == "" ]]; then
          connectionColor=$inactive
          currentLine="$outline##$connectionColor$CONNECTIONNoConnection"
        else
          connectionColor=$active
          if [[ "$hostMainConnection" == "USB" ]] || [[ "$hostMainConnection" == "Embedded USB" ]]; then
            currentLine="$outline##$connectionColor$CONNECTIONUSB"
          else # if [[ "$hostMainConnection" == "Serial" ]]; then
            currentLine="$outline##$connectionColor$CONNECTIONSerial"
          fi
        fi
      elif [[ $currentLinePrefix == "AFTER" ]]; then
        if [[ "$mainDisplayName" == "" ]]; then
          connectionColor=$inactive
        else
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[4]}"
      elif [[ $currentLinePrefix == "CANB1" ]]; then
        if [[ "$menuCANBUS" == "" ]]; then
          connectionColor=$inactive
        else
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[4]}"
      elif [[ $currentLinePrefix == "CANB2" ]]; then
        if [[ "$menuCANBUS" == "" ]]; then
          connectionColor=$inactive
          currentLine="$outline##$connectionColor${systemDiagramArray[4]}"
        else
          connectionColor=$active

        fi
      elif [[ $currentLinePrefix == "CANB3" ]]; then
        if [[ "$menuCANBUS" == "" ]]; then
          connectionColor=$inactive
        else
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[4]}"
      else 
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
      fi        
    fi
    
    if [[ $i -eq 0 ]]; then
      currentLine="$currentLine${EMPTYSTRING:0:$rightWidth}$outline##"
    else
      iGraphic=$(( $i - 1 ))
      if [[ $iGraphic -ge $drawConfigGraphicArraySize ]]; then
        currentLine="$currentLine${EMPTYSTRING:0:$rightWidth}$outline##"
      else 
        currentGraphicLine=${drawConfigGraphicArray[$iGraphic]}
        currentGraphicWidth=${#currentGraphicLine}
        actualGraphicWidth=${#currentGraphicLine}
        j=0
        while [ $j -lt $currentGraphicWidth ]; do
          if [[ ${currentGraphicLine:$j:1} == "%" ]]; then
            tempColor=$LIGHTGRAY
            if [[ ${currentGraphicLine:$(( $j + 1 )):1} == "b" ]]; then
              tempColor=$DARKGRAY
            elif [[ ${currentGraphicLine:$(( $j + 1 )):1} == "w" ]]; then
              tempColor=$LIGHTGRAY
            elif [[ ${currentGraphicLine:$(( $j + 1 )):1} == "y" ]]; then
              tempColor=$YELLOW
            elif [[ ${currentGraphicLine:$(( $j + 1 )):1} == "r" ]]; then
              tempColor=$RED
            elif [[ ${currentGraphicLine:$(( $j + 1 )):1} == "g" ]]; then
              tempColor=$GREEN
            elif [[ ${currentGraphicLine:$(( $j + 1 )):1} == "c" ]]; then
              tempColor=$LIGHTCYAN
            fi
            currentGraphicLine="${currentGraphicLine:0:j}$tempColor${currentGraphicLine:$(( $j + 2 ))}"
            j=$(( $j + 8 ))
            actualGraphicWidth=$(( $actualGraphicWidth - 2 ))
            currentGraphicWidth=$(( currentGraphicWidth + 6 ))
          else
            j=$(( $j + 1 ))
          fi
        done
        rightFiller=$(( $rightWidth - ( 1 + $actualGraphicWidth ) ))
        currentLine="$currentLine $active$currentGraphicLine${EMPTYSTRING:0:$rightFiller}$outline##"
      fi
    fi
    
    echo -e "$currentLine"
    
    i=$(( $i + 1 ))
  done

  echo -e     "$PHULLSTRING$BASE"
  
  invalidResponseString="Invalid Response  "
  invalidResponseStringLength=${#invalidResponseString}
  invalidResponseString="$YELLOW$invalidResponseString$LIGHTGRAY"
  promptString="$promptString (${inputPromptsArray[0]}"
  inputPromptsArrayTemp="${inputPromptsArray[0]}"
  inputPromptsArrayTemp="${inputPromptsArrayTemp^^}"
  inputPromptsArrayTemp="${inputPromptsArrayTemp:0:1}"
  inputPromptsArray[0]="$inputPromptsArrayTemp"
  i=1
  while [ $i -lt $inputPromptsArraySize ]; do
    promptString="$promptString/${inputPromptsArray[$i]}"
    inputPromptsArrayTemp="${inputPromptsArray[$i]}"
    inputPromptsArrayTemp="${inputPromptsArrayTemp^^}"
    inputPromptsArrayTemp="${inputPromptsArrayTemp:0:1}"
    inputPromptsArray[$i]="$inputPromptsArrayTemp"
    i=$(( $i + 1 ))
  done
  
  validFlag=0
  invalidPromptString=${EMPTYSTRING:0:invalidResponseStringLength}
  while [ $validFlag -eq 0 ]; do
    echo -n -e "$invalidPromptString"
    read -p "$promptString): " inputChar
    invalidPromptString="$invalidResponseString"
    if [[ "$inputChar" != "" ]]; then
      inputChar="${inputChar^^}"
      inputChar="${inputChar:0:1}"
      i=0
      while [ $i -lt $inputPromptsArraySize ] && [ $validFlag -eq 0 ]; do
        if [[ "$inputChar" == "${inputPromptsArray[$i]}" ]]; then
          validFlag=1
        fi
        i=$(( $i + 1 ))
      done
    fi
    if [ $validFlag -eq 0 ]; then
      echo -en "\033[1A\033[2K"
    fi
  done
  
  drawConfigFlowReturn="$inputChar"
}
drawConfigFlowConfirm() {
drawConfigHeader="$1"
drawConfigGraphic="$2"
drawConfigPrompt="$3"

  drawConfigFlowFlag=0
  while [ $drawConfigFlowFlag -eq 0 ]; do
    drawConfigFlow "$drawConfigHeader" "$drawConfigGraphic" "$drawConfigPrompt" "$confirmationPromptList"
    if [[ "$drawConfigFlowReturn" == "Q" ]]; then
      echo -e "Quit Application"
      exit 0
    elif [[ "$drawConfigFlowReturn" == "Y" ]] || [[ "$drawConfigFlowReturn" == "N" ]]; then
      drawConfigFlowFlag=1
    fi
  done
}      






########################################################################
# File System Methods
########################################################################
virginSystemCheck() {
  if [[ "$rootFile" == *"klipper"* ]]; then
    drawError "Image State Check" "\"klipper\" folder found in system. MUST start with blank system"
    exit 1
  elif [[ "$rootFile" == *"Katapult"* ]]; then
    drawError "Image State Check" "\"Katapult\" folder found in system. MUST start with blank system"
    exit 1
  elif [[ "$rootFile" == *"kiauh"* ]]; then
    drawError "Image State Check" "\"kiauh\" folder found in system. MUST start with blank system"
    exit 1
  fi
}
getHost() {
  hostCPUInfo=""
  hostModel=$'Model'
  colonSpace=": "
  cpuInfo=`cat /proc/cpuinfo`
  cpuInfoModel=${cpuInfo#*$hostModel}

  if [[ "$cpuInfo" != "$cpuInfoModel" ]] ; then
    cpuInfoModel=${cpuInfoModel#*$colonSpace}
    cpuInfoModel="${cpuInfoModel// /_}"
    cpuInfoModel="${cpuInfoModel/./_}"
    i=0
    while [ $i -lt $hostcfgArraySize ]; do
      hostElement=${hostcfgArray[$i]}
      hostElementSize=${#hostElement}
      if [[ "$hostElement" == "${cpuInfoModel:0:$hostElementSize}" ]]; then
        hostFileContents=`wget $hostFileLocation/$hostElement -O -`
        hostCPUInfo="$cpuInfoModel"
        break
      fi
      i=$(( $i + 1 ))
    done
  fi
}
hostName="";                          hostNameIndex=0
hostStatus="";                        hostStatusIndex=1
hostMatchName="";                     hostMatchNameIndex=2
hostConnections="";                   hostConnectionsIndex=3
hostConnectionsArray=""
hostConnectionsArraySize=0
hostBlock="";                         hostBlockIndex=4
hostEmbeddedUSB="";                   hostEmbeddedUSBIndex=5
hostUSB="";                           hostUSBIndex=6
hostSerial="";                        hostSerialIndex=7
hostCfgHeaders="HOSTNAME:
STATUS:
MATCHNAME:
CONNECTIONS:
BLOCKDIAGRAM:
USBEMBEDDEDCONNECTION:
USBCONNECTION:
SERIALCONNECTION:
EOF:"
readarray -t hostCfgHeadersArray <<< $hostCfgHeaders
setupHost() {
  hostName=${hostFileContents#*"${hostCfgHeadersArray[$hostNameIndex]}"}
  hostName=${hostName%"$newLine${hostCfgHeadersArray[$(( $hostNameIndex + 1 ))]}"*}
  hostStatus=${hostFileContents#*"${hostCfgHeadersArray[$hostStatusIndex]}"}
  hostStatus=${hostStatus%"$newLine${hostCfgHeadersArray[$(( $hostStatusIndex + 1 ))]}"*}
  hostMatchName=${hostFileContents#*"${hostCfgHeadersArray[$hostMatchNameIndex]}"}
  hostMatchName=${hostMatchName%"$newLine${hostCfgHeadersArray[$(( $hostMatchNameIndex + 1 ))]}"*}
  hostConnections=${hostFileContents#*"${hostCfgHeadersArray[$hostConnectionsIndex]}"}
  hostConnections=${hostConnections%"$newLine${hostCfgHeadersArray[$(( $hostConnectionsIndex + 1 ))]}"*}
  readarray -t hostConnectionsArray <<< $hostConnections
  hostConnectionsArraySize=${#hostConnectionsArray[@]}
  hostBlock=${hostFileContents#*"${hostCfgHeadersArray[$hostBlockIndex]}"}
  hostBlock=${hostBlock%"$newLine${hostCfgHeadersArray[$(( $hostBlockIndex + 1 ))]}"*}
  hostEmbeddedUSB=${hostFileContents#*"${hostCfgHeadersArray[$hostEmbeddedUSBIndex]}"}
  hostEmbeddedUSB=${hostEmbeddedUSB%"$newLine${hostCfgHeadersArray[$(( $hostEmbeddedUSBIndex + 1 ))]}"*}
  hostUSB=${hostFileContents#*"${hostCfgHeadersArray[$hostUSBIndex]}"}
  hostUSB=${hostUSB%"$newLine${hostCfgHeadersArray[$(( $hostUSBIndex + 1 ))]}"*}
  hostSerial=${hostFileContents#*"${hostCfgHeadersArray[$hostSerialIndex]}"}
  hostSerial=${hostSerial%"$newLine${hostCfgHeadersArray[$(( $hostSerialIndex + 1 ))]}"*}
}
menuMainFullName=""
menuMainProcessor=""
menuMainVersion=""
menuMainStatus=""
maincfgNameDecode() {
  tempMainFileName=$1
  menuMainStatus=${tempMainFileName#*"__"}
  menuMainStatus=${menuMainStatus#*"__"}        
  menuMainStatus=${menuMainStatus#*"__"} 
  menuMainStatus=${menuMainStatus:0:1}
  menuMainStatus=${menuMainStatus^^}
  menuMainProcessor=${tempMainFileName#*"__"}
  menuMainProcessor=${menuMainProcessor#*"__"}        
  menuMainProcessor=${menuMainProcessor%"__"*}
  menuMainVersion=${tempMainFileName#*"__"}        
  menuMainVersion=${menuMainVersion%"__"*}
  menuMainVersion=${menuMainVersion%"__"*}
  menuMainVersion=${menuMainVersion//_/.}
  menuMainFullName=${tempMainFileName%"__"*}
  menuMainFullName=${menuMainFullName%"__"*}
  menuMainFullName=${menuMainFullName%"__"*}
  menuMainFullName=${menuMainFullName//_/ }
}
mainCfgHeaders="DISPLAYNAME:
FIRMWARELOAD:
FIRMWARENAME:
CONNECTIONS:
KLIPPERPRINTERCFG:
BUILTINCAN:
KLIPPERSERIALCONFIGURATION:
KLIPPERUSBCONFIGURATION:
BLOCKDIAGRAM:
SDCARDFIRMARELOAD:
DFUFIRMARELOAD:
MSSFIRMWARELOAD:
THUMBFIRMWARELOAD:
USBEMBEDDEDCONNECTION:
USBCONNECTION:
USBWIRING:
SERIALCONNECTION:
SERIALWIRING:
EOF:"
readarray -t mainCfgHeadersArray <<< $mainCfgHeaders
mainDisplayName="";            mainDisplayNameIndex=0
mainFirmwareLoad="";           mainFirmwareLoadIndex=1
mainFirmwareLoadArray=""
mainFirmwareLoadArraySize=0
mainFirmwareLoadSelected=""
mainFirmwareName="";           mainFirmwareNameIndex=2
mainConnections="";            mainConnectionsIndex=3
mainConnectionsArray=""
mainConnectionsArraySize=0
mainConnectionsSelected=""
mainPrinterCfg="";             mainPrinterCfgIndex=4
mainBuiltInCAN="";             mainBuiltInCANIndex=5
mainSerialConfiguration="";    mainSerialConfigurationIndex=6
mainUSBConfiguration="";       mainUSBConfigurationIndex=7
mainBlock="";                  mainBlockIndex=8
mainSDFirmwareLoad="";         mainSDFirmwareLoadIndex=9
mainDFUFirmwareLoad="";        mainDFUFirmwareLoadIndex=10
mainUSBMSSFirmwareLoad="";     mainUSBMSSFirmwareLoadIndex=11
mainThumbFirmwareLoad="";      mainThumbFirmwareLoadIndex=12
mainEmbeddedUSB="";            mainEmbeddedUSBIndex=13
mainUSB="";                    mainUSBIndex=14
mainUSBWiring=""               mainUSBWiringIndex=15
mainSerial="";                 mainSerialIndex=16
mainSerialWiring=""            mainSerialWiringIndex=17
setupMain() {
  mainDisplayName=${menuMainFileContents#*"${mainCfgHeadersArray[$mainDisplayNameIndex]}"}
  mainDisplayName=${mainDisplayName%"$newLine${mainCfgHeadersArray[$(( $mainDisplayNameIndex + 1 ))]}"*}
  mainFirmwareLoad=${menuMainFileContents#*"${mainCfgHeadersArray[$mainFirmwareLoadIndex]}"}
  mainFirmwareLoad=${mainFirmwareLoad%"$newLine${mainCfgHeadersArray[$(( $mainFirmwareLoadIndex + 1 ))]}"*}
  readarray -t mainFirmwareLoadArray <<< $mainFirmwareLoad
  mainFirmwareLoadArraySize=${#mainFirmwareLoadArray[@]}
  mainFirmwareLoadSelected=""
  mainFirmwareName=${menuMainFileContents#*"${mainCfgHeadersArray[$mainFirmwareNameIndex]}"}
  mainFirmwareName=${mainFirmwareName%"$newLine${mainCfgHeadersArray[$(( $mainFirmwareNameIndex + 1 ))]}"*}
  mainConnections=${menuMainFileContents#*"${mainCfgHeadersArray[$mainConnectionsIndex]}"}
  mainConnections=${mainConnections%"$newLine${mainCfgHeadersArray[$(( $mainConnectionsIndex + 1 ))]}"*}
  readarray -t mainConnectionsArray <<< $mainConnections
  mainConnectionsArraySize=${#mainConnectionsArray[@]}
  mainConnectionsSelected=""
  mainPrinterCfg=${menuMainFileContents#*"${mainCfgHeadersArray[$mainPrinterCfgIndex]}"}
  mainPrinterCfg=${mainPrinterCfg%"$newLine${mainCfgHeadersArray[$(( $mainPrinterCfgIndex + 1 ))]}"*}
  mainBuiltInCAN=${menuMainFileContents#*"${mainCfgHeadersArray[$mainBuiltInCANIndex]}"}
  mainBuiltInCAN=${mainBuiltInCAN%"$newLine${mainCfgHeadersArray[$(( $mainBuiltInCANIndex + 1 ))]}"*}
  mainSerialConfiguration=${menuMainFileContents#*"${mainCfgHeadersArray[$mainSerialConfigurationIndex]}"}
  mainSerialConfiguration=${mainSerialConfiguration%"$newLine${mainCfgHeadersArray[$(( $mainSerialConfigurationIndex + 1 ))]}"*}
  mainUSBConfiguration=${menuMainFileContents#*"${mainCfgHeadersArray[$mainUSBConfigurationIndex]}"}
  mainUSBConfiguration=${mainUSBConfiguration%"$newLine${mainCfgHeadersArray[$(( $mainUSBConfigurationIndex + 1 ))]}"*}
  mainBlock=${menuMainFileContents#*"${mainCfgHeadersArray[$mainBlockIndex]}"}
  mainBlock=${mainBlock%"$newLine${mainCfgHeadersArray[$(( $mainBlockIndex + 1 ))]}"*}
  mainSDFirmwareLoad=${menuMainFileContents#*"${mainCfgHeadersArray[$mainSDFirmwareLoadIndex]}"}
  mainSDFirmwareLoad=${mainSDFirmwareLoad%"$newLine${mainCfgHeadersArray[$(( $mainSDFirmwareLoadIndex + 1 ))]}"*}
  mainDFUFirmwareLoad=${menuMainFileContents#*"${mainCfgHeadersArray[$mainDFUFirmwareLoadIndex]}"}
  mainDFUFirmwareLoad=${mainDFUFirmwareLoad%"$newLine${mainCfgHeadersArray[$(( $mainDFUFirmwareLoadIndex + 1 ))]}"*}
  mainUSBMSSFirmwareLoad=${menuMainFileContents#*"${mainCfgHeadersArray[$mainUSBMSSFirmwareLoadIndex]}"}
  mainUSBMSSFirmwareLoad=${mainUSBMSSFirmwareLoad%"$newLine${mainCfgHeadersArray[$(( $mainUSBMSSFirmwareLoadIndex + 1 ))]}"*}
  mainThumbFirmwareLoad=${menuMainFileContents#*"${mainCfgHeadersArray[$mainThumbFirmwareLoadIndex]}"}
  mainThumbFirmwareLoad=${mainThumbFirmwareLoad%"$newLine${mainCfgHeadersArray[$(( $mainThumbFirmwareLoadIndex + 1 ))]}"*}
  mainEmbeddedUSB=${menuMainFileContents#*"${mainCfgHeadersArray[$mainEmbeddedUSBIndex]}"}
  mainEmbeddedUSB=${mainEmbeddedUSB%"$newLine${mainCfgHeadersArray[$(( $mainEmbeddedUSBIndex + 1 ))]}"*}
  mainUSB=${menuMainFileContents#*"${mainCfgHeadersArray[$mainUSBIndex]}"}
  mainUSB=${mainUSB%"$newLine${mainCfgHeadersArray[$(( mainUSBIndex + 1 ))]}"*}
  mainUSBWiring=${menuMainFileContents#*"${mainCfgHeadersArray[$mainUSBWiringIndex]}"}
  mainUSBWiring=${mainUSBWiring%"$newLine${mainCfgHeadersArray[$(( mainUSBWiringIndex + 1 ))]}"*}
  mainSerial=${menuMainFileContents#*"${mainCfgHeadersArray[$mainSerialIndex]}"}
  mainSerial=${mainSerial%"$newLine${mainCfgHeadersArray[$(( mainSerialIndex + 1 ))]}"*}
  mainSerialWiring=${menuMainFileContents#*"${mainCfgHeadersArray[$mainSerialWiringIndex]}"}
  mainSerialWiring=${mainSerialWiring%"$newLine${mainCfgHeadersArray[$(( mainSerialWiringIndex + 1 ))]}"*}
}






########################################################################
# String Methods
########################################################################
stringAlign() {
  currentString="$1"
  specifiedWidth="$2"
  returnString=""
  read -a currentStringArray <<< $currentString
  currentStringArraySize=${#currentStringArray[@]}
  i=0
  while [ $i -lt $currentStringArraySize ]; do
    saveString=""
    saveWord=${currentStringArray[$i]}
    while [ $specifiedWidth -gt $(( ${#saveString} + ${#saveWord} + 3 )) ] && [ $i -lt $currentStringArraySize ]; do
	  if [[ $saveString == "" ]]; then
	    saveString=$saveWord
      else
        saveString="$saveString $saveWord"
      fi
      i=$(( $i + 1 ))
      saveWord=${currentStringArray[$i]}
    done
	if [[ $returnString == "" ]]; then
	  returnString="$saveString"
	else
	  returnString="$returnString$newLine$saveString"
	fi
  done
  echo "$returnString"
}



########################################################################
# KOI Mainline
########################################################################

# Set and Save Environment
set -e

drawSplashScreen

drawAppend "Cataloging configuration files."
catalogHostGithubList
catalogMainGithubList
catalogToolGithubList

quitPromptText="Quit"
yesPromptText="Yes"
verifyPromptText="Verify"
noPromptText="No"
hostPromptText="Host"
mainPromptText="Main"
cablePromptText="Cable"
embeddedUSBPromptText="Embedded USB"
USBPromptText="USB"
serialPromptText="Serial"

getHost
if [[ "$hostCPUInfo" == "" ]]; then

  base=0
  while : ; do
#$# Will have to support "Prev" and "Next" when having more than 9 host options
#$# Copy approach used later for main and tool controller boards
    hostSelectMessage="Select Host$newLine$newLine"
    promptList="Quit"
    i=0
    while [ $(( $i + $base )) -lt $hostcfgArraySize ] && [ $i -lt 9 ]; do
      tempHostName=${hostcfgArray[$(( $i + $base ))]}
      tempHostName=${tempHostName//_/ }
      i=$(( $i + 1 ))
      hostSelectMessage="$hostSelectMessage$i $tempHostName$newLine$newLine"
      promptList="$promptList$newLine$i"
    done

    while : ; do
      menuHostDisplayName=""
#$# Will have to support "Prev" and "Next" when having more than 9 host options
      drawConfigFlow "Select Host" "$hostSelectMessage" "Select Host" "$promptList"
      if [[ "$drawConfigFlowReturn" == "1" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 0 ))]}"
      elif [[ "$drawConfigFlowReturn" == "2" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 1 ))]}"
      elif [[ "$drawConfigFlowReturn" == "3" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 2 ))]}"
      elif [[ "$drawConfigFlowReturn" == "4" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 3 ))]}"
      elif [[ "$drawConfigFlowReturn" == "5" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 4 ))]}"
      elif [[ "$drawConfigFlowReturn" == "6" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 5 ))]}"
      elif [[ "$drawConfigFlowReturn" == "7" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 6 ))]}"
      elif [[ "$drawConfigFlowReturn" == "8" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 7 ))]}"
      elif [[ "$drawConfigFlowReturn" == "9" ]]; then
        hostInfo="${hostcfgArray[$(( $base + 8 ))]}"
      elif [[ "$drawConfigFlowReturn" == "Q" ]]; then
        echo -e "All Done!"
        exit 0
      fi
  
      hostFileContents=`wget $hostFileLocation/$hostInfo -O -`
      setupHost
      menuHostDisplayName="$hostName"

      drawConfigFlowConfirm "Confirm Selected Host" "$hostMatchName$newLine$newLine$hostBlock" "Confirm Selected Host"
      if [[ "$drawConfigFlowReturn" == "Y" ]]; then
        break 2
      fi
    done
  done
  
else
  setupHost 
  menuHostDisplayName="$hostName"
fi  


  
########################################################################
# Select the Main Controller board
########################################################################
maincfgMessage="Select Main Controller Board$newLine$newLine"
promptList="Quit"
i=0
while [ $i -lt $maincfgArraySize ] && [ $i -lt 9 ]; do
#$# Will have to support "Prev" and "Next" when having more than 7 main options
  mainInfo=${maincfgArray[$i]}
  i=$(( $i + 1 ))
  maincfgNameDecode $mainInfo
  tempMaincfgProcessorSize=${#menuMainProcessor}
  if [[ $menuMainStatus == "R" ]]; then
    maincfgMessage="$maincfgMessage$i $menuMainFullName"
  else 
    maincfgMessage="$maincfgMessage$i %y$menuMainFullName"
  fi
  maincfgMessage="$maincfgMessage$newLine  PROCESSOR: $menuMainProcessor ${EMPTYSTRING:0:$(( 9 - $tempMaincfgProcessorSize))} VERSION: $menuMainVersion$newLine$newLine"
  promptList="$promptList$newLine$i"
done

while : ; do
#$# Will have to support "Prev" and "Next" when having more than 7 main options
  mainDisplayName=""
  mainFirmwareLoadSelected=""
  drawConfigFlow "Select Main Controller Board" "$maincfgMessage" "Select Main Controller" "$promptList"
  mainConnection=$drawConfigFlowReturn
  if [[ "$drawConfigFlowReturn" == "1" ]]; then
    mainInfo="${maincfgArray[0]}"
  elif [[ "$drawConfigFlowReturn" == "2" ]]; then
    mainInfo="${maincfgArray[1]}"
  elif [[ "$drawConfigFlowReturn" == "3" ]]; then
    mainInfo="${maincfgArray[2]}"
  elif [[ "$drawConfigFlowReturn" == "4" ]]; then
    mainInfo="${maincfgArray[3]}"
  elif [[ "$drawConfigFlowReturn" == "5" ]]; then
    mainInfo="${maincfgArray[4]}"
  elif [[ "$drawConfigFlowReturn" == "6" ]]; then
    mainInfo="${maincfgArray[5]}"
  elif [[ "$drawConfigFlowReturn" == "7" ]]; then
    mainInfo="${maincfgArray[6]}"
  elif [[ "$drawConfigFlowReturn" == "8" ]]; then
    mainInfo="${maincfgArray[7]}"
  elif [[ "$drawConfigFlowReturn" == "9" ]]; then
    mainInfo="${maincfgArray[8]}"
  elif [[ "$drawConfigFlowReturn" == "Q" ]]; then
    echo -e "All Done!"
    exit 0
  fi
  
  menuMainFileContents=`wget $mainFileLocation/$mainInfo -O -`
  
  maincfgNameDecode $mainInfo
  setupMain

  mainFirmwareLoadSelected=""
  drawConfigFlowConfirm "Confirm Selected Main Controller" "$menuMainFullName$newLine$newLine$mainBlock" "Confirm Main Controller"
  if [[ "$drawConfigFlowReturn" == "Y" ]]; then
    break
  fi
done



########################################################################
# Select the communications method between main controller and host
# Set of options must be available to both host and main controller
########################################################################
promptList=$quitPromptText
i=0
sharedCOMMSArray=""
sharedCOMMS=0
while [ $i -lt $hostConnectionsArraySize ]; do
  j=0
  while [ $j -lt $mainConnectionsArraySize ]; do
    if [[ "${hostConnectionsArray[$i]}" == "${mainConnectionsArray[$j]}" ]]; then
      promptList="$promptList$newLine${hostConnectionsArray[$i]}"
	  sharedCOMMSArray[$sharedCOMMS]=${hostConnectionsArray[$i]}
      sharedCOMMS=$(( $sharedCOMMS + 1 ))
      break
    fi
    j=$(( $j + 1 ))
  done
  i=$(( $i + 1 ))
done

if [ $sharedCOMMS -eq 0 ]; then
  drawError "No Host/Main Common Communications" "No Common Communications Between $hostMatchName & $menuMainFullName"
  exit 1
fi

hostMainConnection=${sharedCOMMSArray[0]}
displayInfo="Main"
while : ; do
  headerList=$(stringAlign "$hostMatchName/$menuMainFullName" "$rightWidth")
  headerList="$headerList$newLine$newLine"
  promptList="$quitPromptText$newLine$verifyPromptText"
  if [[ ${sharedCOMMSArray[@]} =~ "Embedded USB" ]]; then
    if [[ $hostMainConnection == "Embedded USB" ]]; then
      headerList="$headerList %y< Embedded USB >%w$newLine$newLine"
      mainGraphic=$mainEmbeddedUSB
	else 
      headerList="$headerList   Embedded USB  $newLine$newLine"
      if [ $sharedCOMMS -ne 1 ]; then
        promptList="$promptList$newLine$embeddedUSBPromptText"
      fi
	fi
  fi
  i=0  # Using 'if [[ ${sharedCOMMSArray[@]} =~ "USB" ]]; then' will return a false true for "Embedded USB"
  while [[ ${sharedCOMMSArray[i]} != "USB" ]] && [ $i -lt $sharedCOMMS ]; do
    i=$(( $i + 1 ))
  done
  if [ $i -lt $sharedCOMMS ]; then
    if [[ $hostMainConnection == "USB" ]]; then
      headerList="$headerList %y< USB >%w$newLine"
      if [[ $displayInfo == "Host" ]]; then
        headerList="$headerList  %y< Host >%w$newLine"
        mainGraphic=$hostUSB
      else 
        headerList="$headerList    Host  $newLine"
      fi
      if [[ $displayInfo == "Main" ]]; then
        headerList="$headerList  %y< Main >%w$newLine"
        mainGraphic=$mainUSB
      else 
        headerList="$headerList    Main  $newLine"
      fi
      if [[ $displayInfo == "Cable" ]]; then
        headerList="$headerList  %y< Cable >%w$newLine$newLine"
        mainGraphic=$mainUSBWiring
      else 
        headerList="$headerList    Cable  $newLine$newLine"
      fi
	else 
      headerList="$headerList   USB  $newLine$newLine"
      if [ $sharedCOMMS -ne 1 ]; then
        promptList="$promptList$newLine$USBPromptText"
      fi
	fi
  fi
  if [[ ${sharedCOMMSArray[@]} =~ "Serial" ]]; then
    if [[ $hostMainConnection == "Serial" ]]; then
      headerList="$headerList %y< Serial >%w$newLine"
      if [[ $displayInfo == "Host" ]]; then
        headerList="$headerList  %y< Host >%w$newLine"
        mainGraphic=$hostSerial
      else 
        headerList="$headerList    Host  $newLine"
      fi
      if [[ $displayInfo == "Main" ]]; then
        headerList="$headerList  %y< Main >%w$newLine"
        mainGraphic=$mainSerial
      else 
        headerList="$headerList    Main  $newLine"
      fi
      if [[ $displayInfo == "Cable" ]]; then
        headerList="$headerList  %y< Cable >%w$newLine$newLine"
        mainGraphic=$mainSerialWiring
      else 
        headerList="$headerList    Cable  $newLine$newLine"
      fi
	else 
      headerList="$headerList   Serial  $newLine$newLine"
      if [ $sharedCOMMS -ne 1 ]; then
        promptList="$promptList$newLine$serialPromptText"
      fi
	fi
  fi
  if [[ $hostMainConnection != "Embedded USB" ]]; then
    if [[ $displayInfo != "Host" ]]; then
      promptList="$promptList$newLine$hostPromptText"
    fi
    if [[ $displayInfo != "Main" ]]; then
      promptList="$promptList$newLine$mainPromptText"
    fi
    if [[ $displayInfo != "Cable" ]]; then
      promptList="$promptList$newLine$cablePromptText"
    fi
  fi
  drawConfigFlow "Verify Host and Main Board Connection" "$headerList$mainGraphic" "Verify" "$promptList"
  if [[ "$drawConfigFlowReturn" == "V" ]]; then
    break
  elif [[ "$drawConfigFlowReturn" == "Q" ]]; then
    echo -e "All Done!"
    exit 0 
  elif [[ "$drawConfigFlowReturn" == "E" ]]; then
    hostMainConnection="Embedded USB"
  elif [[ "$drawConfigFlowReturn" == "U" ]]; then
    hostMainConnection="USB"
    displayInfo="Main"
  elif [[ "$drawConfigFlowReturn" == "S" ]]; then
    hostMainConnection="Serial"
    displayInfo="Main"
  elif [[ "$drawConfigFlowReturn" == "H" ]]; then
    displayInfo="Host"
  elif [[ "$drawConfigFlowReturn" == "M" ]]; then
    displayInfo="Main"
  elif [[ "$drawConfigFlowReturn" == "C" ]]; then
    displayInfo="Cable"
  fi
done

exit 0 #$# So execution doesn't start with the sudo instructions below



#$# Check for CAN toolhead controller

########################################################################
# Klipper & KIAUH CANNOT be Present before Loading/Building/Flashing
########################################################################
virginSystemCheck

drawHeader "Initial Resource Load"
doAppend "!Basic Updates and Installs:" "sudo apt update -y" "sudo apt upgrade -y" "sudo apt-get upgrade -y" "sudo apt-get install bc -y" "sudo apt-get install git -y"

#$# Load Klipper
#$# Load KIAUH

#$# Build Katapult/Klipper 

#$# IF NO CAN
#$#   Load main controller WITHOUT CAN with Katapult
#$#   End Here with loading main Controller with Klipper

#$# ELSE (CAN REQUIRED)
#$#   IF MAIN CONTROLLER CAN UED 
#$#     Load main controller WITH CAN with Katapult
#$#   ELSE 
#$#     setup U2C as CAN controller
#$#   Load main Controller with Klipper

#$#   Load toolhead controller WITH CAN with Katapult
#$#   Setup can0 

#$#   Reboot and Load toolhead controller with Klipper

exit 0






########################################################################
# Previous Mainline
########################################################################




# Check to see if Klipper is there and load/update it
loadOrUpdateKlipper() {
local instance_names  ##### - This is how the variable is declared in "start_klipper_setup"
local klipper_systemd_services


cd ~
rootFile=`ls ~ -al`

KIAUH_SRCDIR="$homeDirectory/kiauh"
for script in "${KIAUH_SRCDIR}/scripts/"*.sh; do . "${script}"; done
for script in "${KIAUH_SRCDIR}/scripts/ui/"*.sh; do . "${script}"; done
##### Above is from the start of kiauh.sh
check_euid
init_logfile
set_globals  
##### Above is at the End of kiauh.sh mainline
init_ini    ### save all installed webinterface ports to the ini file
##### Above is done in main_menu
if [[ "$rootFile" == *"klipper"* ]]; then
  echoYellow "Klipper installed"
  echoYellow "Updating Klipper"
  update_klipper
#  echoYellow "Updating Moonraker"
#  update_moonraker
#  echoYellow "Updating Mainsail"
#  update_mainsail
#  update_all
##### From update_menu
  echoGreen "Update of Klipper applications Complete!"
else
  echoRed "Klipper not installed"
  echoYellow "Executing 'run_klipper_setup \"3\" \"printer\"' in KIAUH Code"
  fetch_webui_ports
  set_multi_instance_names
##### Above is done in install_menu
  klipper_systemd_services=$(klipper_systemd)
  if [[ -n ${klipper_systemd_services} ]]; then
    echoRed "Klipper Instance already installed"
    exit 1
  fi
#### Above is done in "start_klipper_setup"    
  instance_names+=("printer")
  run_klipper_setup "3" "${instance_names[@]}"
    
  echoYellow "Executing 'moonraker_setup_dialog' in KIAUH Code"
  moonraker_setup_dialog
    
  echoYellow "Executing 'install_mainsail' in KIAUH Code"
  install_mainsail

  echoGreen "Klipper, Moonrake & Mainsail Installed!"
fi
}

# Load Katapult if it's not installed
loadKatapult() {
  cd ~
  rootFile=`ls ~ -al`
  if [[ "$rootFile" == *"Katapult"* ]]; then
    echoYellow "Katapult installed"
  else
    echoYellow "Loading Katapult and pyserial"
    git clone https://github.com/Arksine/Katapult
    sudo apt install python3-serial 
  fi
  return 0 # True
}

# Load KIAUH if it's not installed
loadKIAUH() {
  cd ~
  rootFile=`ls ~ -al`
  if [[ "$rootFile" == *"kiauh"* ]]; then
    echoYellow "KIAUH installed"
  else
    echoYellow "Loading KIAUH"
	git clone https://github.com/dw-0/kiauh.git
  fi
  return 0 # True
}

exitIfMainControllerUSBNotCorrect() {
  lsusbDevices=`lsusb`
  if [[ "$lsusbDevices" == *"${1}"* ]]; then
    return 0 # True
  else
    echoRed "Error - 'lsusb' does not return '${1}'"
    exit 1
  fi
}


# Mainline code follows
set -e
echoYellow "KOI - Klipper Optimized Installation"

cd ~
homeDirectory=`pwd`

# Check Input Parameters
# -h for help
# Look for main controller board menuconfig file
if [ "" == "$1" ]; then
  echoRed "No main controller board filename specified"
  exit 1
elif [ "-h" == "$1" ]; then
  echoRed "Put in Help Information for the application"
  exit 1
fi


menuConfigFileName="https://raw.githubusercontent.com/mykepredko/klipperScripts/main/$1.menuconfig"
if curl -f ${menuConfigFileName} >/dev/null 2>&1; then
  echoGreen "Specified main controller board filename found"
else
  echoRed "Specified main controller board filename not found"
  exit 1
fi
if [ "" = "$2" ]; then
  canDataRate="500"
elif [ "-s" != "$2" ]; then
  echoRed "Invalid Command Line Parameter"
  exit 1
elif [ "250" != "$3" ] && [ "500" != "$3" ] && [ "1000" != "$3" ]; then
  echoRed "Invalid CAN bus speed specified"
  exit 1
else
  canDataRate="$3"
fi
menuConfigFile=`wget https://raw.githubusercontent.com/mykepredko/klipperScripts/main/$1.menuconfig -O -`
klipperStart=$'klipper=\n'
katapultStart=$'\nKatapult=\n'
menuConfigFile=${menuConfigFile//$'%%%'/$canDataRate}
menuConfigKlipper=${menuConfigFile%$katapultStart*}
menuConfigKlipper=${menuConfigKlipper#*$klipperStart}
menuConfigKlipper=${menuConfigKlipper//$'\n'/\\n}

menuConfigKatapult=${menuConfigFile#*$katapultStart}
menuConfigKatapult=${menuConfigKatapult//$'\n'/\\n}



echoYellow "Check for Klipper, Katapult and main controller is in DFU mode"
exitIfMainControllerUSBNotCorrect "0483:df11"
loadKIAUH
loadOrUpdateKlipper


echoYellow "Load Katapult"
sudo service klipper stop
loadKatapult


# Build the firmware images
echoYellow "Build Katapult firmware image"
cd $homeDirectory/Katapult
make clean
echo -e $menuConfigKatapult > .config
make

echoYellow "Build Klipper firmware image"
# Use the downloaded config
# Set the CAN data rate
cd $homeDirectory/klipper
make clean
echo -e $menuConfigKlipper > .config
make


set +e  ### Ignore returned errors (primarily from the "dfu-util" statement following


echoYellow "Flash Katapult firmage image into main controller"
sudo dfu-util -a 0 -D ~/Katapult/out/katapult.bin --dfuse-address 0x08000000:force:mass-erase:leave -d 0483:df11
sleep 1s

echoYellow "Flash Klipper firmware into main controller"
lsDevice=`ls /dev/serial/by-id/`
echoRed "$lsDevice"
if [[ "$lsDevice" == *"No such file or directory"* ]]; then
  echoRed "\"No such file or directory\" Encountered after DFU programming."
  exit 1
fi
sudo python3 $homeDirectory/Katapult/scripts/flashtool.py -d /dev/serial/by-id/$lsDevice -f $homeDirectory/klipper/out/klipper.bin


set -e  ### Enable Stop on any errors encountered


echoYellow "Create can0 file in /etc/network/interfaces.d"
can0Contents=$(wget https://raw.githubusercontent.com/mykepredko/klipperScripts/main/can0 -O -)
can0Contents=${can0Contents//$'%%%'/$canDataRate}
can0Contents=${can0Contents//$'\n'/\\n}
can0Temp=$(mktemp)
echo -e $can0Contents > $can0Temp
sudo cp $can0Temp /etc/network/interfaces.d/can0
sudo chmod +r /etc/network/interfaces.d/can0


echoYellow "Create mcu.cfg file in ~/printer_data/config"
mcuCfgContents=$(wget https://raw.githubusercontent.com/mykepredko/klipperScripts/main/mcu.cfg -O -)
mcuCfgContents=${mcuCfgContents//$'%%%'/$canDataRate}
mcuCfgContents=${mcuCfgContents//$'^^^'/$1}
mcuCfgContents=${mcuCfgContents//$'###'/$lsDevice}
mcuCfgContents=${mcuCfgContents//$'&&&'/$homeDirectory}
mcuCfgContents=${mcuCfgContents//$'\n'/\\\\n}  
mcuCfgTemp=$(mktemp)
echo -e $mcuCfgContents > $mcuCfgTemp
sudo cp $mcuCfgTemp $homeDirectory/printer_data/config/mcu.cfg
sudo chmod +r $homeDirectory/printer_data/config/mcu.cfg


echoYellow "Install Code for CM4 KlipperScreen"
sudo wget https://datasheets.raspberrypi.com/cmio/dt-blob-disp1-only.bin -O /boot/firmware/dt-blob.bin


echoYellow "Install Code for Measuring Resonances"
sudo apt update
sudo apt install python3-numpy python3-matplotlib libatlas-base-dev 
~/klippy-env/bin/pip install -v numpy


echoYellow "Update mcu.cfg"
sleep 5s  # Give system some time to restart and have CAN bus set up
can0UUIDs=`$homeDirectory/Katapult/scripts/flash_can.py -i can0 -q`
klipperLeadUUID=${can0UUIDs%", Application: Klipper"*}
klipperUUID=${klipperLeadUUID#*"UUID: "}

mcuCfgRead=`cat $homeDirectory/printer_data/config/mcu.cfg`
sudo rm $homeDirectory/printer_data/config/mcu.cfg
mcuCfgRead=${mcuCfgRead//$'@@@'/$klipperUUID}
mcuCfgRead=${mcuCfgRead//$'\n'/\\n}
mcuCfgReadTemp=$(mktemp)
echo -e $mcuCfgRead > $mcuCfgReadTemp
sudo cp -f $mcuCfgReadTemp $homeDirectory/printer_data/config/mcu.cfg
sudo chmod +r $homeDirectory/printer_data/config/mcu.cfg

#  sudo service klipper restart

echoGreen "
############################################################
###                                                      ###
###  System Ready for Toolhead Connection/Flashing       ###
###                                                      ###
###  1. Connect the Toolhead to the host using USB       ###
###  2. Boot the Toolhead controller in DFU mode         ###
###  3. Finally, run 'KOItoolhead'                       ###
###                                                      ###
############################################################"
