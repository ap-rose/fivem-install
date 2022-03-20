#
# Author: A.P. Rose
#
#
#!/bin/bash

# Detect User OS
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
    echo "\e[91mSorry, this OS is not supported by FiveM install script.\e[0m"
    exit 1
fi

# Userinput - Root Password
read -e -p "Enter your root mysql password: " -i "$ROOT_PASSWORD" ROOT_PASSWORD
if [[ "$ROOT_PASSWORD" = "" ]]; then
    echo "mysql password required."
    exit 2
fi

# Purge current MYSQL installations
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
# Add sources
cat > /etc/apt/sources.list <<EOF
deb mirror://mirrors.ubuntu.com/mirrors.txt $(lsb_release -sc) main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt $(lsb_release -sc)-updates main restricted universe multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt $(lsb_release -sc) main restricted universe multiverse 
deb-src mirror://mirrors.ubuntu.com/mirrors.txt $(lsb_release -sc)-updates main restricted universe multiverse
deb-src http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted universe multiverse
deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner
deb-src http://archive.canonical.com/ubuntu $(lsb_release -sc) partner
EOF
apt-get update
# Get Basics
DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common wget gnupg gnupg2
wget -O- "https://download.opensuse.org/repositories/home:/andykimpe:/ubuntu-$(lsb_release -sc)/xUbuntu_$(lsb_release -sr)/Release.key" | sudo apt-key add -
echo 'deb http://download.opensuse.org/repositories/home:/andykimpe:/ubuntu-'$(lsb_release -sc)'/xUbuntu_'$(lsb_release -sr)'/ /' > /etc/apt/sources.list.d/andykimpe.list
echo 'deb-src http://download.opensuse.org/repositories/home:/andykimpe:/ubuntu-'$(lsb_release -sc)'/xUbuntu_'$(lsb_release -sr)'/ /' >> /etc/apt/sources.list.d/andykimpe.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

# Get SQL
echo "mariadb-server mysql-server/root_password password $ROOT_PASSWORD" | /usr/bin/debconf-set-selections
echo "mariadb-server mysql-server/root_password_again password $ROOT_PASSWORD" | /usr/bin/debconf-set-selections
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server libxslt1-dev e2fsprogs wget mcrypt nscd htop python libcurl3 nano unzip
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y install libcurl4
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install libapache2-mod-php5.6 php5.6-common php5.6-cli php5.6-mysql php5.6-gd php5.6-mcrypt php5.6-curl php-pear php5.6-imap php5.6-xmlrpc php5.6-xsl php5.6-intl php php-dev php5.6-dev
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -y install phpmyadmin php5.6-mbstring
update-alternatives --set php /usr/bin/php5.6
update-alternatives --set phar /usr/bin/phar5.6
update-alternatives --set phar.phar /usr/bin/phar.phar5.6
update-alternatives --set phpize /usr/bin/phpize5.6
update-alternatives --set php-config /usr/bin/php-config5.6
a2dismod php7.0
a2dismod php7.1
a2dismod php7.2
a2dismod php7.3
a2dismod php7.4
a2enmod php5.6
phpenmod -v 5.6 mcrypt
phpenmod -v 5.6 mbstring
service apache2 restart
cd /usr/share/
rm -rf /usr/share/phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/4.9.5/phpMyAdmin-4.9.5-all-languages.tar.xz
tar -xvf phpMyAdmin-4.9.5-all-languages.tar.xz
rm -f phpMyAdmin-4.9.5-all-languages.tar.xz
mv phpMyAdmin-4.9.5-all-languages phpmyadmin
chmod 777 -R phpmyadmin
chmod 777 -R phpmyadmin/*
ln -s /etc/phpmyadmin/config.inc.php /usr/share/phpmyadmin/config.inc.php
chmod 644 /etc/phpmyadmin/config.inc.php
systemctl stop mariadb
wget "https://raw.githubusercontent.com/ap-rose/fivem-install/main/Configs/my.cnf" -O /etc/mysql/my.cnf
chmod 644 /etc/mysql/my.cnf
systemctl start mariadb
apt-get -y install sshpass
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
getent passwd fxserver
adduser --system --shell /bin/false --group --disabled-login fxserver 
mkdir -p /home/fxserver

