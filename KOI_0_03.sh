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
  echo "0.03"
}
# Version information:
# 0.01 - Initial Version to work out menu format & operation
# 0.02 - Increase Menu Width to 74 (from 70)
#      - Get the "host" working and reading files from github
# 0.03 - Read through the Github files and separate out "host", "main" and "toolhead" into their own arrays at the start
#      - Remove the "version" information from the "host" search criteria
#      - Change the Splash Screen to all "KOI" letters
#        - Won't work with changing the color/Put in splat ("*") characters instead
#        - Goal is to have a fish outline on the splash screen
#      - Figure out how to get it to work executing from "curl"
#        - Use format: "bash <(curl -s https://raw.githubusercontent.com/mykepredko/klipperScripts/main/KOI_#_##.sh)"
#      + Bring in user selected host to use the same code as automatically detected host for connections
#      + Provide user with list of "main" boards to choose from
#      + Provide user with ability to select the programming method for the "main" boards ("USB DFU" or "SD Card" Expected)

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
# 5.1. For other main and tool board files/information provided by other users
# 6. Katapult is loaded as Klipper bootloader
# 6.1. If DFU is available on the board, the firmware bootloader that comes with the board will be overwritten
# 7. Eliminate the need for the user to copy files onto a system for the SD Card Katapult firmware Load
# 7.1. Use host's USB port for this
# 7.2. If the host can't support this operation then it will not be used.  
# 7.2.1. What does this mean for the Raspberry Pi Zero?
# 8. Totally Web based/All required application files on github
# 8.1. User does not have to load any software before executing "curl"
# 8.2. User can SSH in from default terminal programs on Windows (10 & later), Mac OS and Linux
# 8.3. TESTED - WORKS ON ALL BASIC TERMINALS PLUS TERA TERM & PUTTY
# 9. Not a "What If" tool.  The assumption is that the user has selected the hardware or using existing
# 10. Will provide the necessary instructions for the user to carry out the imaging without outside references
# 11. Will NOT brick the user's main or toolhead controllers.
# 11.1. This does not mean that the original bootloader will not be overwritten using DFU but it can be reloaded using DFU

# To execute the script from Github, use the Linux command line statement:
# curl -sSL https://raw.githubusercontent.com/mykepredko/klipperScripts/main/KOI_0_01.sh | bash

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
#     Search for "'5.0' | '5.0')" using ^W and change it to "'5.1' | '5.1')"
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
#  "info breakpoints" lists active breakpoints
#  "next" skips over methods

# Questions and problems to be reported at https://klipper.discourse.group

# This software has only been tested on Raspberry Pi 4B and CM4 as well as the BTT CB1

# Users of this software run at their own risk as this software is "As Is" with no Warranty or Guarantee.  


# Code Start - Start with Set and Save Environment so defining "BLACK" isn't so jarring
set -e

cd ~
homeDirectory=`pwd`
rootFile=`ls ~ -al`



########################################################################
# Github access methods and Variables
########################################################################
webFileLocation="https://raw.githubusercontent.com/mykepredko/klipperScripts/main"

API_URL="https://api.github.com"
REPO_OWNER="mykepredko"
REPO_NAME="klipperScripts"
endpoint="repos/$REPO_OWNER/$REPO_NAME/contents"
hostcfgArray=""
hostcfgArraySize=0
maincfgArray=""
maincfgArraySize=0
toolcfgArray=""
toolcfgArraySize=0
getGithubContents() {

  curl -s "$API_URL/$endpoint" 
}
catalogGithubList() {

  githubFile=$(getGithubContents)
  
  lastFile=""
  returnName="\"name\": \""
  hostcfg=""
  hostcfgReturnExtension=".hostcfg"
  maincfg=""
  maincfgReturnExtension=".maincfg"
  toolcfg=""
  toolcfgReturnExtension=".toolcfg"
  cfgReturnExtensionLength=${#hostcfgReturnExtension}
  while [ "$githubFile" != "$lastFile" ]; do
    lastFile="$githubFile"
    githubFile=${githubFile#*$returnName}
    i=0
    while [ "${githubFile:$i:1}" != "." ] && [ "${githubFile:$i:1}" != "\"" ]; do
      i=$(( $i + 1))
    done
    if [ "${githubFile:$i:$cfgReturnExtensionLength}" == "$hostcfgReturnExtension" ]; then
      if [ "$hostcfg" != "" ]; then
        hostcfg="$hostcfg
"
      fi
      hostcfg=$"$hostcfg${githubFile:0:$i}"
    elif [ "${githubFile:$i:$cfgReturnExtensionLength}" == "$maincfgReturnExtension" ]; then
      if [ "$maincfg" != "" ]; then
        maincfg="$maincfg
"
      fi
      maincfg=$"$maincfg${githubFile:0:$i}"
    elif [ "${githubFile:$i:$cfgReturnExtensionLength}" == "$toolcfgReturnExtension" ]; then
      if [ "$toolcfg" != "" ]; then
        toolcfg="$toolcfg
"
      fi
      toolcfg=$"$toolcfg${githubFile:0:$i}"
    fi
  done  
  
  readarray -t hostcfgArray <<< $hostcfg
  hostcfgArraySize=${#hostcfgArray[@]}
  readarray -t maincfgArray <<< $maincfg
  maincfgArraySize=${#maincfgArray[@]}
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
  tblankscreen=${BLANKSTRING}
  version=$(koiVersion) 
  headerLength=${#headerName}
  versionLength=${#version}
  stringLength=$(( displayWidth - ( 4 + 4 + 4 + 2 + versionLength + headerLength )))
  echo -e "##$highlight  KOI $version ${EMPTYSTRING:0:$stringLength} ${1}  $outline##"

  echo -e "$PHULLSTRING$BASE"
}
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
  echo -e "$outline##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
##$inactive**********************************************************************$outline##
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
  errorLength=${#errorString}
  stringLength=$(( displayWidth - ( 4 + 2 + errorLength )))
  echo -e     "##$highlight  $errorString${EMPTYSTRING:0:stringLength}$outline##"

  echo -e     "$PHULLSTRING$BASE"
}
drawConfigFlowReturn=""
drawConfigFlow() {
configHeader="$1"
drawConfigGraphic="$2"
promptString="$3"
inputPrompts="$4"

  drawHeader "$configHeader"
  
  connectionColor="$inactive"

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
    currentLine=${drawConfigGraphicArray[$i]}
    currentWidth=${#currentLine}
    if [[ graphicWidth -lt $currentWidth ]]; then
      graphicWidth=$currentWidth
    fi
    i=$(( $i + 1 ))
  done
  
  if [[ $graphicWidth -gt $rightWidth ]]; then
    echo -e "ERROR: Graphic is too wide for the window"
    exit 1
  fi
  
  leftSpace=$(( ( $rightWidth - $graphicWidth ) / 2 ))
  rightSpace=$leftSpace
  if [[ $(( $leftSpace + $graphicWidth + $rightSpace )) -ne $rightWidth ]]; then
    rightSpace=$(( $rightSpace + 1 ))
  fi
  
  i=0
  segmentNumber=0
  drawConfigGraphicLines=$systemDiagramArraySize
  if [[ $systemDiagramArraySize -lt $drawConfigGraphicArraySize ]]; then
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
        if [[ "$menuHostName" != "" ]]; then
          connectionColor=$active
        fi
        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
      elif [[ $currentLinePrefix == " +- m" ]]; then
        if [[ "$menuMCUName" == "" ]]; then
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
      elif [[ $currentLinePrefix == " | NA" ]]; then
        if [[ "$connectionColor" == "$inactive" ]]; then
          currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
        elif [[ $segmentNumber -eq 0 ]]; then
          lineNameWidth=${#menuHostName}
          lineRight=$(( $leftLineSpace - $lineNameWidth  ))
          currentLine="$outline##$connectionColor | $menuHostName${EMPTYSTRING:0:$lineRight} | $outline##"
        elif [[ $segmentNumber -eq 1 ]]; then
          lineNameWidth=${#menuMCUName}
          lineRight=$(( $leftLineSpace - $lineNameWidth  ))
          currentLine="$outline##$connectionColor | $menuMCUName${EMPTYSTRING:0:$lineRight} | $outline##"
        else # [[ $segmentNumber -eq 2 ]]; then
          lineNameWidth=${#menuToolheadName}
          lineRight=$(( $leftLineSpace - $lineNameWidth  ))
          currentLine="$outline##$connectionColor | $menuToolheadName${EMPTYSTRING:0:$lineRight} | $outline##"
        fi
      elif [[ $currentLinePrefix == " | VE" ]]; then
        if [[ $segmentNumber -eq 1 ]]; then
          if [[ "$menuMCUName" == "" ]]; then
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
      elif [[ $currentLinePrefix == " | MC" ]]; then
        if [[ $segmentNumber -eq 1 ]]; then
          if [[ "$menuMCUName" == "" ]]; then
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
      elif [[ $currentLinePrefix == " | PR" ]]; then
        if [[ "$menuMCUName" == "" ]]; then
          connectionColor=$inactive
        else
          connectionColor=$active
        fi

        currentLine="$outline##$connectionColor${systemDiagramArray[$i]}"
      elif [[ $currentLinePrefix == "CONNE" ]]; then
        if [[ "$menuConnection" == "" ]]; then
          connectionColor=$inactive
          currentLine="$outline##$connectionColor${systemDiagramArray[$(( $i - 1 ))]}"
        else
          connectionColor=$active
          
        fi
      elif [[ $currentLinePrefix == "CANBU" ]]; then
        if [[ "$menuCANBUS" == "" ]]; then
          connectionColor=$inactive
          currentLine="$outline##$connectionColor${systemDiagramArray[$(( $i - 1 ))]}"
        else
          connectionColor=$active

        fi
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
        rightFiller=$(( $rightWidth - ( $leftSpace + $currentGraphicWidth ) ))
        currentLine="$currentLine${EMPTYSTRING:0:$leftSpace}$active${drawConfigGraphicArray[$iGraphic]}${EMPTYSTRING:0:$rightFiller}$outline##"
      fi
    fi
    
    echo -e "$currentLine"
    
    i=$(( $i + 1 ))
  done

  echo -e     "$PHULLSTRING$BASE"
  
  invalidResponseString="Invalid Response    "
  invalidResponseStringLength=${#invalidResponseString}
  promptString="$promptSting (${inputPromptsArray[0]}"
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
    read -p "$invalidPromptString$promptString): " inputChar
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
# Configuration (Constant) Variables
########################################################################
#                      1111111111222222222233333333334444444444555555555566666666667777
#            01234567890123456789012345678901234567890123456789012345678901234567890123
EMPTYSTRING="                                                                          "
PHULLSTRING="##########################################################################"
displayWidth=${#EMPTYSTRING}
systemDiagram="                     $outline##
 +- host ----------+ $outline##
 | NAME            | $outline##
 +--------+--------+ $outline##
          |          $outline##
CONNECTION
          |          $outline##
 +- main ----------+ $outline##
 | NAME            | $outline##
 | VER X.XX        | $outline##
 | MCU             | $outline##
 | PROG            | $outline##
 +--------+--------+ $outline##
          |          $outline##
CANBUS
          |          $outline##
 +- toolhead ------+ $outline##
 | NAME            | $outline##
 | VER X.XX        | $outline##
 | MCU             | $outline##
 | DFU             | $outline##
 +-----------------+ $outline##
                     $outline##"
readarray -t systemDiagramArray <<< $systemDiagram
systemDiagramArraySize=${#systemDiagramArray[@]}
confirmationPromptList="Quit
Yes
No"

hostCPUInfo=""
menuHost=""
menuHostName=""
menuHostMatchName=""
menuHostConnections=""
menuHostConnectionsArray=""
menuHostConnectionsArraySize=0
hostConnection=""
menuHostBlock=""
menuHostEmbeddedUSB=""
menuHostUSB=""
menuHostSerial=""
menuHostFileContents=""
menuConnection=""
menuMCU=""
menuMCUName=""
menuCANBUS=""
menuToolhead=""
menuToolheadName=""






########################################################################
# File System Methods
########################################################################
virginSystemCheck() {
  if [[ "$rootFile" == *"klipper"* ]]; then
    sleep 2s
    drawError "Image State Check" "\"klipper\" folder found in system. MUST start with blank system"
    exit 1
  elif [[ "$rootFile" == *"Katapult"* ]]; then
    sleep 2s
    drawError "Image State Check" "\"Katapult\" folder found in system. MUST start with blank system"
    exit 1
  elif [[ "$rootFile" == *"kiauh"* ]]; then
    sleep 2s
    drawError "Image State Check" "\"kiauh\" folder found in system. MUST start with blank system"
    exit 1
  fi
}
getHost() {
  hostModel=$'Model'
  colonSpace=": "
  cpuInfo=`cat /proc/cpuinfo`
  cpuInfoModel=${cpuInfo#*$hostModel}

  hostCPUInfo=""
  if [[ "$cpuInfo" != "$cpuInfoModel" ]] ; then
    cpuInfoModel=${cpuInfoModel#*$colonSpace}
    cpuInfoModel="${cpuInfoModel// /_}"
    cpuInfoModel="${cpuInfoModel/./_}"
    i=0
    hostFoundFlag=0
    while [ $i -lt $hostcfgArraySize ] && [ $hostFoundFlag -eq 0 ]; do
      hostElement=${hostcfgArray[$i]}
      hostElementSize=${#hostElement}
      if [[ "$hostElement" == "${cpuInfoModel:0:$hostElementSize}" ]]; then
        menuHostFileContents=`wget $webFileLocation/$hostElement.hostcfg -O -`
        hostCPUInfo="$cpuInfoModel"
        hostFoundFlag=1
      fi
      i=$(( $i + 1 ))
    done
  fi
}
setupHost() {
  menuHostNameStart="HOSTNAME: "
  menuHostNameEnd="
STATUS:"
  menuHostName=${menuHostFileContents#*$menuHostNameStart}
  menuHostName=${menuHostName%$menuHostNameEnd*}
  menuHostMatchNameStart="MATCHNAME: "
  menuHostMatchNameEnd="
CONNECTIONS:"
  menuHostMatchName=${menuHostFileContents#*$menuHostMatchNameStart}  
  menuHostMatchName=${menuHostMatchName%$menuHostMatchNameEnd*}
  menuHostConnectionsStart="CONNECTIONS:
"
  menuHostConnectionsEnd="
BLOCKDIAGRAM:
"
  menuHostConnections=${menuHostFileContents#*$menuHostConnectionsStart}
  menuHostConnections=${menuHostConnections%$menuHostConnectionsEnd*}
  readarray -t menuHostConnectionsArray <<< $menuHostConnections
  menuHostConnectionsArraySize=${#menuHostConnectionsArray[@]}
  menuHostBlockStart="BLOCKDIAGRAM:
"
  menuHostBlockEnd="
EMBEDDEDUSBCONNECTION:
"
  menuHostBlock=${menuHostFileContents#*$menuHostBlockStart}
  menuHostBlock=${menuHostBlock%$menuHostBlockEnd*}
  menuHostEmbeddedUSBStart="EMBEDDEDUSBCONNECTION:
"
  menuHostEmbeddedUSBEnd="
USBCONNECTION:
"
  menuHostEmbeddedUSB=${menuHostFileContents#*$menuHostEmbeddedUSBStart}
  menuHostEmbeddedUSB=${menuHostEmbeddedUSB%$menuHostEmbeddedUSBEnd*}
  menuHostUSBStart="
USBCONNECTION:
"
  menuHostUSBEnd="
SERIALCONNECTION:
"
  menuHostUSB=${menuHostFileContents#*$menuHostUSBStart}
  menuHostUSB=${menuHostUSB%$menuHostUSBEnd*}
  menuHostSerialStart="SERIALCONNECTION:
"
  menuHostSerial=${menuHostFileContents#*$menuHostSerialStart}
}




########################################################################
# KOI Mainline
########################################################################

# Set and Save Environment
set -e

drawSplashScreen

if [ "$1" != "-nvc" ]; then
  virginSystemCheck
fi

drawAppend "Cataloging configuration files."
catalogGithubList

doAppend "!Do Basic Updates and Installs:" "sudo apt update -y" "sudo apt upgrade -y" "sudo apt-get upgrade -y" "sudo apt-get install bc" "sudo apt-get install git -y"

getHost
if [[ "$hostCPUInfo" == "" ]]; then
#$# Will have to support "Prev" and "Next" when having more than 9 host options
#$# Copy approach used later for main and tool controller boards
  hostcfgMessage="Select Host

"
  promptList="Quit"
  i=0
  while [ $i -lt $hostcfgArraySize ] && [ $i -lt 9 ]; do
    menuHostFileContents=`wget $webFileLocation/${hostcfgArray[$i]}.hostcfg -O -`
    menuHostNameStart="MATCHNAME: "
    menuHostNameEnd="
CONNECTIONS:"
    tempMenuHostName=${menuHostFileContents#*$menuHostNameStart}
    tempMenuHostName=${tempMenuHostName%$menuHostNameEnd*}
    i=$(( $i + 1 ))
    hostcfgMessage="$hostcfgMessage$i $tempMenuHostName

"
    promptList="$promptList
$i"
  done

  hostSelectFlag=0
  while [ $hostSelectFlag -eq 0 ]; do
    drawConfigFlow "Select Host" "$hostcfgMessage" "Select Host" "$promptList"
    hostConnection=$drawConfigFlowReturn
    if [[ "$drawConfigFlowReturn" == "1" ]]; then
      hostCPUInfo="${hostcfgArray[0]}"
    elif [[ "$drawConfigFlowReturn" == "2" ]]; then
      hostCPUInfo="${hostcfgArray[1]}"
    elif [[ "$drawConfigFlowReturn" == "3" ]]; then
      hostCPUInfo="${hostcfgArray[2]}"
    elif [[ "$drawConfigFlowReturn" == "4" ]]; then
      hostCPUInfo="${hostcfgArray[3]}"
    elif [[ "$drawConfigFlowReturn" == "5" ]]; then
      hostCPUInfo="${hostcfgArray[4]}"
    elif [[ "$drawConfigFlowReturn" == "6" ]]; then
      hostCPUInfo="${hostcfgArray[5]}"
    elif [[ "$drawConfigFlowReturn" == "7" ]]; then
      hostCPUInfo="${hostcfgArray[6]}"
    elif [[ "$drawConfigFlowReturn" == "8" ]]; then
      hostCPUInfo="${hostcfgArray[7]}"
    elif [[ "$drawConfigFlowReturn" == "9" ]]; then
      hostCPUInfo="${hostcfgArray[8]}"
    elif [[ "$drawConfigFlowReturn" == "Q" ]]; then
      echo -e "All Done!"
      exit 0
    fi
  
    menuHostFileContents=`wget $webFileLocation/$hostCPUInfo.hostcfg -O -`
  
    setupHost

    drawConfigFlowConfirm "Confirm Selected Host" "$menuHostMatchName

$menuHostBlock" "Confirm Selected Host"
    if [[ "$drawConfigFlowReturn" == "Y" ]]; then
      hostSelectFlag=1
    fi
  done
  
else
  setupHost 
fi  

#$# Select the Main Controller board

#$# Select the communications method between main controller and host
#$# Set of options must be available to both host and main controller
  
promptList="Quit"
i=0
while [ $i -lt $menuHostConnectionsArraySize ]; do
  promptList="$promptList
${menuHostConnectionsArray[$i]}"
  i=$(( $i + 1 ))
done

communicationsSelectFlag=0
while [ $communicationsSelectFlag -eq 0 ]; do
  drawConfigFlow "Host Configuration" "$menuHostMatchName

$menuHostBlock" "Select Host Comms" "$promptList"
  hostConnection=$drawConfigFlowReturn
  if [[ "$hostConnection" == "E" ]]; then
    drawConfigFlowConfirm "Confirm Embedded USB" "$menuHostMatchName

$menuHostEmbeddedUSB" "Use Embedded USB"
  elif [[ "$hostConnection" == "U" ]]; then
    drawConfigFlowConfirm "Confirm USB Communications" "$menuHostMatchName

$menuHostUSB" "Use USB"
  elif [[ "$hostConnection" == "S" ]]; then
    drawConfigFlowConfirm "Confirm Serial Communications" "$menuHostMatchName

$menuHostSerial" "Use Serial"
  else # if [[ "$hostConnection" == "Q" ]]; then
    echo -e "All Done!"
    exit 0
  fi
  if [[ "$drawConfigFlowReturn" == "Y" ]]; then
    communicationsSelectFlag=1
  fi
done

#$# Check for CAN toolhead controller

#$# Load KIAUH

#$# Build Katapult/Klipper 

#$# Load main controller WITHOUT CAN

#$# Load main controller WITH CAN

#$# Load toolhead controller WITH CAN

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
