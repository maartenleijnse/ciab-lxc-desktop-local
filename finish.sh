#!/bin/bash

#=====================================================================================================================
# finish.sh
# by Brian Mullan (bmullan.mail@gmail.com)
#
# MIT License
#
# Copyright (c) 2016 bmullan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# NOTE:  the finish.sh script executes INSIDE the CN1 container
#        and will create a User acct with SUDO privileges only in the CN1 container for the UserID 
#        that the installer gives us below when prompted.
#=====================================================================================================================


# Prompt for the UserID to create an new Acct in the CN1 container for the Installing User.
# This acct will be provided SUDO privileges only in the CN1 container.

# the following will ask what the User ID for the new acct should be from the Installer.
# it will also set the variable 'userID' to that... for use later in thes script

while :
do
    echo
    echo
    read -p 'Please enter the UserID you want to create an Account for in the CN1 container: ' userID 
    echo
    echo
    echo "You want to create a new User Acct for  '$userID'  in the CN1 container?"
    echo
    read -r -p "Are You Sure? [y/n] " input
	case $input in
	    [yY])
		break
		;;
	    [nN])
                clear
		;;
	    *)
		echo "Invalid input..."
		;;
	esac
done


files=/opt/ciab


#-------------------------------------------------------------------------------------------------------------
# add Canonical Partner repositories
#
# NOTE:  if you are NOT using Ubuntu 15.10 then change the following 4 lines from "wily" to whatever release
# you are using.    ** I have only tested this on Ubuntu 15.04 and 15.10 though **

echo "deb http://archive.canonical.com/ubuntu wily partner" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://archive.canonical.com/ubuntu wily partner" | sudo tee -a /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ wily-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://us.archive.ubuntu.com/ubuntu/ wily-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list


#---------------------------------------------------------------------------------------------------------------
# Make sure 'software-properties' is installed or add-apt-repository won't work...

sudo apt-get install software-properties-common -y

# Add the apt-fast author's ppa and update our sources list...

sudo add-apt-repository ppa:saiarcot895/myppa -y

# update and upgrade the container

sudo apt-get update
sudo apt-get upgrade -y

#---------------------------------------------------------------------------------------------------------------
#  Install apt-fast...  note - all future apt-get will be done with apt-fast instead
#  apt-fast actually uses apt-get ... it just implements multiple concurrent threads
#  to speed up the apt-get process

sudo apt-get install apt-fast -y

#---------------------------------------------------------------------------------------------------------------
# Install Ubuntu-Mate DE...

sudo apt-fast install mate-core mate-desktop-environment mate-notification-daemon --force-yes -y

# Configure the Xsession as the default desktop environment to make ALL future Users default xsession to UBUNTU-MATE.

sudo update-alternatives --set x-session-manager /usr/bin/mate-session

# add some useful extras to the CN1 container... including pulseaudio

sudo apt-fast install openssh-server gdebi nano firefox terminator synaptic alsa alsa-utils -y
sudo apt-fast install pulseaudio libcanberra-pulse pulseaudio-module-zeroconf paprefs pavucontrol -y
sudo apt-fast install indicator-sound adobe-flashplugin -y

#---------------------------------------------------------------------------------------------------------------
# install X related apps so Xnest can work with them to present the desktop to the user on the Host

sudo apt-fast install xserver-xorg xdm xterm blackbox -y

#--------------------------------------------------------------------------------------------------------------
# To enable Xnest in the Host to bring up this containers Desktop Environment (mate in our case) these 2
# files need to be change IN only the  Container..

# Comment out the line with 'DisplayManager.requestPort' with an exclamation mark (!)
sudo sed -i '/DisplayManager.requestPort/ c\! DisplayManager.requestPort: 0' /etc/X11/xdm/xdm-config

# Remove the comment on the line with #any host can get a login window:
sudo sed -i '/any host can get a login window/ c\* #any host can get a login window' /etc/X11/xdm/Xaccess

# After making the above 2 changes you need to restart xdm

sudo /etc/init.d/xdm restart

#---------------------------------------------------------------------------------------------------------------
# After the Ubuntu-Mate desktop is installed we need to create a user acct for the Installer userID
# and give that acct SUDO privileges in this CN1 container

sudo adduser $userID
sudo adduser $userID adm
sudo adduser $userID sudo

# fix ownership of files that were copied into /opt/ciab in the CN1 container
# and make them "owned" by the Installer's UserID

sudo chown $userID:$userID /opt/ciab
sudo chown $userID:$userID /opt/ciab/*.sh
sudo chown $userID:$userID /opt/ciab/*.deb

# add the Installer's UserID to the audio & pulse "groups"

sudo adduser $userID audio
sudo adduser $userID pulse
sudo adduser $userID pulse-access

#---------------------------------------------------------------------------------------------------------------
# add the command "export PULSE_SERVER=10.0.3.1"  to the installer/user acct in the container CN1
# Later when that user logs into the container... that PULSE_SERVER environment variable will be set
# and REDIRECT any sound generated in the container to 10.0.3.1 which from the container CN1's perspective
# is the HOST it is running in.
#
# Important Note:  later if you add additional User accounts to the LXC container you will need to add this
#                  statement to those userID .bashrc files as well.
#---------------------------------------------------------------------------------------------------------------

echo "export PULSE_SERVER=10.0.3.1" | tee -a /home/$userID/.bashrc

#---------------------------------------------------------------------------------------------------------------
# The avahi-daemon install has a problem completing when installed in LXC right now  so the following is a
# workaround for now

sudo apt-fast install avahi-daemon avahi-utils -y
sudo systemctl disable avahi-daemon
sudo systemctl stop avahi-daemon
sudo apt-fast autoremove
sudo apt-fast install -f avahi-daemon avahi-utils -y


#---------------------------------------------------------------------------------------------------------------
# we need to add the export PULSE_SERVER-10.0.3.1 to the firefox.sh file that is run when you execute
# firefox from the Ubuntu menu instead of starting it from a command prompt
# when you start it from a command prompt the actual /usr/lib/firefox/firefox binary runs
# when you start firefox from the Ubuntu menu... the firefox.sh runs... then invokes the actual
# firefox binary.   We need the firefox.sh script to have the same PULSE_SERVER=10.0.3.1 environment
# variable as the User's .bashrc has
#
# Note:  I'm not sure if this difference in starting firefox via the menu & the command line is a bug or not
#        but I am going to submit it as Bug as I think both methods of starting firefox should run with the
#        same User Environment variables - not different ones.   In the meantime, some of the next commands
#        are a workaround by inserting the 'export PULSE_SERVER=10.0.3.1' to the /usr/lib/firefox/firefox.sh
#---------------------------------------------------------------------------------------------------------------

# the original firefox.sh file is this one...
oldfile=/usr/lib/firefox/firefox.sh

# save the original
sudo cp $oldfile $oldfile.orig

# we will use SED to add our PULSE_SERVER statement to the original firefox.sh but save the change to firefox.sh.new
newfile=/usr/lib/firefox/firefox.sh.new

# Now in firefox.sh we append after its "!/bin/sh" the export statement and redirect that to a new 
# copy of the firefox.sh which we will call firefox.sh.new
sudo sed '/bin\/sh/a export PULSE_SERVER=10.0.3.1' $oldfile > $newfile

# now we replace firefox.sh with the firefox.sh.new file and we should be all set
sudo mv $newfile $oldfile
# and make sure the new firefox.sh is executable
sudo chmod +x $oldfile

echo
echo 
echo "***************************************************************************************"
echo " Just about done.   At the prompt below just type 'exit'.   This will return you from"
echo " this script 'finish.sh' back to the first script 'start.sh' so it can finish up by"
echo " rebooting the LXC container CN1."
echo
echo " After you see the output of the LXC LIST command which will display the IP address of"
echo " CN1 container you can then access it's Ubuntu-Mate desktop and begin using it."
echo
echo " Remember... type 'exit'..."
echo
echo

exit 0

