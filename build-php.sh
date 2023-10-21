#!/bin/bash
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
mkdir -p /root/phpbuild/
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
'./configure' '--prefix=/home/xui/bin/php' '--with-fpm-user=xui' '--with-fpm-group=xui' '--enable-gd' '--with-jpeg' '--with-freetype' '--enable-static' '--disable-shared' '--enable-opcache' '--enable-fpm' '--without-sqlite3' '--without-pdo-sqlite' '--enable-mysqlnd' '--with-mysqli' '--with-curl' '--disable-cgi' '--with-zlib' '--enable-sockets' '--with-openssl' '--enable-shmop' '--enable-sysvsem' '--enable-sysvshm' '--enable-sysvmsg' '--enable-calendar' '--disable-rpath' '--enable-inline-optimization' '--enable-pcntl' '--enable-mbregex' '--enable-exif' '--enable-bcmath' '--with-mhash' '--with-gettext' '--with-xmlrpc' '--with-xsl' '--with-libxml' '--with-pdo-mysql' '--disable-mbregex'
#'./configure'  '--prefix=/home/xui/bin/php' '--with-zlib-dir' '--with-freetype-dir' '--enable-mbstring' '--enable-calendar' '--with-curl' '--with-gd' '--disable-rpath' '--enable-inline-optimization' '--with-bz2' '--with-zlib' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-pcntl' '--enable-mbregex' '--enable-exif' '--enable-bcmath' '--with-mhash' '--enable-zip' '--with-pcre-regex' '--with-pdo-mysql=mysqlnd' '--with-mysqli=mysqlnd' '--with-openssl' '--with-fpm-user=xtreamcodes' '--with-fpm-group=xtreamcodes' '--with-libdir=/lib/x86_64-linux-gnu' '--with-gettext' '--with-xmlrpc' '--with-xsl' '--enable-opcache' '--enable-fpm' '--enable-libxml' '--enable-static' '--disable-shared' '--with-jpeg-dir' '--enable-gd-jis-conv' '--with-webp-dir' '--with-xpm-dir'
make -j$(nproc --all)
killall php
killall php-fpm
killall php
killall php-fpm
killall php
killall php-fpm
make install
cd /root
rm -rf /root/phpbuild/
