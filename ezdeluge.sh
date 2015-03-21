#!/bin/bash
#this is just a POC for me to setup deluge on my server
#any on this script may be problem on your setup
#distribute under MIT license.
if [ $USER != 'root' ]; then
	echo "Sorry, you need to run this as root"
	exit
fi

if [ ! -e /etc/apache2 ]; then
	echo "Looks like Apache web server is not installing"
	exit
fi

if [ ! -e /etc/debian_version ]; then
	echo "Looks like you aren't running this installer on a Debian-based system"
	exit
fi

# Try to get our IP from the system and fallback to the Internet.
IP=$(ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1)
if [ "$IP" = "" ]; then
        IP=$(wget -qO- ipv4.icanhazip.com)
fi

if [ -e /etc/default/deluge-daemon ]; then
	while :
	do
	clear
		echo "Looks like Deluge Daemon/Web UI is already installed"
		echo "What do you want to do?"
		echo ""
		echo "1) Remove Deluge"
		echo "2) Exit"
		echo ""
		read -p "Select an option [1-2]:" option
		case $option in
			1) 
			echo ""
			apt-get remove -y deluge deluged deluge-web
			rm -rf /etc/default/deluge-daemon
			rm -rf /etc/init.d/deluge-daemon
			pkill deluged
			pkill deluge-web
			echo ""
			echo "Deluge removed!"
			echo "you should restart your server"
			echo "1)restart"
			echo "2)no"
			echo ""
			read -p "Select an option [1-2]:" pilih
			case $pilih in
				1)shutdown -r now;;
				2)exit;;
			esac
			exit
			;;
			2) exit;;
		esac
	done
else
	echo 'Welcome to this quick Deluge web UI "road warrior" installer'
	echo ""
	# Deluge setup
	echo "This will install the Deluge application itself, the Deluge Daemon" 
	echo "to let us run Deluge as a background process, and the Deluge html "
	echo "based Web Interface." 
	echo "Make sure Apache web server has been installed!"
	read -n1 -r -p "Press any key to continue..."
	apt-get update
	apt-get install deluge deluged deluge-web -y
	echo "This will run deluge daemon and start up the web UI"
	deluged
	deluge-web --fork
	cd /var/www/html
	mkdir files
	mkdir .temp
	mkdir watch
	chown -R www-data:www-data /var/www/html
	
	cd

	touch /etc/default/deluge-daemon
	touch /etc/init.d/deluge-daemon
	echo "# Configuration for /etc/init.d/deluge-daemon" >> /etc/default/deluge-daemon
	echo "# The init.d script will only run if this variable non-empty." >> /etc/default/deluge-daemon
	echo "DELUGED_USER="root"" >> /etc/default/deluge-daemon
	echo "# Should we run at startup?" >> /etc/default/deluge-daemon
	echo "RUN_AT_STARTUP="YES"" >> /etc/default/deluge-daemon

	wget -c http://www.havetheknowhow.com/scripts/deluge-daemon_rc.txt --no-check-certificate -O deluge-daemon
	mv deluge-daemon /etc/init.d/
	
	chmod 755 /etc/init.d/deluge-daemon
	update-rc.d deluge-daemon defaults
	invoke-rc.d deluge-daemon start
	
	echo "Deluge is now running and ready for us to login for the first time!"
	echo "The install port will have defaulted to 8112 (http://"$IP":8112)"
	echo ""
	echo "Web UI password is “deluge” and will need to be changed on login."
	echo "Please setup yor directory according to this http://i.imgur.com/2wF62EE.png"
	echo ""
	echo "make with ♥ do visit http://najashark.net"
fi
