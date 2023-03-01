#!/bin/bash

#
# Configurables
#

SSH_TEMP_FILE=/tmp/vnc_ssh_socket
VNC_USER=eclaus
SSH_SERVER=chtm-lwrk-01.lan.chtm.me
TUN_PORT=5902
SSH_PORT=22
VNC_CONF=/tmp/${VNC_USER}_conf.tigervnc

CONF_COLOR_INFO="54"
CONF_COLOR_WARN="220"
CONF_COLOR_ERR="196"

#
# Some Constants
#

ESC_SEQ=$(echo -ne "\033[")

ENTER_ALT_FB="${ESC_SEQ}?1049h"
EXIT_ALT_FB="${ESC_SEQ}?1049l"

SET_CURSOR_INVIS="${ESC_SEQ}25l"
UNSET_CURSOR_INVIS="${ESC_SEQ}25h"

CLEAR_SCREEN="${ESC_SEQ}2J"
HOME_CURSOR="${ESC_SEQ}H"
PREV_LINE="${ESC_SEQ}1F"
ERASE_LINE="${ESC_SEQ}2K"

COLOR256_BG="${ESC_SEQ}48;5;250m"

COLOR256_INFO="${ESC_SEQ}38;5;${CONF_COLOR_INFO}m$COLOR256_BG"
COLOR256_WARN="${ESC_SEQ}38;5;${CONF_COLOR_WARN}m$COLOR256_BG"
COLOR256_ERR="${ESC_SEQ}38;5;${CONF_COLOR_ERR}m$COLOR256_BG"


#
# Functions
#


#
# Begin Setup
#

# swap to alt fb, set colors, clear buffer, and set cursor to 0,0
echo -en "$ENTER_ALT_FB"
echo -en "$SET_CURSOR_INVIS"
echo -en "$COLOR256_INFO"
echo -en "$CLEAR_SCREEN"
echo -en "$HOME_CURSOR"

# ssh tunnel
echo "Connecting to $SSH_SERVER:$SSH_PORT as $VNC_USER and establishing tunnel..."
ssh -f -N -M -S $SSH_TEMP_FILE -l $VNC_USER $SSH_SERVER -p $SSH_PORT -L $TUN_PORT:localhost:$TUN_PORT 

# create a temp config file
cat > $VNC_CONF <<- EOM
TigerVNC Configuration file Version 1.0

ServerName=localhost:$TUN_PORT
SecurityTypes=VncAuth,Plain
EmulateMiddleButton=1
DotWhenNoCursor=0
ReconnectOnError=1
AutoSelect=1
FullColor=1
LowColorLevel=2
PreferredEncoding=Tight
CustomCompressLevel=0
CompressLevel=2
NoJPEG=0
QualityLevel=8
FullScreen=0
FullScreenMode=Current
FullScreenSelectedMonitors=1
RemoteResize=1
ViewOnly=0
Shared=0
AcceptClipboard=1
SendClipboard=1
MenuKey=F8
FullscreenSystemKeys=1
EOM

# start vnc here
echo "Connecting to localhost:$TUN_PORT using configured tigervnc"
# TODO: wrap this in some platform checks to check different locations on different systems
open -a /Applications/TigerVNC\ Viewer\ 1.12.0.app --args $VNC_CONF

# enter waiting loop
echo "Press any key to close the tunnel @ localhost:$TUN_PORT"
while true ; do
  # checking return status of read ...
  if read -r -t 1 -n 1 ; then
    ssh -S $SSH_TEMP_FILE -O exit $VNC_USER@$SSH_SERVER     # end ssh session
    rm -v $VNC_CONF   # cleanup
    
    echo -en "$UNSET_CURSOR_INVIS"
    echo -en "$EXIT_ALT_FB"     # swap to back to main fb before we go
    exit ;
  else
    echo -en "$ERASE_LINE"
    rand_fg="\033[38;5;$((RANDOM % 255 + 1))m"
    echo -e "$rand_fg Tunnel is running..."
    echo -en "$PREV_LINE"
  fi
done