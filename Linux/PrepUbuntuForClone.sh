#!/bin/bash

#stop logging services
/sbin/service rsyslog stop
/sbin/service auditd stop
#remove old kernels
/bin/package-cleanup –oldkernels –count=1
#get latest updates and clean
sudo apt update
sudo apt install open-vm-tools -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean 
#force logrotate to shrink logspace and remove old logs as well as truncate logs
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz
/bin/rm -f /var/log/dmesg.old
/bin/rm -rf /var/log/anaconda
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/grubby
#remove udev hardware rules
/bin/rm -f /etc/udev/rules.d/70*
#remove uuid from ifcfg scripts
#/bin/sed –i”.bak” ‘/UUID/d’ /etc/sysconfig/network-scripts/ifcfg-eno16777984
/bin/sed -i".bak" '/UUID/d' /etc/sysconfig/network-scripts/ifcfg*
#remove SSH host keys
/bin/rm -f /etc/ssh/*key*
#remove root users shell history
/bin/rm -f ~root/.bash_history
unset HISTFILE
#remove root users SSH history
/bin/rm -rf ~root/.ssh/
#reset the machine id
echo "" | sudo tee /etc/machine-id >/dev/null
# cleanup shell history and shutdown for templating
history -c
history -w
sudo shutdown -h now


