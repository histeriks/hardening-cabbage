#!/bin/bash

source helpers.sh

##############################################################################################################

f_banner(){
echo
echo "
================================================================
======================= CABBAGE v1.0 ===========================
=  originally jshielder, butchered & reassembled by histerix   =
=  promoting dark art of server maintenance through lazyness!  =
=    use it for CIS compliant hardening of Ubuntu & Debian     =
=    without moving your pinky! Don't work hard, work smart!   =
================================================================
================================================================
"
echo
echo

}

clear

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

check_root
say_continue

echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install hfs /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install hfsplus /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install vfat /bin/true" >> /etc/modprobe.d/CIS.conf

clear

df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

clear

echo -e "Installing and configuring AIDE"

apt-get install aide -y
aideinit

clear

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

echo "ALL: 10.0.0.0/255.0.0.0" >> /etc/hosts.allow
echo "ALL: 192.168.0.0/255.255.0.0" >> /etc/hosts.allow
echo "ALL: 172.16.0.0/255.240.0.0" >> /etc/hosts.allow

echo "ALL: ALL" >> /etc/hosts.deny

chown root:root /etc/hosts.allow
chmod 644 /etc/hosts.allow

chown root:root /etc/hosts.deny
chmod 644 /etc/hosts.deny

clear

echo "install dccp /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install sctp /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install rds /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install tipc /bin/true" >> /etc/modprobe.d/CIS.conf

clear

echo -e ""
echo -e "Setting up iptables"


sh templates/iptables-CIS.sh
cp templates/iptables-CIS.sh /etc/init.d/
chmod +x /etc/init.d/iptables-CIS.sh
ln -s /etc/init.d/iptables-CIS.sh /etc/rc2.d/S99iptables-CIS.sh

clear

echo -e "Installing and configuring Auditd"

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

echo -n "Type the new administrative user's username: "; read username
adduser $username

echo -n "Securing SSH..."
sed s/USERNAME/$username/g templates/sshd_config-CIS > /etc/ssh/sshd_config; echo "OK"

runuser -u $username -- ssh-keygen -t rsa -f /home/$username/.ssh/id_rsa -q -P ""
runuser -u $username -- touch /home/$username/.ssh/authorized_keys
chmod 600 /home/$username/.ssh/authorized_keys
cat /root/.ssh/authorized_keys > /home/$username/.ssh/authorized_keys
clear
service sshd restart

chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config

clear

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

read ip < <(last -i root | grep -o '[0-9]\+[.][0-9]\+[.][0-9]\+[.][0-9]\+') && echo ALL: $ip >> /etc/hosts.allow
usermod -aG sudo $username
echo $username "ALL=(ALL:ALL) ALL" >> /etc/sudoers
service sshd restart
clear
echo -n "Do you have a separate /tmp partition? (y/n): "; read tmp_answer
if [ "$tmp_answer" == "n" ]; then
echo "We will create a FileSystem for the /tmp Directory and set Proper Permissions "
spinner
dd if=/dev/zero of=/usr/tmpDISK bs=1024 count=2048000
mkdir /tmpbackup
cp -Rpf /tmp /tmpbackup
mount -t tmpfs -o loop,noexec,nosuid,rw /usr/tmpDISK /tmp
chmod 1777 /tmp
cp -Rpf /tmpbackup/* /tmp/
rm -rf /tmpbackup
echo "/usr/tmpDISK  /tmp    tmpfs   loop,nosuid,nodev,noexec,rw  0 0" >> /etc/fstab
sudo mount -o remount /tmp

else

fi

apt install sendmail -y
apt install fail2ban -y

sed s/MAILTO/$inbox/g templates/fail2ban > /etc/fail2ban/jail.local
cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf
/etc/init.d/fail2ban restart

echo "* hard core 0" >> /etc/security/limits.conf
cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
cp templates/ufw /etc/default/ufw
sysctl -e -p

cd rkhunter-1.4.6/
sh installer.sh --layout /usr --install
cd ..
rkhunter --update
rkhunter --propupd

cp templates/bashrc-root /root/.bashrc
cp templates/bashrc-user /home/$username/.bashrc
chown $username:$username /home/$username/.bashrc
    
job="@daily apt update; apt dist-upgrade -y"
touch job
echo $job >> job
crontab job
rm job
    
apt install portsentry -y
mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf-original
cp templates/portsentry /etc/portsentry/portsentry.conf
sed s/tcp/atcp/g /etc/default/portsentry > salida.tmp
mv salida.tmp /etc/default/portsentry
/etc/init.d/portsentry restart

git clone https://github.com/BinaryDefense/artillery
cd artillery/
python setup.py
cd ..

for port in 22 372 1433 8080 21 5900 53 110 1723 1337 10000 5800 44443 16993; do
echo "iptables -A INPUT -p tcp -m tcp --dport $port -j ACCEPT" >> /etc/init.d/iptables.sh
done

echo tty1 > /etc/securetty
chmod 0600 /etc/securetty
chmod 700 /root
chmod 600 /boot/grub/grub.cfg
apt purge at
apt install -y libpam-cracklib

touch /etc/cron.allow
chmod 600 /etc/cron.allow
awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny

echo "blacklist usb-storage" | sudo tee -a /etc/modprobe.d/blacklist.conf
update-initramfs -u

apt -y install unhide
apt -y install tiger
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG

clear
f_banner

echo -n " Do you want to install PSAD (Recommended)? (y/n): " ; read psad_answer
if [ "$psad_answer" == "y" ]; then
echo -n " Type an Email Address to Receive PSAD Alerts: " ; read inbox1
apt install psad -y
sed -i s/INBOX/$inbox1/g templates/psad.conf
sed -i s/CHANGEME/$host_name.$domain_name/g templates/psad.conf  
cp templates/psad.conf /etc/psad/psad.conf
psad --sig-update
service psad restart
echo "Installation and Configuration Complete"
echo "Run service psad status, for detected events"
echo ""
say_done
else
echo "OK"
say_done
fi

chmod 000 /usr/bin/as >/dev/null 2>&1
chmod 000 /usr/bin/byacc >/dev/null 2>&1
chmod 000 /usr/bin/yacc >/dev/null 2>&1
chmod 000 /usr/bin/bcc >/dev/null 2>&1
chmod 000 /usr/bin/kgcc >/dev/null 2>&1
chmod 000 /usr/bin/cc >/dev/null 2>&1
chmod 000 /usr/bin/gcc >/dev/null 2>&1
chmod 000 /usr/bin/*c++ >/dev/null 2>&1
chmod 000 /usr/bin/*g++ >/dev/null 2>&1

clear
f_banner

echo -n "Enable Unattended Security Updates? (y/n): "; read unattended
if [ "$unattended" == "y" ]; then
dpkg-reconfigure -plow unattended-upgrades
else
clear
fi
  
clear
f_banner

apt install acct -y
touch /var/log/wtmp
echo "OK"
  
clear
f_banner

apt install sysstat -y
sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat
service sysstat start
echo "OK"
say_done
  
clear
f_banner
echo -n " Do you want to Install ArpWatch on this Server? (y/n): " ; read arp_answer
if [ "$arp_answer" == "y" ]; then
echo "Installing ArpWatch"
spinner
apt install -y arpwatch
systemctl enable arpwatch.service
service arpwatch start
echo "OK"
say_done
else
echo "OK"
say_done
fi

clear
f_banner

echo -n " Do you want to set a GRUB bootloader password? (y/n): " ; read grub_answer
if [ "$grub_answer" == "y" ]; then
grub-mkpasswd-pbkdf2 | tee grubpassword.tmp
grubpassword=$(cat grubpassword.tmp | sed -e '1,2d' | cut -d ' ' -f7)
echo " set superusers="root" " >> /etc/grub.d/40_custom
echo " password_pbkdf2 root $grubpassword " >> /etc/grub.d/40_custom
rm grubpassword.tmp
update-grub
echo "You'll have to authenticate on every boot with user root & password you just added"
echo "OK"
say_done
else
echo "OK"
say_done
fi

echo -e ""
echo -e "Securing Boot Settings"
spinner
sleep 2
chown root:root /boot/grub/grub.cfg
chmod og-rwx /boot/grub/grub.cfg
say_done
  
  
cat templates/texts/bye-CIS
say_continue

reboot
