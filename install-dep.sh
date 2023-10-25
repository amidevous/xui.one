#!/bin/bash
echo -e "\nChecking that minimal requirements are ok"
# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
    inst() {
       rpm -q "$1" &> /dev/null
    } 
    if (inst "centos-stream-repos"); then
    OS="CentOs-Stream"
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
if [[ "$VER" = "8" && "$OS" = "CentOs" ]]; then
	echo "Centos 8 obsolete udate to CentOS-Stream 8"
	echo "this operation may take some time"
	sleep 60
	# change repository to use vault.centos.org CentOS 8 found online to vault.centos.org
	find /etc/yum.repos.d -name '*.repo' -exec sed -i 's|mirrorlist=http://mirrorlist.centos.org|#mirrorlist=http://mirrorlist.centos.org|' {} \;
	find /etc/yum.repos.d -name '*.repo' -exec sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|' {} \;
	#update package list
	dnf update -y
	#upgrade all packages to latest CentOS 8
	dnf upgrade -y
	#install CentOS-Stream 8 repository
	dnf -y install centos-release-stream --allowerasing
	#install rpmconf
	dnf -y install rpmconf
	#set config file with rpmconf
	rpmconf -a
	# remove Centos 8 repository and set CentOS-Stream 8 repository by default
	dnf -y swap centos-linux-repos centos-stream-repos
	# system upgrade
	dnf -y distro-sync
	# ceanup old rpmconf file create
	find / -name '*.rpmnew' -exec rm -f {} \;
	find / -name '*.rpmsave' -exec rm -f {} \;
	OS="CentOs-Stream"
	fi
	mkdir -p /etc/yum.repos.d/


echo "Detected : $OS  $VER  $ARCH"
if [[ "$OS" = "CentOs" && "$VER" = "6" && "$ARCH" == "x86_64" ||
"$OS" = "CentOs" && "$VER" = "7" && "$ARCH" == "x86_64" ||
"$OS" = "CentOs-Stream" && "$VER" = "8" && "$ARCH" == "x86_64" ||
"$OS" = "CentOs-Stream" && "$VER" = "9" && "$ARCH" == "x86_64" ||
"$OS" = "Fedora" && ("$VER" = "36" || "$VER" = "37" || "$VER" = "38" ) && "$ARCH" == "x86_64" ||
"$OS" = "Ubuntu" && ( "$VER" = "18.04" || "$VER" = "20.04" || "$VER" = "22.04" ) && "$ARCH" == "x86_64" ||
"$OS" = "debian" && ("$VER" = "10" || "$VER" = "11" ) && "$ARCH" == "x86_64" ]] ; then
echo "Ok."
else
    echo "Sorry, this OS is not supported by Xtream UI."
    exit 1
fi
echo -e "\n-- Updating repositories and packages sources"
if [[ "$OS" = "CentOs" ]] ; then
    PACKAGE_INSTALLER="yum -y install"
    PACKAGE_REMOVER="yum -y remove"
    PACKAGE_UPDATER="yum -y update"
    PACKAGE_UTILS="yum-utils"
    PACKAGE_GROUPINSTALL="yum -y groupinstall"
    PACKAGE_SOURCEDOWNLOAD="yumdownloader --source"
    BUILDDEP="yum-builddep -y"
    MYSQLCNF=/etc/my.cnf
elif [[ "$OS" = "Fedora" || "$OS" = "CentOs-Stream"  ]]; then
    PACKAGE_INSTALLER="dnf -y install"
    PACKAGE_REMOVER="dnf -y remove"
    PACKAGE_UPDATER="dnf -y update"
    PACKAGE_UTILS="dnf-utils" 
    PACKAGE_GROUPINSTALL="dnf -y groupinstall"
    PACKAGE_SOURCEDOWNLOAD="dnf download --source"
    BUILDDEP="dnf build-dep -y"
    MYSQLCNF=/etc/my.cnf
elif [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
    PACKAGE_INSTALLER="apt-get -y install"
    PACKAGE_REMOVER="apt-get -y purge"
    MYSQLCNF=/etc/mysql/mariadb.cnf
    inst() {
       dpkg -l "$1" 2> /dev/null | grep '^ii' &> /dev/null
    }
fi
if [[ "$OS" = "CentOs" || "$OS" = "CentOs-Stream" || "$OS" = "Fedora" ]]; then
	if [[ "$OS" = "CentOs" || "$OS" = "CentOs-Stream" ]]; then
		#To fix some problems of compatibility use of mirror centos.org to all users
		#Replace all mirrors by base repos to avoid any problems.
		find /etc/yum.repos.d -name '*.repo' -exec sed -i 's|mirrorlist=http://mirrorlist.centos.org|#mirrorlist=http://mirrorlist.centos.org|' {} \;
		find /etc/yum.repos.d -name '*.repo' -exec sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://mirror.centos.org|' {} \;
		#check if the machine and on openvz
		if [ -f "/etc/yum.repos.d/vz.repo" ]; then
			sed -i "s|mirrorlist=http://vzdownload.swsoft.com/download/mirrors/centos-$VER|baseurl=http://vzdownload.swsoft.com/ez/packages/centos/$VER/$ARCH/os/|" "/etc/yum.repos.d/vz.repo"
			sed -i "s|mirrorlist=http://vzdownload.swsoft.com/download/mirrors/updates-released-ce$VER|baseurl=http://vzdownload.swsoft.com/ez/packages/centos/$VER/$ARCH/updates/|" "/etc/yum.repos.d/vz.repo"
		fi
		#EPEL Repo Install
		$PACKAGE_INSTALLER epel-release
	fi
	$PACKAGE_INSTALLER $PACKAGE_UTILS
	#disable deposits that could result in installation errors
	# disable all repository
	if [[ "$OS" = "Fedora" ]]; then
		dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
		dnf -y install https://rpms.remirepo.net/fedora/remi-release-$(rpm -E %fedora).rpm
	fi
	if [[ "$OS" = "CentOs" || "$OS" = "CentOs-Stream" ]]; then
if [[ "$OS" = "CentOs" && "$VER" = "6" ]] ; then
cat > /etc/yum.repos.d/mariadb.repo <<EOF
[mariadb]
name=MariaDB RPM source
baseurl=http://mirror.mariadb.org/yum/10.2/rhel/$VER/$ARCH/
enabled=1
gpgcheck=0
EOF
cat > CentOS-Base.repo <<EOF
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-\$releasever - Base
enabled=1
baseurl=https://vault.centos.org/6.10/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#released updates 
[updates]
name=CentOS-\$releasever - Updates
enabled=1
baseurl=https://vault.centos.org/6.10/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
enabled=1
baseurl=https://vault.centos.org/6.10/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus
baseurl=https://vault.centos.org/6.10/centosplus/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#contrib - packages by Centos Users
[contrib]
name=CentOS-\$releasever - Contrib
baseurl=https://vault.centos.org/6.10/contrib/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
EOF
	rm -rf /etc/yum.repos.d/CentOS-Base.repo
	cp CentOS-Base.repo /etc/yum.repos.d/
	rm -rf CentOS-Base.repo
	$PACKAGE_INSTALLER centos-release
	$PACKAGE_INSTALLER centos-release-scl
	$PACKAGE_INSTALLER centos-release-scl-rh
	$PACKAGE_INSTALLER epel-release
cat > epel.repo <<EOF
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
baseurl=https://archives.fedoraproject.org/pub/archive/epel/6/\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 6 - \$basearch - Debug
baseurl=https://archives.fedoraproject.org/pub/archive/epel/6/\$basearch/debug
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 6 - \$basearch - Source
baseurl=https://archives.fedoraproject.org/pub/archive/epel/6/SRPMS
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1
EOF
rm -f /etc/yum.repos.d/epel.repo
cp epel.repo /etc/yum.repos.d/
yum -y update
rm -f /etc/yum.repos.d/epel.repo
cp epel.repo /etc/yum.repos.d/
rm -f epel.repo
else
$PACKAGE_INSTALLER epel-release
cat > /etc/yum.repos.d/mariadb.repo <<EOF
[mariadb]
name=MariaDB RPM source
baseurl=http://mirror.mariadb.org/yum/10.6/rhel/$VER/x86_64/
enabled=1
gpgcheck=0
EOF
fi
$PACKAGE_INSTALLER --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
$PACKAGE_INSTALLER --nogpgcheck https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
	elif [[ "$OS" = "Fedora" ]]; then
cat > /etc/yum.repos.d/mariadb.repo <<EOF
[mariadb]
name=MariaDB RPM source
baseurl=http://mirror.mariadb.org/yum/10.6/fedora/$VER/x86_64/
enabled=1
gpgcheck=0
EOF
	fi
	find /etc/yum.repos.d -name '*.repo' -exec sed -i 's|enabled=1|enabled=0|' {} \;
	# enable vz repository if present for openvz system
	if [ -f "/etc/yum.repos.d/vz.repo" ]; then
		sed -i "s|enabled=0|enabled=1|" "/etc/yum.repos.d/vz.repo"
	fi
	enablerepo() {
	if [ "$OS" = "CentOs" ]; then
        	yum-config-manager --enable $1
	else
		dnf config-manager --set-enabled $1
        fi
	}
	if [ "$OS" = "CentOs" ]; then
		# enable official repository CentOs 7 Base
		enablerepo base
		# enable official repository CentOs 7 Updates
		enablerepo updates
		# enable official repository Fedora Epel
		enablerepo epel
		enablerepo centos-sclo-rh
		enablerepo centos-sclo-sclo
		enablerepo mariadb
		enablerepo rpmfusion-free
		enablerepo rpmfusion-free-updates
		enablerepo rpmfusion-nonfree
		enablerepo rpmfusion-nonfree-updates
		enablerepo remi
		enablerepo remi-safe
		enablerepo remi-php73
		enablerepo remi-php74
		yum -y install wget
	elif [ "$OS" = "CentOs-Stream" ]; then
		# enable official repository CentOs Stream BaseOS
		enablerepo baseos
		# enable official repository CentOs Stream AppStream
		enablerepo appstream
		# enable official repository CentOs Stream extra
		enablerepo extras
		# enable official repository CentOs Stream extra-common
		enablerepo extras-common
		# enable official repository CentOs Stream PowerTools
		enablerepo powertools
		# enable official repository CentOs Stream Devel
		enablerepo devel
		# enable official repository CentOs Stream CRB
		enablerepo crb
		# enable official repository CentOs Stream CRB
		enablerepo CRB
		# enable official repository Fedora Epel
		enablerepo epel
		# enable official repository Fedora Epel
		enablerepo epel-modular
		enablerepo mariadb
		enablerepo rpmfusion-free
		enablerepo rpmfusion-free-updates
		enablerepo rpmfusion-nonfree
		enablerepo rpmfusion-nonfree-updates
		enablerepo remi
		enablerepo remi-safe
		dnf -y install wget
	elif [ "$OS" = "Fedora" ]; then
		enablerepo fedora-cisco-openh264
		enablerepo fedora-modular
		enablerepo fedora
		enablerepo updates-modular
		enablerepo updates
		enablerepo mariadb
		enablerepo rpmfusion-free
		enablerepo rpmfusion-free-updates
		enablerepo rpmfusion-nonfree
		enablerepo rpmfusion-nonfree-updates
		enablerepo remi
		enablerepo remi-safe
		dnf -y install wget
	fi
	yumpurge() {
	for package in $@
	do
		echo "removing config files for $package"
		for file in $(rpm -q --configfiles $package)
		do
			echo "  removing $file"
			rm -f $file
		done
		rpm -e $package
	done
	}

	# We need to disable SELinux...
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0

	# Stop conflicting services and iptables to ensure all services will work
	if  [[ "$VER" = "7" || "$VER" = "8" || "$VER" = "34" || "$VER" = "35" || "$VER" = "36" ]]; then
		systemctl  stop sendmail.service
		systemctl  disabble sendmail.service
	else
		service sendmail stop
		chkconfig sendmail off
	fi
	# disable firewall
	$PACKAGE_INSTALLER iptables
	$PACKAGE_INSTALLER firewalld
	if  [[ "$VER" = "7" || "$VER" = "8" || "$VER" = "34" || "$VER" = "35" || "$VER" = "36" ]]; then
		FIREWALL_SERVICE="firewalld"
	else
		FIREWALL_SERVICE="iptables"
	fi
	if  [[ "$VER" = "7" || "$VER" = "8" || "$VER" = "34" || "$VER" = "35" || "$VER" = "36" ]]; then
		systemctl  save "$FIREWALL_SERVICE".service
		systemctl  stop "$FIREWALL_SERVICE".service
		systemctl  disable "$FIREWALL_SERVICE".service
	else
		service "$FIREWALL_SERVICE" save
		service "$FIREWALL_SERVICE" stop
		chkconfig "$FIREWALL_SERVICE" off
	fi
	# Removal of conflicting packages prior to installation.
	yumpurge bind-chroot
	yumpurge qpid-cpp-client
	$PACKAGE_UPDATER
	$PACKAGE_INSTALLER yum-plugin-copr
	$PACKAGE_INSTALLER yum-plugins-copr
	$PACKAGE_INSTALLER dnf-plugin-core
	$PACKAGE_INSTALLER dnf-plugins-core
	$PACKAGE_INSTALLER dnf-plugin-copr
	$PACKAGE_INSTALLER dnf-plugins-copr
	$PACKAGE_INSTALLER sudo vim make wget nano
    	$PACKAGE_INSTALLER ld-linux.so.2 libbz2.so.1 libdb-4.7.so libgd.so.2
    	$PACKAGE_INSTALLER db-devel 
	$PACKAGE_INSTALLER libdb-devel
    	$PACKAGE_INSTALLER gd-devel
    	$PACKAGE_INSTALLER glibc32
    	$PACKAGE_INSTALLER bzip2-libs 
	$PACKAGE_INSTALLER curl-devel
	$PACKAGE_INSTALLER perl-libwww-perl
	$PACKAGE_INSTALLER libxml2 libxml2-devel bzip2-devel gcc gcc-c++ at ca-certificates psmisc bash-completion jq sshpass net-tools
	$PACKAGE_GROUPINSTALL --with-optional -y "C Development Tools and Libraries" "Development Tools" "Fedora Packager"
	$PACKAGE_INSTALLER e2fslibs
	$PACKAGE_INSTALLER e2fsprogs
	$PACKAGE_INSTALLER e2fsprogs-libs
	$PACKAGE_INSTALLER libcurl-devel libxslt-devel GeoIP-devel nscd htop unzip httpd httpd-devel zip mc libpng-devel
	$PACKAGE_INSTALLER python3
	$PACKAGE_INSTALLER python3-pip
	$PACKAGE_INSTALLER python
	$PACKAGE_INSTALLER python-pip
	$PACKAGE_INSTALLER python2
	$PACKAGE_INSTALLER python2-pip
	$PACKAGE_INSTALLER python
	$PACKAGE_INSTALLER python-pip
	$PACKAGE_INSTALLER python-paramiko
	$PACKAGE_INSTALLER python2-paramiko
	$PACKAGE_INSTALLER python3-paramiko
	$PACKAGE_INSTALLER mcrypt
	$PACKAGE_INSTALLER mcrypt-devel
	$PACKAGE_INSTALLER libmcrypt
	$PACKAGE_INSTALLER libmcrypt-devel
	$PACKAGE_INSTALLER MariaDB-client 
	$PACKAGE_INSTALLER MariaDB
	$PACKAGE_INSTALLER mariadb-client
	$PACKAGE_INSTALLER mariadb
	$PACKAGE_INSTALLER MariaDB-server
	$PACKAGE_INSTALLER mariadb-server
	$PACKAGE_INSTALLER MariaDB-devel
	$PACKAGE_INSTALLER mariadb-devel
	$PACKAGE_INSTALLER libX11-devel
	$PACKAGE_INSTALLER X11-devel
	$PACKAGE_INSTALLER libpng-devel zlib-devel bzip2-devel gcc libxml2-devel curl httpd pam nginx pam-devel httpd-devel
	$PACKAGE_INSTALLER gnupg2
	$PACKAGE_INSTALLER gnupg
	$PACKAGE_INSTALLER curl-devel
	$PACKAGE_INSTALLER libcurl-devel
	$PACKAGE_INSTALLER nginx-devel
	$PACKAGE_INSTALLER libstdc++-devel openssl-devel sqlite-devel libedit-devel
	$PACKAGE_INSTALLER smtpdaemon
	$PACKAGE_INSTALLER pcre-devel
	$PACKAGE_INSTALLER pcre2-devel
	$PACKAGE_INSTALLER pcre3-devel
	$PACKAGE_INSTALLER libxcrypt-devel
	$PACKAGE_INSTALLER xcrypt-devel
	$PACKAGE_INSTALLER perl-interpreter
	$PACKAGE_INSTALLER autoconf automake
	$PACKAGE_INSTALLER make
	$PACKAGE_INSTALLER libtool
	$PACKAGE_INSTALLER libtool-ltdl-devel
	$PACKAGE_INSTALLER systemtap-sdt-devel
	$PACKAGE_INSTALLER systemd-devel
	$PACKAGE_INSTALLER tzdata
	$PACKAGE_INSTALLER procps
	$PACKAGE_INSTALLER procps-ng
	$PACKAGE_INSTALLER libacl-devel
	$PACKAGE_INSTALLER krb5-devel
	$PACKAGE_INSTALLER libc-client-devel
	$PACKAGE_INSTALLER cyrus-sasl-devel
	$PACKAGE_INSTALLER openldap-devel libpq-devel unixODBC-devel firebird-devel net-snmp-devel oniguruma-devel gd-devel gmp-devel
	$PACKAGE_INSTALLER db4-devel
	$PACKAGE_INSTALLER libdb-devel
	$PACKAGE_INSTALLER tokyocabinet-devel lmdb-devel qdbm-devel libtidy-devel freetds-devel aspell-devel libicu-devel
	$PACKAGE_INSTALLER enchant-devel
	$PACKAGE_INSTALLER libenchant-devel
	$PACKAGE_INSTALLER libsodium-devel
	$PACKAGE_INSTALLER sodium-devel
	$PACKAGE_INSTALLER libffi-devel
	$PACKAGE_INSTALLER ffi-devel
	$PACKAGE_INSTALLER libxslt-devel
	$PACKAGE_INSTALLER xslt-devel
	$PACKAGE_INSTALLER yasm nasm gnutls-devel
	$PACKAGE_INSTALLER lame-devel libass-devel fdk-aac-devel
	$PACKAGE_INSTALLER opus-devel
	$PACKAGE_INSTALLER libopus-devel
	$PACKAGE_INSTALLER librtmp-devel
	$PACKAGE_INSTALLER librtmp
	$PACKAGE_INSTALLER rtmp-devel
	$PACKAGE_INSTALLER rtmp
	$PACKAGE_INSTALLER rtmpdump
	$PACKAGE_INSTALLER alsa-lib-devel
	$PACKAGE_INSTALLER AMF-devel
	$PACKAGE_INSTALLER faac-devel
	$PACKAGE_INSTALLER flite-devel fontconfig-devel freetype-devel fribidi-devel frei0r-devel
	$PACKAGE_INSTALLER game-music-emu-devel gsm-devel ilbc-devel
	$PACKAGE_INSTALLER jack-audio-connection-kit-devel
	$PACKAGE_INSTALLER ladspa-devel libaom-devel libdav1d-devel libbluray-devel libbs2b-devel libcaca-devel libcdio-paranoia-devel
	$PACKAGE_INSTALLER libchromaprint-devel libcrystalhd-devel lensfun-devel libavc1394-devel libdc1394-devel
	$PACKAGE_INSTALLER libiec61883-devel libdrm-devel libgcrypt-devel libGL-devel libmodplug-devel libmysofa-devel libopenmpt-devel
	$PACKAGE_INSTALLER librsvg2-devel libsmbclient-devel libssh-devel libtheora-devel libv4l-devel libva-devel libvdpau-devel
	$PACKAGE_INSTALLER libvorbis-devel
	$PACKAGE_INSTALLER vapoursynth-devel libvpx-devel libmfx
	$PACKAGE_INSTALLER mfx
	$PACKAGE_INSTALLER libmfx-devel
	$PACKAGE_INSTALLER mfx-devel
	$PACKAGE_INSTALLER nasm
	$PACKAGE_INSTALLER libwebp-devel netcdf-devel raspberrypi-vc-devel nv-codec-headers
	$PACKAGE_INSTALLER opencore-amr-devel vo-amrwbenc-devel
	$PACKAGE_INSTALLER libomxil-bellagio-devel
	$PACKAGE_INSTALLER libxcb-devel
	$PACKAGE_INSTALLER libxml2-devel
	$PACKAGE_INSTALLER lilv-devel lv2-devel
	$PACKAGE_INSTALLER openal-soft-devel
	$PACKAGE_INSTALLER opencl-headers ocl-icd-devel
	$PACKAGE_INSTALLER openjpeg2-devel
	$PACKAGE_INSTALLER pulseaudio-libs-devel
	$PACKAGE_INSTALLER podman
	$PACKAGE_INSTALLER rav1e-devel
	$PACKAGE_INSTALLER rubberband-devel
	$PACKAGE_INSTALLER SDL2-devel
	$PACKAGE_INSTALLER snappy-devel
	$PACKAGE_INSTALLER soxr-devel
	$PACKAGE_INSTALLER speex-devel
	$PACKAGE_INSTALLER srt-devel
	$PACKAGE_INSTALLER srt-libs
	$PACKAGE_INSTALLER srt-lib
	$PACKAGE_INSTALLER srt
	$PACKAGE_INSTALLER svt-av1-devel
	$PACKAGE_INSTALLER tesseract-devel
	$PACKAGE_INSTALLER texi2html
	$PACKAGE_INSTALLER texinfo
	$PACKAGE_INSTALLER twolame-devel
	$PACKAGE_INSTALLER libvmaf-devel
	$PACKAGE_INSTALLER wavpack-devel
	$PACKAGE_INSTALLER vid.stab-devel
	$PACKAGE_INSTALLER vulkan-loader-devel
	$PACKAGE_INSTALLER libshaderc-devel
	$PACKAGE_INSTALLER libshaderc
	$PACKAGE_INSTALLER spirv-tools-libs
	$PACKAGE_INSTALLER x264-devel
	$PACKAGE_INSTALLER x264-libs
	$PACKAGE_INSTALLER x264-lib
	$PACKAGE_INSTALLER libx264-devel
	$PACKAGE_INSTALLER x264
	$PACKAGE_INSTALLER x265-devel
	$PACKAGE_INSTALLER x265-libs
	$PACKAGE_INSTALLER x265-lib
	$PACKAGE_INSTALLER libx265-devel
	$PACKAGE_INSTALLER x265
	$PACKAGE_INSTALLER xvidcore-devel
	$PACKAGE_INSTALLER libxvidcore-devel
	$PACKAGE_INSTALLER xvid-devel
	$PACKAGE_INSTALLER libxvid-devel
	$PACKAGE_INSTALLER xvidcore
	$PACKAGE_INSTALLER xvid
	$PACKAGE_INSTALLER zimg-devel
	$PACKAGE_INSTALLER zlib-devel
	$PACKAGE_INSTALLER zeromq-devel
	$PACKAGE_INSTALLER zvbi-devel
	$PACKAGE_INSTALLER vmaf-models
	$PACKAGE_INSTALLER pkgconfig
	$PACKAGE_INSTALLER libunistring-devel
	$PACKAGE_INSTALLER unistring-devel
	$PACKAGE_INSTALLER libunistring
	$PACKAGE_INSTALLER unistring
	$PACKAGE_INSTALLER libxslt-devel
	$PACKAGE_INSTALLER GeoIP-devel
	$PACKAGE_INSTALLER tar
	$PACKAGE_INSTALLER unzip
	$PACKAGE_INSTALLER curl
	$PACKAGE_INSTALLER wget
	$PACKAGE_INSTALLER git
	$PACKAGE_INSTALLER libmaxminddb-devel
	$PACKAGE_INSTALLER libmcrypt-devel
	$PACKAGE_INSTALLER mcrypt-devel
	$PACKAGE_INSTALLER mcrypt
	$PACKAGE_INSTALLER libgeoip-devel
	$PACKAGE_INSTALLER geoip-devel
	$PACKAGE_INSTALLER podman
	$PACKAGE_INSTALLER bison
	$PACKAGE_INSTALLER boost-devel
	$PACKAGE_INSTALLER cmake
	$PACKAGE_INSTALLER libevent-devel
	$PACKAGE_INSTALLER flex
	$PACKAGE_INSTALLER cracklib-devel
	$PACKAGE_INSTALLER Judy-devel
	$PACKAGE_INSTALLER libaio-devel
	$PACKAGE_INSTALLER xz-devel
	$PACKAGE_INSTALLER lz4-devel
	$PACKAGE_INSTALLER lzo-devel
	$PACKAGE_INSTALLER libpmem-devel
	$PACKAGE_INSTALLER readline-devel
	$PACKAGE_INSTALLER policycoreutils-python
	$PACKAGE_INSTALLER libzstd-devel
	$PACKAGE_INSTALLER librabbitmq-devel
	$PACKAGE_INSTALLER libedit-devel
	$PACKAGE_INSTALLER scons
	$PACKAGE_INSTALLER check
	$PACKAGE_INSTALLER check-devel
	$PACKAGE_INSTALLER kernel-devel
	$PACKAGE_INSTALLER kernel-headers
	$PACKAGE_INSTALLER help2man
	$PACKAGE_INSTALLER gettext
	$PACKAGE_INSTALLER gettext-devel
	$PACKAGE_INSTALLER zlib-static
	$PACKAGE_INSTALLER sharutils
	$PACKAGE_INSTALLER libstdc++-static
	$PACKAGE_INSTALLER libstdc++-devel
	$PACKAGE_INSTALLER m4
	$PACKAGE_INSTALLER emacs
	$PACKAGE_INSTALLER perl-macros
	$PACKAGE_INSTALLER perl-podlators
	$PACKAGE_INSTALLER python-requests
	$PACKAGE_INSTALLER python2-requests
	$PACKAGE_INSTALLER python26-requests
	$PACKAGE_INSTALLER python3-requests
	$PACKAGE_INSTALLER binutils-devel
	$PACKAGE_INSTALLER libtirpc-devel
	$PACKAGE_INSTALLER tbb
	$PACKAGE_INSTALLER tbb-devel
	$PACKAGE_INSTALLER bsdtar
	$PACKAGE_INSTALLER libmicrohttpd-devel
	$PACKAGE_INSTALLER libmicrohttpd
	if [[ "$OS" = "CentOs" && "$VER" = "6" ]] ; then
	$PACKAGE_INSTALLER centos-release-scl
	$PACKAGE_INSTALLER centos-release-scl-rh
	$PACKAGE_INSTALLER devtoolset-9
	$PACKAGE_INSTALLER devtoolset-9-runtime
	$PACKAGE_INSTALLER devtoolset-9-annobin
	$PACKAGE_INSTALLER devtoolset-9-annobin-annocheck
	$PACKAGE_INSTALLER devtoolset-9-binutils
	$PACKAGE_INSTALLER devtoolset-9-binutils-devel
	$PACKAGE_INSTALLER devtoolset-9-dwz
	$PACKAGE_INSTALLER devtoolset-9-dyninst
	$PACKAGE_INSTALLER devtoolset-9-dyninst-devel
	$PACKAGE_INSTALLER devtoolset-9-dyninst-doc
	$PACKAGE_INSTALLER devtoolset-9-dyninst-static
	$PACKAGE_INSTALLER devtoolset-9-dyninst-testsuite
	$PACKAGE_INSTALLER devtoolset-9-elfutils
	$PACKAGE_INSTALLER devtoolset-9-elfutils-devel
	$PACKAGE_INSTALLER devtoolset-9-elfutils-libelf
	$PACKAGE_INSTALLER devtoolset-9-elfutils-libelf-devel
	$PACKAGE_INSTALLER devtoolset-9-elfutils-libs
	$PACKAGE_INSTALLER devtoolset-9-gcc
	$PACKAGE_INSTALLER devtoolset-9-gcc-c++
	$PACKAGE_INSTALLER devtoolset-9-gcc-gdb-plugin
	$PACKAGE_INSTALLER devtoolset-9-gcc-gfortran
	$PACKAGE_INSTALLER devtoolset-9-gcc-plugin-devel
	$PACKAGE_INSTALLER devtoolset-9-gdb
	$PACKAGE_INSTALLER devtoolset-9-gdb-doc
	$PACKAGE_INSTALLER devtoolset-9-gdb-gdbserver
	$PACKAGE_INSTALLER devtoolset-9-libasan-devel
	$PACKAGE_INSTALLER devtoolset-9-libatomic-devel
	$PACKAGE_INSTALLER devtoolset-9-libgccjit
	$PACKAGE_INSTALLER devtoolset-9-libgccjit-devel
	$PACKAGE_INSTALLER devtoolset-9-libgccjit-docs
	$PACKAGE_INSTALLER devtoolset-9-libitm-devel
	$PACKAGE_INSTALLER devtoolset-9-liblsan-devel
	$PACKAGE_INSTALLER devtoolset-9-libquadmath-devel
	$PACKAGE_INSTALLER devtoolset-9-libstdc++-devel
	$PACKAGE_INSTALLER devtoolset-9-libstdc++-docs
	$PACKAGE_INSTALLER devtoolset-9-libtsan-devel
	$PACKAGE_INSTALLER devtoolset-9-libubsan-devel
	$PACKAGE_INSTALLER devtoolset-9-ltrace
	$PACKAGE_INSTALLER devtoolset-9-make
	$PACKAGE_INSTALLER devtoolset-9-memstomp
	$PACKAGE_INSTALLER devtoolset-9-oprofile
	$PACKAGE_INSTALLER devtoolset-9-oprofile-devel
	$PACKAGE_INSTALLER devtoolset-9-oprofile-jit
	$PACKAGE_INSTALLER devtoolset-9-perftools
	$PACKAGE_INSTALLER devtoolset-9-strace
	$PACKAGE_INSTALLER devtoolset-9-systemtap
	$PACKAGE_INSTALLER devtoolset-9-systemtap-client
	$PACKAGE_INSTALLER devtoolset-9-systemtap-devel
	$PACKAGE_INSTALLER devtoolset-9-systemtap-initscript
	$PACKAGE_INSTALLER devtoolset-9-systemtap-runtime
	$PACKAGE_INSTALLER devtoolset-9-systemtap-sdt-devel
	$PACKAGE_INSTALLER devtoolset-9-systemtap-server
	$PACKAGE_INSTALLER devtoolset-9-systemtap-testsuite
	$PACKAGE_INSTALLER devtoolset-9-toolchain
	$PACKAGE_INSTALLER devtoolset-9-valgrind
	$PACKAGE_INSTALLER devtoolset-9-valgrind-devel
	$PACKAGE_INSTALLER devtoolset-9-build
	$PACKAGE_REMOVER devtoolset-9-build
	/opt/rh/devtoolset-9/enable
	source /opt/rh/devtoolset-9/enable
	fi
elif [[ "$OS" = "Ubuntu" ]]; then
	DEBIAN_FRONTEND=noninteractive
	export DEBIAN_FRONTEND=noninteractive
	# Update the enabled Aptitude repositories
	echo -ne "\nUpdating Aptitude Repos: " >/dev/tty
	mkdir -p "/etc/apt/sources.list.d.save"
	cp -R "/etc/apt/sources.list.d/*" "/etc/apt/sources.list.d.save" &> /dev/null
	rm -rf "/etc/apt/sources.list/*"
	cp "/etc/apt/sources.list" "/etc/apt/sources.list.save"
	cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main restricted universe multiverse 
deb-src http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted universe multiverse
deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner
deb-src http://archive.canonical.com/ubuntu $(lsb_release -sc) partner
EOF
	apt-get update
	apt-get -y --force-yes install software-properties-common --install-recommends
	apt-get -y --force-yes install python-software-properties --install-recommends
	apt-get -y --force-yes install dirmngr --install-recommends
	apt-get -y --force-yes install python-software-properties --install-recommends
	apt-get -y --force-yes install apt-apt-key
	apt-get -y --force-yes install apt-transport-https
	apt-get -y --force-yes install ca-certificates
  add-apt-repository -y ppa:ondrej/apache2
	add-apt-repository -y -s ppa:ondrej/php
	add-apt-repository -y ppa:maxmind/ppa
echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$VER /' | sudo tee /etc/apt/sources.list.d/podman.list
wget -qO- "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$VER/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/podman.gpg > /dev/null
	apt-get update
wget -qO- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF1656F24C74CD1D8" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/mariadb.gpg > /dev/null
	add-apt-repository -y "deb [arch=amd64,arm64,ppc64el] https://mirrors.nxthost.com/mariadb/repo/10.6/ubuntu/ $(lsb_release -cs) main"
	apt-get update
elif [[ "$OS" = "debian" ]]; then
	DEBIAN_FRONTEND=noninteractive
	export DEBIAN_FRONTEND=noninteractive
	# Update the enabled Aptitude repositories
	echo -ne "\nUpdating Aptitude Repos: " >/dev/tty
	apt-get update
	apt install curl wget apt-transport-https gnupg2 dirmngr -y
	mkdir -p "/etc/apt/sources.list.d.save"
	cp -R "/etc/apt/sources.list.d/*" "/etc/apt/sources.list.d.save" &> /dev/null
	rm -rf "/etc/apt/sources.list/*"
	cp "/etc/apt/sources.list" "/etc/apt/sources.list.save"
	cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian/ $(lsb_release -sc) main contrib non-free
deb-src http://deb.debian.org/debian/ $(lsb_release -sc) main contrib non-free
deb http://deb.debian.org/debian/ $(lsb_release -sc)-updates main contrib non-free
deb-src http://deb.debian.org/debian/ $(lsb_release -sc)-updates main contrib non-free
deb http://deb.debian.org/debian-security/ $(lsb_release -sc)/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ $(lsb_release -sc)/updates main contrib non-free
EOF
	apt-get update
	apt-get install software-properties-common dirmngr --install-recommends -y
	apt-get install apt-apt-key --install-recommends -y
  apt-get update
  wget -qO- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF1656F24C74CD1D8" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/mariadb.gpg > /dev/null
	add-apt-repository -y "deb [arch=amd64,arm64,ppc64el] https://mirrors.nxthost.com/mariadb/repo/10.6/debian/ $(lsb_release -cs) main"
	apt-get update
	apt-get -y install debhelper cdbs lintian build-essential fakeroot devscripts dh-make ca-certificates gpg reprepro
cat > /etc/apt/sources.list.d/php.list <<EOF
deb https://packages.sury.org/php/ $(lsb_release -sc) main
deb-src https://packages.sury.org/php/ $(lsb_release -sc) main
EOF
cat > /etc/apt/sources.list.d/apache2.list <<EOF
deb https://packages.sury.org/apache2/ $(lsb_release -sc) main
deb-src https://packages.sury.org/apache2/ $(lsb_release -sc) main
EOF
cat > /etc/apt/sources.list.d/podman.list <<EOF
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_$VER/ /
EOF
wget -qO- "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_$VER/Release.key" | sudo apt-key add -
	wget --no-check-certificate -qO- https://packages.sury.org/php/apt.gpg | apt-key add -
	wget --no-check-certificate -qO- https://packages.sury.org/apache2/apt.gpg | apt-key add -
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
	apt-get update
fi
if [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
	DEBIAN_FRONTEND=noninteractive
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get -y --force-yes dist-upgrade
	apt-get -y --force-yes install mariadb-server
	apt-get -y --force-yes install mariadb-common
	apt-get -y --force-yes install libmariadbclient-dev
	apt-get -y --force-yes install libmariadbclient18
	apt-get -y --force-yes install libmariadbd-dev
	apt-get -y --force-yes install libmysqlclient18
	apt-get -y --force-yes install mariadb-client
	apt-get -y --force-yes install mariadb-common
	apt-get -y --force-yes install mariadb-test
	apt-get -y --force-yes install mysql-common
	apt-get -y --force-yes install sqlite3-dev
	apt-get -y --force-yes install libsqlite3-dev
	apt-get -y --force-yes install oniguruma
	apt-get -y --force-yes install oniguruma-dev
	apt-get -y --force-yes install liboniguruma
	apt-get -y --force-yes install liboniguruma-dev
	apt-get -y --force-yes install libonig-dev
	apt-get -y --force-yes install apache2-dev
	apt-get -y --force-yes install apache2-threaded-dev
	apt-get -y --force-yes install libaprutil1-dev
	apt-get -y --force-yes install bison
	apt-get -y --force-yes install chrpath
	apt-get -y --force-yes install default-libmysqlclient-dev
	apt-get -y --force-yes install libmysqlclient-dev
	apt-get -y --force-yes install dh-apache2
	apt-get -y --force-yes install dpkg-dev
	apt-get -y --force-yes install firebird-dev
	apt-get -y --force-yes install firebird1.5-dev
	apt-get -y --force-yes install firebird1.6-dev
	apt-get -y --force-yes install firebird1.7-dev
	apt-get -y --force-yes install firebird1.8-dev
	apt-get -y --force-yes install firebird1.9-dev
	apt-get -y --force-yes install firebird2.0-dev
	apt-get -y --force-yes install firebird2.1-dev
	apt-get -y --force-yes install firebird2.2-dev
	apt-get -y --force-yes install firebird2.3-dev
	apt-get -y --force-yes install firebird2.4-dev
	apt-get -y --force-yes install firebird2.5-dev
	apt-get -y --force-yes install flex
	apt-get -y --force-yes install freetds-dev
	apt-get -y --force-yes install libacl1-dev
	apt-get -y --force-yes install libapparmor-dev
	apt-get -y --force-yes install libapr1-dev
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install 
	apt-get -y --force-yes install debhelper
	apt-get -y --force-yes install cdbs
	apt-get -y --force-yes install lintian
	apt-get -y --force-yes install build-essential
	apt-get -y --force-yes install fakeroot
	apt-get -y --force-yes install devscripts
	apt-get -y --force-yes install dh-make
	apt-get -y --force-yes install curl
	apt-get -y --force-yes install libxslt1-dev
	apt-get -y --force-yes install libcurl3-gnutls
	apt-get -y --force-yes install libgeoip-dev
	apt-get -y --force-yes install python
	apt-get -y --force-yes install python2
	apt-get -y --force-yes install python33
	apt-get -y --force-yes install e2fsprogs
	apt-get -y --force-yes install wget
	apt-get -y --force-yes install mcrypt
	apt-get -y --force-yes install nscd
	apt-get -y --force-yes install htop
	apt-get -y --force-yes install zip
	apt-get -y --force-yes install unzip
	apt-get -y --force-yes install mc
	apt-get -y --force-yes install python3-paramiko
	apt-get -y --force-yes install python-paramiko
	apt-get -y --force-yes install python2-paramiko
	apt-get -y --force-yes install python-pip
	apt-get -y --force-yes install python2-pip
	apt-get -y --force-yes install python3-pip
	apt-get -y --force-yes dist-upgrade
	apt-get -y --force-yes install debhelper
	apt-get -y --force-yes install cdbs
	apt-get -y --force-yes install lintian
	apt-get -y --force-yes install build-essential
	apt-get -y --force-yes install fakeroot
	apt-get -y --force-yes install devscripts
	apt-get -y --force-yes install dh-make
	apt-get -y --force-yes install wget
	apt-get -y --force-yes build-dep php7.4
	apt-get -y --force-yes install libmariadb-dev
	apt-get -y --force-yes install libmariadb-dev-compat
	apt-get -y --force-yes install libmariadbd-dev
	apt-get -y --force-yes install dbconfig-mysql
	apt-get -y --force-yes install autoconf
	apt-get -y --force-yes install automake
	apt-get -y --force-yes install build-essential
	apt-get -y --force-yes install cmake
	apt-get -y --force-yesinstall git-core
	apt-get -y --force-yes install git
	apt-get -y --force-yes install libass-dev
	apt-get -y --force-yes install libfreetype6-dev
	aapt-get -y --force-yes install libgnutls28-dev
	apt-get -y --force-yes install libmp3lame-dev
	apt-get -y --force-yes install libsdl2-dev
	apt-get -y --force-yes install libtool
	apt-get -y --force-yes install libva-dev
	apt-get -y --force-yes install libvdpau-dev
	apt-get -y --force-yes install libvorbis-dev
	apt-get -y --force-yes install libxcb1-dev
	apt-get -y --force-yes install libxcb-shm0-dev
	apt-get -y --force-yes install libxcb-xfixes0-dev
	apt-get -y --force-yes install meson
	apt-get -y --force-yes install ninja-build
	apt-get -y --force-yes install pkg-config
	apt-get -y --force-yes install texinfo
	apt-get -y --force-yes install yasm
	apt-get -y --force-yes install zlib1g-dev
	apt-get -y --force-yes install libxvidcore-dev
	apt-get -y --force-yes install libunistring-dev
	apt-get -y --force-yes install nasm
	aapt-get -y --force-yes install libx264-dev
	apt-get -y --force-yes install libx265-dev
	apt-get -y --force-yes install libnuma-dev
	apt-get -y --force-yes install libvpx-dev
	apt-get -y --force-yes install libfdk-aac-dev
	apt-get -y --force-yes install libopus-dev
	apt-get -y --force-yes install unzip
	apt-get -y --force-yes install librtmp-dev
	apt-get -y --force-yes install libtheora-dev
	aapt-get -y --force-yes install libbz2-dev
	apt-get -y --force-yes install libgmp-dev
	apt-get -y --force-yes install libssl-dev
	apt-get -y --force-yes install zip
	apt-get -y --force-yes install libdav1d-dev
	apt-get -y --force-yes install libaom-dev
	apt-get -y --force-yes install reprepro
	apt-get -y --force-yes install subversion
	apt-get -y --force-yes install zstd
	apt-get -y --force-yes install libpcre3
	apt-get -y --force-yes install libpcre3-dev
	apt-get -y --force-yesapt-get -y install pcre3
	apt-get -y --force-yes install libpcre
	apt-get -y --force-yes install libpcre-dev
	apt-get -y --force-yes install pcre
	apt-get -y --force-yes install libpcre2
	apt-get -y --force-yes install libpcre2-dev
	apt-get -y --force-yes install pcre2
	apt-get -y --force-yes install libgd-dev
	apt-get -y --force-yes install libxslt-dev
	apt-get -y --force-yes install libgeoip-dev
	apt-get -y --force-yes install tar
	apt-get -y --force-yes install curl
	apt-get -y --force-yes install wget
	apt-get -y --force-yes install git
	apt-get -y --force-yes install libmaxminddb-dev
	apt-get -y --force-yes install libmcrypt-dev
	apt-get -y --force-yes install mcrypt-dev
	apt-get -y --force-yes install libmcrypt-devel
	apt-get -y --force-yes install mcrypt-devel
	apt-get -y --force-yes install mcrypt
	apt-get -y --force-yes install libgeoip-dev
	apt-get -y --force-yes install libgeoip-devel
	apt-get -y --force-yes install geoip-devel
	apt-get -y --force-yes install podman
	apt-get update
	apt-get -y install python-software-properties
	apt-get -y install software-properties-common wget gnupg gnupg2
	add-apt-repository -y -s ppa:andykimpe/curl
	add-apt-repository -y -s  ppa:ondrej/apache2
	add-apt-repository -y -s  ppa:ondrej/php
	apt-get update
	apt-get -y dist-upgrade
	apt-get -y install apache2 libapache2-mod-fcgid apache2-bin apache2-data apache2-utils php-pear
	apt-get -y install libapache2-mod-php php php-common php-fpm php-cli php-mysql php-gd php-mcrypt php-curl php-imap php-xmlrpc php-intl php-dev php-mbstring
	apt-get -y install libapache2-mod-php5.6 php5.6 php5.6-common php5.6-fpm php5.6-cli php5.6-mysql php5.6-gd php5.6-mcrypt php5.6-curl php5.6-imap php5.6-xmlrpc php5.6-xsl php5.6-intl php5.6-dev php5.6-mbstring
	apt-get -y install libapache2-mod-php7.0 php7.0 php7.0-common php7.0-fpm php7.0-cli php7.0-mysql php7.0-gd php7.0-mcrypt php7.0-curl php7.0-imap php7.0-xmlrpc php7.0-xsl php7.0-intl php7.0-dev php7.0-mbstring
	apt-get -y install libapache2-mod-php7.1 php7.1 php7.1-common php7.1-fpm php7.1-cli php7.1-mysql php7.1-gd php7.1-mcrypt php7.1-curl php7.1-imap php7.1-xmlrpc php7.1-xsl php7.1-intl php7.1-dev php7.1-mbstring
	apt-get -y install libapache2-mod-php7.2 php7.2 php7.2-common php7.2-fpm php7.2-cli php7.2-mysql php7.2-gd php7.2-mcrypt php7.2-curl php7.2-imap php7.2-xmlrpc php7.2-xsl php7.2-intl php7.2-dev php7.2-mbstring
	apt-get -y install libapache2-mod-php7.3 php7.3 php7.3-common php7.3-fpm php7.3-cli php7.3-mysql php7.3-gd php7.3-mcrypt php7.3-curl php7.3-imap php7.3-xmlrpc php7.3-xsl php7.3-intl php7.3-dev php7.3-mbstring
	apt-get -y install libapache2-mod-php7.4 php7.4 php7.4-common php7.4-fpm php7.4-cli php7.4-mysql php7.4-gd php7.4-mcrypt php7.4-curl php7.4-imap php7.4-xmlrpc php7.4-xsl php7.4-intl php7.4-dev php7.4-mbstring
	apt-get -y install libapache2-mod-php8.0 php8.0 php8.0-common php8.0-fpm php8.0-cli php8.0-mysql php8.0-gd php8.0-mcrypt php8.0-curl php8.0-imap php8.0-xmlrpc php8.0-xsl php8.0-intl php8.0-dev php8.0-mbstring
	apt-get -y install libapache2-mod-php8.1 php8.1 php8.1-common php8.1-fpm php8.1-cli php8.1-mysql php8.1-gd php8.1-mcrypt php8.1-curl php8.1-imap php8.1-xmlrpc php8.1-xsl php8.1-intl php8.1-dev php8.1-mbstring
	apt-get -y install libapache2-mod-php8.2 php8.2 php8.2-common php8.2-fpm php8.2-cli php8.2-mysql php8.2-gd php8.2-mcrypt php8.2-curl php8.2-imap php8.2-xmlrpc php8.2-xsl php8.2-intl php8.2-dev php8.2-mbstring
	update-alternatives --set php /usr/bin/php7.4
	update-alternatives --set phar /usr/bin/phar7.4
	update-alternatives --set phar.phar /usr/bin/phar.phar7.4
	update-alternatives --set phpize /usr/bin/phpize7.4
	update-alternatives --set php-config /usr/bin/php-config7.4
	update-alternatives --remove-all php-fpm
	rm -f /usr/sbin/php-fpm
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm5.6 100
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm7.0 90
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm7.1 80
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm7.2 70
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm7.3 60
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm7.4 50
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm8.0 40
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm8.1 30
	update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm8.2 20
	update-alternatives --set php-fpm /usr/sbin/php-fpm7.4
	a2dismod php5.6
	a2dismod php7.0
	a2dismod php7.1
	a2dismod php7.2
	a2dismod php7.3
	a2dismod php7.4
	a2dismod php8.0
	a2dismod php8.1
	a2dismod php8.2
	a2enmod php7.4
	phpenmod -v 5.6 mcrypt
	phpenmod -v 5.6 mbstring
	phpenmod -v 7.0 mcrypt
	phpenmod -v 7.0 mbstring
	phpenmod -v 7.1 mcrypt
	phpenmod -v 7.1 mbstring
	phpenmod -v 7.2 mcrypt
	phpenmod -v 7.2 mbstring
	phpenmod -v 7.3 mcrypt
	phpenmod -v 7.3 mbstring
	phpenmod -v 7.4 mcrypt
	phpenmod -v 7.4 mbstring
	phpenmod -v 8.0 mcrypt
	phpenmod -v 8.0 mbstring
	phpenmod -v 8.1 mcrypt
	phpenmod -v 8.1 mbstring
	phpenmod -v 8.2 mcrypt
	phpenmod -v 8.2 mbstring
	a2enmod rewrite
	a2disconf php5.6-fpm
	a2disconf php7.0-fpm
	a2disconf php7.1-fpm
	a2disconf php7.2-fpm
	a2disconf php7.3-fpm
	a2disconf php7.4-fpm
	a2disconf php8.0-fpm
	a2disconf php8.1-fpm
	a2disconf php8.2-fpm
	systemctl stop php5.6-fpm
	systemctl disable php5.6-fpm
	systemctl stop php7.0-fpm
	systemctl disable php7.0-fpm
	systemctl stop php7.1-fpm
	systemctl disable php7.1-fpm
	systemctl stop php7.2-fpm
	systemctl disable php7.2-fpm
	systemctl stop php7.3-fpm
	systemctl disable php7.3-fpm
	systemctl stop php7.4-fpm
	systemctl disable php7.4-fpm
	systemctl stop php8.0-fpm
	systemctl disable php8.0-fpm
	systemctl stop php8.1-fpm
	systemctl disable php8.1-fpm
	systemctl stop php8.2-fpm
	systemctl disable php8.2-fpm
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/apache2.conf -O /etc/apache2/apache2.conf
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/ports.conf -O /etc/apache2/ports.conf
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/000-default.conf -O /etc/apache2/sites-available/000-default.conf
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/default-ssl.conf -O /etc/apache2/sites-available/default-ssl.conf
	wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
	tar -xzf ioncube_loaders_lin_x86-64.tar.gz -C /usr/local && rm -f ioncube_loaders_lin_x86-64.tar.gz
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/5.6/php.ini -O /etc/php/5.6/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/5.6/php.ini -O /etc/php/5.6/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/5.6/php.ini -O /etc/php/5.6/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.0/php.ini -O /etc/php/7.0/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.0/php.ini -O /etc/php/7.0/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.0/php.ini -O /etc/php/7.0/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.1/php.ini -O /etc/php/7.1/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.1/php.ini -O /etc/php/7.1/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.1/php.ini -O /etc/php/7.1/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.2/php.ini -O /etc/php/7.2/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.2/php.ini -O /etc/php/7.2/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.2/php.ini -O /etc/php/7.2/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.3/php.ini -O /etc/php/7.3/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.3/php.ini -O /etc/php/7.3/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.3/php.ini -O /etc/php/7.3/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.4/php.ini -O /etc/php/7.4/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.4/php.ini -O /etc/php/7.4/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/7.4/php.ini -O /etc/php/7.4/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.0/php.ini -O /etc/php/8.0/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.0/php.ini -O /etc/php/8.0/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.0/php.ini -O /etc/php/8.0/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.1/php.ini -O /etc/php/8.1/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.1/php.ini -O /etc/php/8.1/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.1/php.ini -O /etc/php/8.1/fpm/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.2/php.ini -O /etc/php/8.2/apache2/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.2/php.ini -O /etc/php/8.2/cli/php.ini
	wget https://raw.githubusercontent.com/amidevous/ubuntu-apache-install/master/8.2/php.ini -O /etc/php/8.2/fpm/php.ini
	systemctl restart apache2
	apt-get -y install phpmyadmin
	dpkg-reconfigure phpmyadmin
 	add-apt-repository ppa:ubuntuhandbook1/vlc -y
   	apt-get update
   	apt-get install vlc screen -y
   	sed -i 's/geteuid/getppid/' /usr/bin/vlc
   	sed -i 's/geteuid/getppid/' /usr/bin/cvlc
 	cd /usr/share
    	rm -rf phpmyadmin
 	wget https://files.phpmyadmin.net/phpMyAdmin/4.9.11/phpMyAdmin-4.9.11-all-languages.tar.xz
  	tar -xvf phpMyAdmin-4.9.11-all-languages.tar.xz
   	rm -rf phpMyAdmin-4.9.11-all-languages.tar.xz
    	mv phpMyAdmin-4.9.11-all-languages phpmyadmin  
	apt-get -y purge postfix
	debconf-set-selections <<< "postfix postfix/mailname string redhat"
	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
	rm -rf /etc/aliases /etc/postfix
	DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install postfix
	rm -rf /var/lib/dpkg/info/postfix.postinst
	dpkg --configure postfix
	dpkg-reconfigure postfix
	apt-get install -yf --force-yes

	
fi
if [[ "$OS" = "CentOs" && "$VER" = "6" ]] ; then
yum -y install tcl-devel
rpm -i https://vault.centos.org/centos/7/os/Source/SPackages/sqlite-3.7.17-8.el7_7.1.src.rpm
wget -O $(rpm --eval %{_topdir})/SPECS/sqlite.spec https://raw.githubusercontent.com/amidevous/xtream-ui-ubuntu20.04/master/centos/6/sqlite.spec
rpmbuild -ba $(rpm --eval %{_topdir})/SPECS/sqlite.spec
yum -y install $(rpm --eval %{_topdir})/RPMS/sqlite-3.7.17-8.el6.1.x86_64.rpm $(rpm --eval %{_topdir})/RPMS/sqlite-devel-3.7.17-8.el6.1.x86_64.rpm $(rpm --eval %{_topdir})/RPMS/sqlite-doc-3.7.17-8.el6.1.noarch.rpm $(rpm --eval %{_topdir})/RPMS/lemon-3.7.17-8.el6.1.x86_64.rpm $(rpm --eval %{_topdir})/RPMS/sqlite-tcl-3.7.17-8.el6.1.x86_64.rpm
yum -y install $(rpm --eval %{_topdir})/RPMS/x86_64/sqlite-3.7.17-8.el6.1.x86_64.rpm $(rpm --eval %{_topdir})/RPMS/x86_64/sqlite-devel-3.7.17-8.el6.1.x86_64.rpm $(rpm --eval %{_topdir})/RPMS/noarch/sqlite-doc-3.7.17-8.el6.1.noarch.rpm $(rpm --eval %{_topdir})/RPMS/x86_64/lemon-3.7.17-8.el6.1.x86_64.rpm $(rpm --eval %{_topdir})/RPMS/x86_64/sqlite-tcl-3.7.17-8.el6.1.x86_64.rpm
yum -y remove oniguruma-devel
yum -y install oniguruma5php-devel

rpm -i https://vault.centos.org/centos/7/os/Source/SPackages/autoconf-2.69-11.el7.src.rpm
wget -O $(rpm --eval %{_topdir})/SPECS/autoconf.spec https://raw.githubusercontent.com/amidevous/xtream-ui-ubuntu20.04/master/centos/6/autoconf.spec
rpmbuild -ba $(rpm --eval %{_topdir})/SPECS/autoconf.spec
yum -y install $(rpm --eval %{_topdir})/RPMS/autoconf-2.69-11.el6.noarch.rpm
yum -y install $(rpm --eval %{_topdir})/RPMS/noarch/autoconf-2.69-11.el6.noarch.rpm

fi
	systemctl start mariadb
	systemctl enable mariadb
	service start mariadb
	update-rc.d mariadb defaults
	chkconfig mariadb on

