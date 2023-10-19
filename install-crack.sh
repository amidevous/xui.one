#!/bin/bash
[ ! -f "/etc/systemd/system/xuione.service" ] && echo "XUI.one isn't installed!" && exit
[ ! -d "/home/xui/config" ] && echo "XUI.one isn't installed!" && exit
echo "XUI.one Crack"
echo "-------------"
echo "All Versions"
echo "By sysnull84"
echo "-------------
"
echo "Stopping XUI.one
"
sudo systemctl stop xuione
echo "Installing cracked license
"
cp -r license /home/xui/config/license
cp -r xui.so /home/xui/bin/php/lib/php/extensions/no-debug-non-zts-20190902/xui.so
echo "Update configuration file
"
sed -i "s/^license.*/license     =   \"cracked\"/g" /home/xui/config/config.ini
echo "Starting XUI.one
"
sudo systemctl start xuione
echo "Cracked! ;)
"
