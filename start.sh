#!/bin/bash

#=============================================================================================================
# start.sh
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
# Purpose:
#
# This script is one of 2 that will create/start a "privileged" LXD/LXC container named CN1.
# Note that this will work with the normal "default" LXD/LXC containers which are "un-privileged".
#
# Pre-req:  you have to have pulseaudio installed on your Host pc, you have placed all of the
#           ciab-lxc-desktop files in the Host's /opt/ciab directory and you changed the owner
#           of that directory to be the installing UserID
#
#                  example:  sudo chown $USER:$USER /opt/ciab
#
# In CN1 this script will then:
#
# 1) add a new User acct for the installer using the Installer's Host userID (re $USER)
# 2) give that userID sudo privileges
# 3) copy (re in lXD terms PUSH) the rest of the config etc files from the Host to the container
#    This will include a 2nd script which will be executed "inside" the new CN1 container
# 4) finally it will reboot the CN1 container
#
# When this entire process is done installing you will be able to use Xnest on your Host to bring up the
# ubuntu-mate desktop running in the CN1 container.
#
# From that CN1 Ubuntu-Mate desktop you can cut & paste, print, hear sound etc just like from your normal
# pc/host
#
# example command to execute on the host after all of this installation is complete would be the
#         following (assuming the CN1 container address is 10.0.3.72 (your's will probably be different)
#
#                   $ Xnest :1 -query 10.0.3.72
#
# the above command does assume you installed Xnest on  your PC/Host ($ sudo apt-get install xnest) !!
#=============================================================================================================

# set location where the installation files were placed when they were UNTarred. I just created a directory 
# /opt/ciab and put the files there on my system but If you put them somewhere else then change "/opt/ciab" 
# in the following to point to that directory.

files=/opt/ciab

#-------------------------------------------------------------------------------------------------------------
# append the following the the /etc/pulse/system.pa file so pulseaudio will load its TCP module
# This is required so that sound in the LXC containers can be redirected via TCP to the Host's Pulseaudio 
# server and heard on the Host system's speakers.

# this command authorizes only sound from the Host itself & from any LXC container on the default 10.0.3.x
# lxcbr0 bridge.

echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;10.0.3.0/24" | sudo tee -a /etc/pulse/system.pa

echo "load-module module-zeroconf-publish" | sudo tee -a /etc/pulse/system.pa


#-------------------------------------------------------------------------------------------------------------
# for ciab-desktop demonstration use-case...
# lets create just 1 container and call it CN1
#
# in CN1 we will pre-install the Ubuntu-MATE desktop environment
#-------------------------------------------------------------------------------------------------------------

# this assumes you already had LXD installed on your Host PC and used the name "images" when you setup the
# remote repository to get rootfs images from

# I am using Ubuntu 15.10 so I'm launching an Ubuntu Wily 15.10 64 bit containers named cn1 as a
# PRIVILEGED container (unprivileged works equally well & is the default with LXD)

lxc launch images:ubuntu/wily/amd64 cn1 -c security.privileged=true

#-------------------------------------------------------------------------------------------------------------
# If you want the CN1 container to later auto-start  when the Host is rebooted
# uncomment the following before you execute the script if you want CN1 to autoboot when the system reboots
# If you do not use the following you will have to manually restart the CN1 container after any reboot of
# your system.

# lxc config set cn1 boot.autostart 1

cd $files

#---------------------------------------------------------------------------------------------------------------
# push (re copy) our CN1 setup script to the CN1 container into CN1's /opt/ciab directory so it can
# later be executed & setup the the container for you so it has a desktop & has sound enabled.
#---------------------------------------------------------------------------------------------------------------

lxc exec cn1 -- /bin/bash -c "mkdir /opt/ciab"


lxc file push ./finish.sh cn1/opt/ciab/

# make sure bash scripts we pushed are executable on cn1
lxc exec cn1 -- /bin/bash -c "chmod +x /opt/ciab/*.sh"


echo
echo
echo "*******************************************************************************************************"
echo
echo "Next we start a  bash shell inside the CN1 container and you will notice the  command line"
echo "prompt will change to indicate you are logged in as 'root' in the container CN1."
echo
echo "At that point change directory to the CN1 container's /opt/ciab directory and execute the script named"
echo "'finish.sh' to complete the installation of all required software in the container."
echo
echo "          example:"
echo "                   root@cn1# cd /opt/ciab"
echo "                   root@cn1# ./finish.sh"
echo
echo "When the finish.sh script completes... just type 'exit' to exit the container and you will be returned"
echo "to this script and it too will run to completion."
echo
echo
read -p "Press any key when you are ready to be logged into the CN1 container..."


lxc exec cn1 /bin/bash

echo
echo
echo
echo "Exited the CN1 container and continuing the 'start.sh' script..."
echo
echo

echo "Rebooting cn1..."
lxc exec cn1 -- /bin/bash -c "shutdown -r now"
echo


# lets list the LXC containers just to check
# wait 5 seconds for the CN1 container to start back up then list it for you so you know the IP to use
# in your xfreerdp command later when you want to bring up the CN1 Ubuntu-Mate desktop

sleep 5
lxc list

echo
echo
echo
echo
echo "====================================================================================================================="
echo " Setup is complete!"
echo " Now you can start your LXC Desktop using either the a terminal command line or by using the included ciab.sh script."
echo
echo " In either method you need to know what is the next available 'Session Number' to can assign for your new LXC Desktop"
echo " to run in."
echo
echo " We've included a script which will tell you the next available 'Session Number' to use."
echo " That script's name is next-free-N.sh so execute it:"
echo
echo "             $ ./next-free-N.sh"
echo
echo " this will display a message such as: first available display is :1"
echo
echo " This is telling you '1' is the next free Session Number you can use.  In the following 'N' is the Session Number"
echo " and IP-ADDR is the IP address of the CN1 LXC container (see above or execute $ lxc list to get it)"
echo
echo " Start your LXC Desktop -"
echo
echo " from a Host terminal command line execute:  $ Xnest :N -query IP-ADDR"
echo " -or-"
echo " use the 'ciab.sh' script and execute:  $ ./ciab.sh N IP-ADDR"
echo
echo " Either method will present you with a new LXC Desktop window where you will be asked to input your Login/Password"
echo " for your User Account in the CN1 LXC container.   After entering both you will see the Ubuntu-Mate desktop appear."
echo
echo

exit 0



