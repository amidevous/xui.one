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
    VERFULL="$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)"
    VER="${VERFULL:0:1}" # return 6, 7 or 8
elif [ -f /etc/fedora-release ]; then
    inst() {
       rpm -q "$1" &> /dev/null
    } 
    OS="Fedora"
    VERFULL="$(sed 's/^.*release //;s/ (Fin.*$//' /etc/fedora-release)"
    VER="${VERFULL:0:2}" # return 34, 35 or 36
elif [ -f /etc/lsb-release ]; then
    OS="$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')"
    VER="$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')"
elif [ -f /etc/os-release ]; then
    OS="$(grep -w ID /etc/os-release | sed 's/^.*=//')"
    VER="$(grep -w VERSION_ID /etc/os-release | sed 's/^.*=//')"
 else
    OS="$(uname -s)"
    VER="$(uname -r)"
fi
ARCH=$(uname -m)
echo "Detected : $OS  $VER  $ARCH"
if [[ "$OS" = "Ubuntu" && ( "$VER" = "20.04" || "$VER" = "22.04" || "$VER" = "24.04" ) && "$ARCH" == "x86_64" ]] ; then
echo "Ok."
else
    echo "Sorry, this OS is not supported by Xtream UI use online Ubuntu LTS Version."
    echo "Use online actual Ubuntu LTS Version 20.04 22.04 or 24.04."
    exit 1
fi
sudo DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python python-dev unzip >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python2 python2-dev unzip >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python2.7 python2.7-dev unzip >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python2.8 python2.8-dev unzip >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3 python3-dev unzip >/dev/null 2>&1
cd /root
wget https://github.com/amidevous/xui.one/releases/download/test/XUI_1.5.12.zip -O XUI_1.5.12.zip >/dev/null 2>&1
unzip XUI_1.5.12.zip >/dev/null 2>&1
wget https://raw.githubusercontent.com/amidevous/xui.one/master/install.python3 -O /root/install.python3 >/dev/null 2>&1
python3 /root/install.python3
