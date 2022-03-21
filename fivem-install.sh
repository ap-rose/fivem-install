#!/bin/bash
# Author: A.P. Rose
# Version: 1.0

echo -e "\e[93m[fivem-install]\e[0m Detecting Operating System"
if [ -f /etc/centos-release ]; then
    OS="CentOs"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 6, 7 or 8
elif [ -f /etc/fedora-release ]; then
    OS="Fedora"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/fedora-release)
    VER=${VERFULL:0:2} # return 6 or 7
elif [ -f /etc/lsb-release ]; then
    OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
elif [ -f /etc/os-release ]; then
    OS=$(grep -w ID /etc/os-release | sed 's/^.*=//')
    VER=$(grep VERSION_ID /etc/os-release | sed 's/^.*"\(.*\)"/\1/' | head -n 1 | tail -n 1)
 else
    OS=$(uname -s)
    VER=$(uname -r)
fi
ARCH=$(uname -m)
echo "Detected : $OS  $VER  $ARCH"
if [[ "$OS" = "Ubuntu" && "$VER" = "18.04" || "$OS" = "Ubuntu" && "$VER" = "20.04" ]] ; then
    echo -e "\e[92mOS Supported\e[0m"
else
    echo -e "\e[91mSorry, this OS is not supported by FiveM install script.\e[0m"
    exit 1
fi
echo ""
echo -e "\e[93mFiveM Server Installer"
echo "https://github.com/ap-rose/fivem-install"
echo ""
echo -e "\e[91mWARNING: This script will overwrite and install a FiveM server.\e[0m"
echo ""
while true; do
    read -p "Do you wish to install FiveM server? (Y/N)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
while true; do
    read -p "Are you sure? (Y/N)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo -e "\e[39m"
read -e -p "Enter your root mysql password: " -i "$MYSQL_ROOT_PASSWORD" MYSQL_ROOT_PASSWORD
if [[ "$MYSQL_ROOT_PASSWORD" = "" ]]; then
    echo "mysql password required."
    exit 2
fi
echo -e "\e[93m[fivem-install]\e[0m Purging SQL Software"
DEBIAN_FRONTEND=noninteractive apt-get -y purge mariadb-client-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mariadb-client-core-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mariadb-common
DEBIAN_FRONTEND=noninteractive apt-get -y purge mariadb-server
DEBIAN_FRONTEND=noninteractive apt-get -y purge mariadb-server-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mariadb-server-core-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-client-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-client-core-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-server-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-server-core-*
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-apt-config
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-client
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-community-client
DEBIAN_FRONTEND=noninteractive apt-get -y purge mysql-community-server
rm -rf /var/lib/mysql/
rm -rf /var/lib/mysql-*
rm -rf /etc/mysql
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install wget xz-utils git
apt-get update
echo -e "\e[93m[fivem-install]\e[0m Install mariadb-server"
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
mkdir /etc/mysql/conf.d/
DEBIAN_FRONTEND=noninteractive mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
echo -e "\e[93m[fivem-install]\e[0m Start mariadb-server"
timeout 5 systemctl start mariadb
DEBIAN_FRONTEND=noninteractive apt-get -y install sshpass
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
echo -e "\e[93m[fivem-install]\e[0m Add user fxserver"
getent passwd fxserver
adduser --system --shell /bin/false --group --disabled-login fxserver 
mkdir -p /home/fxserver
echo -e "\e[93m[fivem-install]\e[0m Download FiveM content"
wget -O "/home/fxserver/server/fx.tar.xz" "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/5402-810a639673d8da03fe4b1dc2b922c9c0265a542e/fx.tar.xz"
echo -e "\e[93m[fivem-install]\e[0m Unpack FiveM content"
DEBIAN_FRONTEND=noninteractive tar xf "/home/fxserver/server/fx.tar.xz" -C "/home/fxserver/server/"
rm -f /tmp/fx.tar.xz
echo -e "\e[93m[fivem-install]\e[0m Update MySQL root password"
mysql -u root -e "UPDATE mysql.user SET Password = PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User = 'root'"
mysql -u root -e "DROP USER ''@'localhost'"
mysql -u root -e "DROP USER ''@'$(hostname)'"
mysql -u root -e "DROP DATABASE test"
mysql -u root -e "FLUSH PRIVILEGES"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DROP DATABASE IF EXISTS fxserver_data; CREATE DATABASE IF NOT EXISTS fxserver_data;"
sqlpass=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w20 | head -n1)
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON fxserver_data.* TO 'fxserver_user'@'%' IDENTIFIED BY '$sqlpass' WITH GRANT OPTION; FLUSH PRIVILEGES;"
ip=$(wget -qO- https://ipstring.000webhostapp.com/)
if ! grep -q "fxserver ALL = (root) NOPASSWD: /sbin/iptables" /etc/sudoers; then
    echo "fxserver ALL = (root) NOPASSWD: /sbin/iptables" >> /etc/sudoers;
fi
if ! grep -q "fxserver ALL = (root) NOPASSWD: /bin/chmod" /etc/sudoers; then
    echo "fxserver ALL = (root) NOPASSWD: /bin/chmod" >> /etc/sudoers;
fi
mkdir -p /home/fxserver/server
mkdir -p /home/fxserver/server-data
git clone https://github.com/citizenfx/cfx-server-data.git /home/fxserver/server-data
wget "https://raw.githubusercontent.com/ap-rose/fivem-install/main/config/server.cfg" -O /home/fxserver/server-data/server.cfg
#wget "https://raw.githubusercontent.com/ap-rose/fivem-install/main/fivem-cron.sh" -O /home/fxserver/server-data/server.cfg
echo -e "\e[93m[fivem-install]\e[0m Configure FiveM server.cfg"
read -r -p "Enter your FiveM license: " fxlicense
read -r -p "Enter your Steam API: " fxsteamapi
read -r -p "Enter your SteamID (steamID64 - Hex): " fxsteamid
read -r -p "Enter your FiveM server name: " fxname
read -r -p "Enter your FiveM server description: " fxdesc
cat >> /home/fxserver/server-data/server.cfg <<EOF
sv_licenseKey $fxlicense
set steam_webApiKey "$fxsteamapi"
sv_hostname "$fxname"
sets sv_projectName "$fxname"
sets sv_projectDesc "$fxdesc"
add_principal identifier.steam:$fxsteamid group.admin # add the admin to the group
EOF
chown fxserver:fxserver -R /home/fxserver
chmod -R 0777 /home/fxserver

echo '
 ____  __  _  _  ____  _  _      __  __ _  ____  ____  __   __    __   
(  __)(  )/ )( \(  __)( \/ ) ___(  )(  ( \/ ___)(_  _)/ _\ (  )  (  )  
 ) _)  )( \ \/ / ) _) / \/ \(___))( /    /\___ \  )( /    \/ (_/\/ (_/\
(__)  (__) \__/ (____)\_)(_/    (__)\_)__)(____/ (__)\_/\_/\____/\____/
'
echo "Server IP: 			$ip:30120"
echo "Server Name: 			$fxname" 
echo "Server Description: 		$fxdesc" 
echo "FiveM License: 			$fxlicense" 
echo "Steam API: 			$fxsteamapi" 
echo "Admin SteamID: 			$fxsteamid" 
echo "SQL Password (root): 		$MYSQL_ROOT_PASSWORD"
echo "SQL Password (fxserver): 	$sqlpass"