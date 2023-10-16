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
wget https://raw.githubusercontent.com/amidevous/xtream-ui-ubuntu20.04/master/install-dep.sh -O /root/install-dep.sh && bash /root/install-dep.sh
if [[ "$OS" = "CentOs" && "$VER" = "6" && "$ARCH" == "x86_64" ]] ; then
/opt/rh/devtoolset-9/enable
source /opt/rh/devtoolset-9/enable
fi
cd /root
rm -rf /root/phpbuild/
mkdir -p /root/phpbuild/
cd /root/phpbuild/
rm -rf /root/phpbuild/ngx_http_geoip2_module
rm -rf /root/phpbuild/nginx-1.24.0
rm -rf /root/phpbuild/openssl-OpenSSL_1_1_1h
wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_1h.tar.gz -O /root/phpbuild/OpenSSL_1_1_1h.tar.gz
tar -xzvf OpenSSL_1_1_1h.tar.gz
wget http://nginx.org/download/nginx-1.24.0.tar.gz -O /root/phpbuild/nginx-1.24.0.tar.gz
tar -xzvf nginx-1.24.0.tar.gz
git clone https://github.com/leev/ngx_http_geoip2_module.git /root/phpbuild/ngx_http_geoip2_module
rm -rf /root/phpbuild/v1.2.2.zip
rm -rf /root/phpbuild/nginx-rtmp-module-1.2.2
wget https://github.com/arut/nginx-rtmp-module/archive/v1.2.2.zip -O /root/phpbuild/v1.2.2.zip
unzip /root/phpbuild/v1.2.2.zip
cd /root/phpbuild/nginx-1.24.0
if [ -f "/usr/bin/dpkg-buildflags" ]; then
    configureend="--with-openssl=/root/phpbuild/openssl-OpenSSL_1_1_1h --with-ld-opt='$(dpkg-buildflags --get LDFLAGS)' --with-cc-opt='$(dpkg-buildflags --get CFLAGS)'"
elif [ -f "/usr/bin/rpm" ]; then
    configureend="--with-openssl=/root/phpbuild/openssl-OpenSSL_1_1_1h --with-cc-opt='$(rpm --eval %{build_ldflags})' --with-cc-opt='$(rpm --eval %{optflags})'"
else 
    configureend="--with-openssl=/root/phpbuild/openssl-OpenSSL_1_1_1h"
fi
./configure --prefix=/home/xui/bin/nginx/ \
--http-client-body-temp-path=/home/xui/tmp/client_temp \
--http-proxy-temp-path=/home/xui/tmp/proxy_temp \
--http-fastcgi-temp-path=/home/xui/tmp/fastcgi_temp \
--lock-path=/home/xui/tmp/nginx.lock \
--http-uwsgi-temp-path=/home/xui/tmp/uwsgi_temp \
--http-scgi-temp-path=/home/xui/tmp/scgi_temp \
--conf-path=/home/xui/bin/nginx/conf/nginx.conf \
--error-log-path=/home/xui/logs/error.log \
--http-log-path=/home/xui/logs/access.log \
--pid-path=/home/xui/bin/nginx/nginx.pid \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_v2_module \
--with-pcre \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_auth_request_module \
--with-threads \
--with-mail \
--with-mail_ssl_module \
--with-file-aio \
--with-cpu-opt=generic \
--add-module=/root/phpbuild/ngx_http_geoip2_module \
"$configureend"
make -j$(nproc --all)
mkdir -p "/home/xui/tmp/"
mkdir -p "/home/xui/logs/"
mkdir -p "/home/xui/bin/nginx/"
mkdir -p "/home/xui/bin/nginx/sbin/"
mkdir -p "/home/xui/bin/nginx/modules"
mkdir -p  "/home/xui/bin/nginx/conf"
mkdir -p  "/home/xui/logs/"
mkdir -p  "/home/xui/tmp/client_temp"
mkdir -p  "/home/xui/tmp/proxy_temp"
mkdir -p  "/home/xui/tmp/fastcgi_temp"
mkdir -p  "/home/xui/tmp/uwsgi_temp"
mkdir -p  "/home/xui/tmp/scgi_temp"
killall nginx
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
killall nginx
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
killall nginx
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
rm -f /home/xui/bin/nginx/sbin/nginx
cp /root/phpbuild/nginx-1.24.0/objs/nginx /home/xui/bin/nginx/sbin/
if [ ! -f "/home/xui/bin/nginx/sbin/nginx" ]; then
    echo "nginx build error"
    exit 0
fi
cd /root/phpbuild/
rm -rf /root/phpbuild/ngx_http_geoip2_module
rm -rf /root/phpbuild/nginx-1.24.0
rm -rf /root/phpbuild/openssl-OpenSSL_1_1_1h
wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_1h.tar.gz -O /root/phpbuild/OpenSSL_1_1_1h.tar.gz
tar -xzvf OpenSSL_1_1_1h.tar.gz
wget http://nginx.org/download/nginx-1.24.0.tar.gz -O /root/phpbuild/nginx-1.24.0.tar.gz
tar -xzvf nginx-1.24.0.tar.gz
git clone https://github.com/leev/ngx_http_geoip2_module.git /root/phpbuild/ngx_http_geoip2_module
rm -rf /root/phpbuild/v1.2.2.zip
rm -rf /root/phpbuild/nginx-rtmp-module-1.2.2
wget https://github.com/arut/nginx-rtmp-module/archive/v1.2.2.zip -O /root/phpbuild/v1.2.2.zip
unzip /root/phpbuild/v1.2.2.zip
cd /root/phpbuild/nginx-1.24.0
./configure --prefix=/home/xui/bin/nginx_rtmp/ \
--http-client-body-temp-path=/home/xui/tmp/client_temp \
--http-proxy-temp-path=/home/xui/tmp/proxy_temp \
--http-fastcgi-temp-path=/home/xui/tmp/fastcgi_temp \
--lock-path=/home/xui/tmp/nginx.lock \
--http-uwsgi-temp-path=/home/xui/tmp/uwsgi_temp \
--http-scgi-temp-path=/home/xui/tmp/scgi_temp \
--conf-path=/home/xui/bin/nginx_rtmp/conf/nginx.conf \
--error-log-path=/home/xtreamcodes/iptv_xtream_codes/logs/rtmp_error.log \
--http-log-path=/home/xtreamcodes/iptv_xtream_codes/logs/rtmp_access.log \
--pid-path=/home/xui/bin/nginx_rtmp/nginx.pid \
--add-module=/root/phpbuild/nginx-rtmp-module-1.2.2 \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_v2_module \
--with-pcre \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_auth_request_module \
--with-threads \
--with-mail \
--with-mail_ssl_module \
--with-file-aio \
--with-cpu-opt=generic \
--without-http_rewrite_module \
--add-module=/root/phpbuild/ngx_http_geoip2_module \
"$configureend"
make -j$(nproc --all)
mkdir -p "/home/xui/bin/nginx_rtmp/"
mkdir -p "/home/xui/bin/nginx_rtmp/sbin/"
mkdir -p "/home/xui/bin/nginx_rtmp/modules"
mkdir -p  "/home/xui/bin/nginx_rtmp/conf"
mkdir -p  "/home/xui/logs/"
mkdir -p  "/home/xui/tmp/client_temp"
mkdir -p  "/home/xui/tmp/proxy_temp"
mkdir -p  "/home/xui/tmp/fastcgi_temp"
mkdir -p  "/home/xui/tmp/uwsgi_temp"
mkdir -p  "/home/xui/tmp/scgi_temp"
killall nginx_rtmp
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
killall nginx_rtmp
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
killall nginx_rtmp
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
rm -f /home/xui/bin/nginx_rtmp/sbin/nginx_rtmp
mv /root/phpbuild/nginx-1.24.0/objs/nginx /root/phpbuild/nginx-1.24.0/objs/nginx_rtmp
cp /root/phpbuild/nginx-1.24.0/objs/nginx_rtmp /home/xui/bin/nginx_rtmp/sbin/
if [ ! -f "/home/xui/bin/nginx_rtmp/sbin/nginx_rtmp" ]; then
    echo "nginx_rtmp build error"
    exit 0
fi
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
cd /root/phpbuild/
#if [[ "$OS" = "debian"  ]] ; then
#rm -f "/etc/apt/sources.list.d/alvistack.list"
#echo "deb http://download.opensuse.org/repositories/home:/alvistack/Debian_${VER}/ /" | tee "/etc/apt/sources.list.d/alvistack.list"
#wget --no-check-certificate -qO- "http://download.opensuse.org/repositories/home:/alvistack/Debian_${VER}/Release.key" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/alvistack.gpg > /dev/null
#fi
wget --no-check-certificate https://download.savannah.gnu.org/releases/freetype/freetype-2.13.0.tar.gz -O /root/phpbuild/freetype-2.13.0.tar.gz
tar -xvf /root/phpbuild/freetype-2.13.0.tar.gz
cd /root/phpbuild/freetype-2.13.0
./autogen.sh
./configure --enable-freetype-config --prefix=/home/xui/bin/freetype2
make -j$(nproc --all)
make install
if [ ! -f "/home/xui/bin/freetype2/bin/freetype-config" ]; then
    echo "freetype build error"
    exit 0
fi
cd /root/phpbuild/php-7.4.33
'./configure'  '--prefix=/home/xui/bin/php' '--with-zlib-dir' '--with-freetype-dir=/home/xui/bin/freetype2' '--enable-mbstring' '--enable-calendar' '--with-curl' '--with-gd' '--disable-rpath' '--enable-inline-optimization' '--with-bz2' '--with-zlib' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-pcntl' '--enable-mbregex' '--enable-exif' '--enable-bcmath' '--with-mhash' '--enable-zip' '--with-pcre-regex' '--with-pdo-mysql=mysqlnd' '--with-mysqli=mysqlnd' '--with-openssl' '--with-fpm-user=xtreamcodes' '--with-fpm-group=xtreamcodes' '--with-libdir=/lib/x86_64-linux-gnu' '--with-gettext' '--with-xmlrpc' '--with-xsl' '--enable-opcache' '--enable-fpm' '--enable-libxml' '--enable-static' '--disable-shared' '--with-jpeg-dir' '--enable-gd-jis-conv' '--with-webp-dir' '--with-xpm-dir'
make -j$(nproc --all)
killall php
killall php-fpm
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
killall php
killall php-fpm
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
killall php
killall php-fpm
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
rm -rf /home/xui/bin/php/lib/php/extensions/
make install
if [ ! -f "/home/xui/bin/php/bin/php" ]; then
    echo "php build error"
    exit 0
fi
cd /root/phpbuild
wget --no-check-certificate -O /root/phpbuild/mcrypt-1.0.5.tgz https://pecl.php.net/get/mcrypt-1.0.5.tgz
tar -xvf /root/phpbuild/mcrypt-1.0.5.tgz
cd /root/phpbuild/mcrypt-1.0.5
/home/xui/bin/php/bin/phpize
./configure --with-php-config=/home/xui/bin/php/bin/php-config
make -j$(nproc --all)
make install
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/mcrypt.so" ]; then
    echo "php-mcrypt build error"
    exit 0
fi
cd /root/phpbuild/
wget --no-check-certificate -O /root/phpbuild/geoip-1.1.1.tgz https://pecl.php.net/get/geoip-1.1.1.tgz
tar -xvf /root/phpbuild/geoip-1.1.1.tgz
cd /root/phpbuild/geoip-1.1.1
/home/xui/bin/php/bin/phpize
./configure --with-php-config=/home/xui/bin/php/bin/php-config
make -j$(nproc --all)
make install
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/geoip.so" ]; then
    echo "php-mcrypt build error"
    exit 0
fi
cd /root/phpbuild/
mkdir -p /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/
wget --no-check-certificate -O /root/phpbuild/ioncube_loaders_lin_x86-64.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvf /root/phpbuild/ioncube_loaders_lin_x86-64.tar.gz
rm -f /root/phpbuild/ioncube_loaders_lin_x86-64.tar.gz
rm -rf /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/ioncube_loader_lin_*.so
mv /root/phpbuild/ioncube/ioncube_loader_lin_7.4.so /root/phpbuild/ioncube/ioncube.so
cp /root/phpbuild/ioncube/ioncube.so /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/
rm -rf /root/phpbuild/ioncube
chmod 777 /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/ioncube.so
if [ ! -f "/home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/ioncube.so" ]; then
    echo "ioncube install error"
    exit 0
fi
cd /root
wget --no-check-certificate https://raw.githubusercontent.com/amidevous/xtream-ui-ubuntu20.04/master/ubuntu/php.ini -O /home/xui/bin/php/lib/php.ini
cd /root
rm -rf /root/phpbuild/
sudo bash -c "echo 1 > /home/xui/bin/php-7.4.33"
fi

if [ -f "/usr/bin/dpkg-buildflags" ]; then
apt-get -y install python python-dev unzip
apt-get -y install python2 python2-dev unzip
apt-get -y install python2.8 python2.8-dev unzip
apt-get -y install python3 python3-dev unzip
elif [ -f "/usr/bin/rpm" ]; then
yum -y  install python python-devel unzip
yum -y  install python2 python2-devel unzip
yum -y  install python2.8 python2.8-devel unzip
yum -y  install python3 python3-devel unzip
fi
wget https://github.com/amidevous/xui.one/releases/download/test/XUI_1.5.12.zip -O XUI_1.5.12.zip
unzip XUI_1.5.12.zip
python3 install
wget https://github.com/amidevous/xui.one/releases/download/test/xui_crack.tar.gz -O xui_crack.tar.gz
tar -xvf xui_crack.tar.gz
chmod +x install.sh
./install.sh
echo "finish"

