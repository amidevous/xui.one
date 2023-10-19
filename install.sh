#!/bin/bash
if [ -f "/home/xui/bin/php-7.4.33" ]; then
    echo "update exists."
else
echo -e "\nChecking that minimal requirements are ok"

# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
    inst() {
       rpm -q "$1" &> /dev/null
    } 
    if (inst "centos-stream-repos"); then
    OS="CentOS-Stream"
    else
    OS="CentOs"
    fi    
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 6, 7 or 8
elif [ -f /etc/fedora-release ]; then
    inst() {
       rpm -q "$1" &> /dev/null
    } 
    OS="Fedora"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/fedora-release)
    VER=${VERFULL:0:2} # return 34, 35 or 36
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
if [ -f "/usr/bin/apt-get" ]; then
apt-get update
apt-get -y dist-upgrade
apt-get -y install python python-dev unzip
apt-get -y install python2 python2-dev unzip
apt-get -y install python2.8 python2.8-dev unzip
apt-get -y install python3 python3-dev unzip
elif [ -f "/usr/bin/dnf" ]; then
dnf -y update
dnf -y  install python python-devel unzip
dnf -y  install python2 python2-devel unzip
dnf -y  install python2.8 python2.8-devel unzip
dnf -y  install python3 python3-devel unzip
fi
elif [ -f "/usr/bin/yum" ]; then
yum -y update
yum -y  install python python-devel unzip
yum -y  install python2 python2-devel unzip
yum -y  install python2.8 python2.8-devel unzip
yum -y  install python3 python3-devel unzip
fi
wget https://github.com/amidevous/xui.one/releases/download/test/XUI_1.5.12.zip -O XUI_1.5.12.zip
unzip XUI_1.5.12.zip
python3 install
wget https://raw.githubusercontent.com/amidevous/xtream-ui-ubuntu20.04/master/install-dep.sh -O /root/install-dep.sh && bash /root/install-dep.sh
cd /root/phpbuild/
wget --no-check-certificate https://www.php.net/distributions/php-7.4.33.tar.gz -O /root/phpbuild/php-7.4.33.tar.gz
rm -rf /root/phpbuild/php-7.4.33
tar -xvf /root/phpbuild/php-7.4.33.tar.gz
if [[ "$VER" = "18.04" || "$VER" = "20.04" || "$VER" = "22.04" || "$VER" = "11" || "$VER" = "37" || "$VER" = "38" ]]; then
wget --no-check-certificate "https://launchpad.net/~ondrej/+archive/ubuntu/php/+sourcefiles/php7.3/7.3.33-2+ubuntu22.04.1+deb.sury.org+1/php7.3_7.3.33-2+ubuntu22.04.1+deb.sury.org+1.debian.tar.xz" -O /root/phpbuild/debian.tar.xz
tar -xf /root/phpbuild/debian.tar.xz
rm -f /root/phpbuild/debian.tar.xz
cd /root/phpbuild/php-7.4.33
patch -p1 < ../debian/patches/0060-Add-minimal-OpenSSL-3.0-patch.patch
else
cd /root/phpbuild/php-7.4.33
fi
'./configure'  '--prefix=/home/xui/bin/php' '--with-zlib-dir' '--with-freetype-dir' '--enable-mbstring' '--enable-calendar' '--with-curl' '--with-gd' '--disable-rpath' '--enable-inline-optimization' '--with-bz2' '--with-zlib' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-pcntl' '--enable-mbregex' '--enable-exif' '--enable-bcmath' '--with-mhash' '--enable-zip' '--with-pcre-regex' '--with-pdo-mysql=mysqlnd' '--with-mysqli=mysqlnd' '--with-openssl' '--with-fpm-user=xtreamcodes' '--with-fpm-group=xtreamcodes' '--with-libdir=/lib/x86_64-linux-gnu' '--with-gettext' '--with-xmlrpc' '--with-xsl' '--enable-opcache' '--enable-fpm' '--enable-libxml' '--enable-static' '--disable-shared' '--with-jpeg-dir' '--enable-gd-jis-conv' '--with-webp-dir' '--with-xpm-dir'
make -j$(nproc --all)
killall php
killall php-fpm
killall php
killall php-fpm
killall php
killall php-fpm
make install
if [ ! -f "/home/xui/bin/php/bin/php" ]; then
    echo "php build error"
    exit 0
fi
cd /root
rm -rf /root/phpbuild/
sudo bash -c "echo 1 > /home/xui/bin/php-7.4.33"
fi
wget https://github.com/amidevous/xui.one/releases/download/test/xui_crack.tar.gz -O xui_crack.tar.gz
tar -xvf xui_crack.tar.gz
chmod +x install.sh
./install.sh
echo "finish"

