# ciab-lxc-desktop-local

This github repository contains several files and 2 scripts to create, and install an Ubuntu-Mate desktop environment into an 
LXC container named CN1.

If you download the .zip file from github (**ciab-lxc-desktop-master.zip**) it contains all of the files you need.

Copy the .zip file to some temporary directory on your Host system, change to that directory and then unzip (uncompress) the files.

    *example:   $ unzip ciab-lxc-desktop-master.zip -d destination_folder*


**NOTE:**
You might need to install unzip:  $ sudo apt-get install unzip

Note that the 2 scripts themselves have the install directory set to /opt/ciab by a variable at the start of each script.   Change that
variable in each script (start.sh and finish.sh) to point to where you placed the files if you decide not to use /opt/ciab.

Each bash script has a lot of comments to explain what all is being done.

**Pre-requisites:** 

1. You are using recent Ubuntu release.  I've tested on 15.04, 15.10 so far.
2. You must have pulseaudio installed on your Host.
3. You must also have installed LXD on your Host. 

    example:

    $ sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable

    $ sudo apt-get update

    $ sudo apt-get dist-upgrade

    $ sudo apt-get install lxd

If you are unfamiliar with LXD refer to:    https://linuxcontainers.org/lxd/introduction/

Aside from creating an LXD/LXC container called CN1 these scripts only modify one file on your Host and that is /etc/pulse/system.pa.

The script will add 2 lines to the end of that file which will instruct Pulseaudio the next time it is restarted to load its TCP module 
so that the Host's Pulseaudio server can have sound from the LXC container redirected via TCP to it.

You begin all of this by changing to your temporary directory that contains these files and executing the setup-containers.sh script
as your normal UserID **not** SUDO.

    $ cd /opt/ciab
    $ ./start.sh
    
The start.sh script will take about 5 minutes to run to completion depending on the speed of your computer/host (re does it have SSD 
or regular hard disks, is it multi-core cpu or not etc).

When start.sh finishes it will instruct you what to do next which will all be done with a second script called "finish.sh" which the 
"start.sh" script will have copied to the CN1 container's own /opt/ciab directory.

The start.sh script will log you into the CN1 container as root at a command prompt similar to:   **root@cn1 $**

Again, like you did on the Host when you executed start.sh  you need to change directory to /opt/ciab then execute the "finish.sh" script:

    # cd /opt/ciab
    # ./finish.sh

This second script (finish.sh) will take quite a bit longer (30-50 minutes) to finish as it will be the Ubuntu-Mate desktop environment in
the CN1 container as well as some other useful tools like synaptic, gdebi, nano etc.

**NOTE:** 
While installing software into the CN1 container you may see some error messages related to *systemd, accountsservice, and dbus*. 
Those errors are related to the use of the LXC container but will not affect the successful use of CN1 in any way.   These errors
are just artifacts of some of the security restrictions that are default in the LXC container.

When this script completes the CN1 container will have the  Ubuntu-Mate desktop installed in it and any sounds generated in the LXC Container 
will be heard on the Host's speakers.

**NOTE:** 
You will need to either reboot your Host once or as an alternative on the Host you can just use kill -9 to kill the running 
Pulseaudio daemon *which will auto-restart* and pick up the 2 new lines placed into the /etc/pulse/system.pa file.

**example:**  On my system I would do this:

    $ ps -ax | grep pulse
     3085 ?        S<l    0:09 /usr/bin/pulseaudio --start --log-target=syslog
     3292 ?        S      0:00 /usr/lib/pulseaudio/pulse/gconf-helper
     6525 pts/17   S+     0:00 grep --color=auto pulse
    
    $ sudo kill -9 3085

When this second script finishes it will leave you at the command prompt again inside the CN1 container.

Just type:  *'exit'*

This will log you out of the CN1 container and the original script "start.sh" will resume & finish its work.

To use the CN1 container you need to install the Xnest application on your Host system (the ubuntu host you are creating the CN1 container in).

On the Host:

    **$ sudo apt-get install xnest -y**

to bring up the CN1 "remote desktop" the following command (assuming the LXC container has the IP address 10.0.3.72) will present you 
with the CN1 Ubuntu-Mate desktop and support remote printing, clipboard & sound from the CN1 container you can use the script ciab.sh 
included in the ciab-desktop.tar.gz file or just use the cli on your Host:

Using the provided ciab.sh file to start the LXC container desktop:

    **$ /path/to/ciab.sh N ip_cn1**

    where:  **N** = an available/unused  **session** number on your Host 
            **ip_cn1** is the IP address of the CN1 container .. which you can get by using the command:  **lxc list** 

or if you want to start the LXC desktop from the CLI:

    **$  Xnest :N -query ip_CN1**

How to find out what is the **next available session number**?
Use for **N** I've included a script named **next-free-N.sh**.   If you execute that script it will tell 
you what session number you can use for N.   This is important if your computer use already utilizes more 
than the default session number *"0"*. 

When the LXC Mate desktop starts you will have to login using yo
ur userID and password after which you will find the 
Mate desktop presented.   Sound, Printers, and file sharing should all 'just work' in that LXC Desktop.

To enable printing, ADD a new printer as usual but for the name of the new printer put IP (10.0.3.1) of the Host
into the search box at the upper right and just hit enter.  You should see any printers you have installed on the
Host show up in the LXC desktop's Printer ADD menu and you can select from those.  If you are prompted for a
login/password just *click Cancel* and ignore that.  You will still get the printer added OK.

Sound will work with any program run in the LXC container's Desktop and will play on the Desktop's speakers unless
you use the Pulseaudio control program (look in the Sound menu) to change the output to headphones (which should
work also). 

**NOTE:**
If you are playing sound via the Host and also play sound/music from the LXC container they will both mingle on
the Host's speakers unless as mentioned above you change one or the other (host or container) to use a different
output (like Host sounds are played on speakers & container sounds play to Headphones).

For File Sharing in the LXC container.. just use Nautilus and browse to the Host's IP (10.0.3.1) address and
you will get prompted to login to the Host with your normal Host UserID & password.  After that you can copy,
cut & paste files to/from the Host & the LXC container.


**NOTE:**
The CN1 container can always be copied/cloned to create more copies of this container if you want more for whatever reason.
You **do not** need to run this script again unless you destroy the original CN1 container.

**If you do need to re-run this script** you will need to manually edit the /etc/pulse/system.pa file and if the following 2 lines 
are duplicated because of the start.sh rerun then delete the repeated pair of lines!

    load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;10.0.3.0/24
    load-module module-zeroconf-publish

**NOTE:**
If later you decide to add additional User Accounts to the CN1 container you will have to do a few things manually:

Create the new user. 
example: 

sudo adduser newID

Add the newID to 3 "groups". 
example: 

sudo adduser newID audio

sudo adduser newID pulse

sudo adduser newID pulse-access

Then finally add the statement "*export PULSE_SERVER=10.0.3.1*" to the newID's **~/.bashrc** file


If you have any questions please read through the comments in the two scripts as I tried to add a lot of information about what they 
were doing throughout them.

And finally...

*If you can improve/contribute to these scripts please do so!*

