#!/bin/bash

# Carbonara, a CIS HARDening script for Ubuntu 18.04
#
# Carbonara not because diamonds are harrrrrdest thing known to man...
# Carbonara not because diamonds are the purest, densest carbon...
#
# Carbonara because this script resembles spaghetti, spaghetti carbonara, junk food made from over-burned bacon and powdered eggs...
#
# basically it's a butchered JShielder (from Jason Soto) tweaked for my own needs...
# 

source helpers.sh

##############################################################################################################

f_banner(){
echo
echo "
==================================================
=----------------- CARBONARA --------------------=
=--- butchered jshielder, for superlazy roots ---=
=------------------------------------------------=
=  Carbonara, not because diamonds, the hardest  =
=   thing known to man are made of pure carbon   =
=------------------------------------------------=
=    Carbonara because it resembles Spaghetti,   =
=    Spaghetti Carbonara, junk food made from    =
=     over-burned bacon and powdered eggs...     =
==================================================
"
echo
echo

}


##############################################################################################################

# Check if running with root User

clear
f_banner


check_root() {
if [ $EUID -ne 0 ]; then
      echo "Can only be run by root"
      exit
else
      clear
      f_banner
      cat templates/texts/welcome-CIS
fi
}

##############################################################################################################

check_root
say_continue

echo -e ""
echo -e "Disabling unused filesystems"
spinner
sleep 2

echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install hfs /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install hfsplus /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install vfat /bin/true" >> /etc/modprobe.d/CIS.conf


clear
f_banner

echo -e ""
echo -e "Setting Sticky bit on all world-writable directories"
sleep 2
spinner

df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t


clear
f_banner
echo -e ""
echo -e "Installing and configuring AIDE"

apt-get install aide -y
aideinit

clear
f_banner

echo -e ""
echo -e "Securing Boot Settings"
spinner
sleep 2

chown root:root /boot/grub/grub.cfg
chmod og-rwx /boot/grub/grub.cfg


echo "* hard core 0" >> /etc/security/limits.conf
cp templates/sysctl-CIS.conf /etc/sysctl.conf
sysctl -e -p


cat templates/motd-CIS > /etc/motd
cat templates/motd-CIS > /etc/issue
cat templates/motd-CIS > /etc/issue.net


chown root:root /etc/motd /etc/issue /etc/issue.net
chmod 644 /etc/motd /etc/issue /etc/issue.net

apt-get update
apt-get -y upgrade

apt-get remove telnet -y

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub
update-grub

clear
f_banner

echo -e ""
echo -e "Setting hosts.allow and hosts.deny"
spinner
sleep 2

echo "ALL: 10.0.0.0/255.0.0.0" >> /etc/hosts.allow
echo "ALL: 192.168.0.0/255.255.0.0" >> /etc/hosts.allow
echo "ALL: 172.16.0.0/255.240.0.0" >> /etc/hosts.allow

echo "ALL: ALL" >> /etc/hosts.deny

chown root:root /etc/hosts.allow
chmod 644 /etc/hosts.allow

chown root:root /etc/hosts.deny
chmod 644 /etc/hosts.deny

clear
f_banner

echo -e ""
echo -e "Disabling uncommon Network Protocols"
spinner
sleep 2

echo "install dccp /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install sctp /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install rds /bin/true" >> /etc/modprobe.d/CIS.conf

echo "install tipc /bin/true" >> /etc/modprobe.d/CIS.conf

clear
f_banner

echo -e ""
echo -e "Setting up Iptables Rules"
spinner
sleep 1

sh templates/iptables-CIS.sh
cp templates/iptables-CIS.sh /etc/init.d/
chmod +x /etc/init.d/iptables-CIS.sh
ln -s /etc/init.d/iptables-CIS.sh /etc/rc2.d/S99iptables-CIS.sh

clear
f_banner
echo -e ""
echo -e "Installing and configuring Auditd"

spinner
sleep 1

apt-get install auditd -y

cp templates/auditd-CIS.conf /etc/audit/auditd.conf

systemctl enable auditd

sed -i 's/GRUB_CMDLINE_LINUX="ipv6.disable=1"/GRUB_CMDLINE_LINUX="ipv6.disable=1\ audit=1"/g' /etc/default/grub

cp templates/audit-CIS.rules /etc/audit/audit.rules

find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print \
"-a always,exit -F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 \
-k privileged" } ' >> /etc/audit/audit.rules

echo " " >> /etc/audit/audit.rules
echo "#End of Audit Rules" >> /etc/audit/audit.rules
echo "-e 2" >>/etc/audit/audit.rules

cp /etc/audit/audit.rules /etc/audit/rules.d/audit.rules

chmod -R g-wx,o-rwx /var/log/*

chown root:root /etc/cron*
chmod og-rwx /etc/cron*

touch /etc/cron.allow
touch /etc/at.allow

chmod og-rwx /etc/cron.allow /etc/at.allow
chown root:root /etc/cron.allow /etc/at.allow

echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m We will now Create a New User for SSH Access"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo -n " Type the new username: "; read username
adduser $username

echo -n " Securing SSH..."
sed s/USERNAME/$username/g templates/sshd_config-CIS > /etc/ssh/sshd_config; echo "OK"

runuser -u $username -- ssh-keygen -t rsa -f /home/$username/.ssh/id_rsa -q -P ""
runuser -u $username -- touch /home/$username/.ssh/authorized_keys
chmod 600 /home/$username/.ssh/authorized_keys
cat /root/.ssh/authorized_keys > /home/$username/.ssh/authorized_keys

service sshd restart

chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config

clear
f_banner

echo -e ""
echo -e "Configuring PAM"
spinner
sleep 2

cp templates/common-passwd-CIS /etc/pam.d/common-passwd
cp templates/pwquality-CIS.conf /etc/security/pwquality.conf
cp templates/common-auth-CIS /etc/pam.d/common-auth

cp templates/login.defs-CIS /etc/login.defs

useradd -D -f 30

for user in `awk -F: '($3 < 1000) {print $1 }' /etc/passwd`; do
  if [ $user != "root" ]; then
    usermod -L $user
  if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
    usermod -s /usr/sbin/nologin $user
  fi
  fi
done

usermod -g 0 root

sed -i s/umask\ 022/umask\ 027/g /etc/init.d/rc

clear
f_banner
echo -e ""
echo -e "Setting System File Permissions"
spinner
sleep 2

chown root:root /etc/passwd
chmod 644 /etc/passwd

chown root:shadow /etc/shadow
chmod o-rwx,g-wx /etc/shadow

chown root:root /etc/group
chmod 644 /etc/group

chown root:shadow /etc/gshadow
chmod o-rwx,g-rw /etc/gshadow

chown root:root /etc/passwd-
chmod 600 /etc/passwd-

chown root:root /etc/shadow-
chmod 600 /etc/shadow-

chown root:root /etc/group-
chmod 600 /etc/group-

chown root:root /etc/gshadow-
chmod 600 /etc/gshadow-

read ip < <(last -i | grep -o '[0-9]\+[.][0-9]\+[.][0-9]\+[.][0-9]\+')
echo $ip >> /etc/hosts.allow
service sshd restart

clear
f_banner

cat templates/texts/bye-CIS
say_continue

reboot
