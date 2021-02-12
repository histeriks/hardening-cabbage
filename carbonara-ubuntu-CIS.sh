#!/bin/bash

# Carbonara v1.0
# CIS Hardening script for Ubuntu 18.04
# Feel free to thank Jason who made the original. I was just too lazy to use it interractively,
# so i created my version which ain't such a terrible pain in the arse...i think.

source helpers.sh

##############################################################################################################

f_banner(){
echo
echo "
=====================================================
==================== CARBONARA ======================
=     originally jshielder, butchered cruely by     =
=    yours trully to aid other lazyass bretheren!   =
=   use it for hardening of Ubuntu 18.04 according  =
=   to CIS benchmarks, without moving your pinky!   =
=====================================================
=  Carbonara, not because diamonds are the hardest, = 
=  purest, densest form of carbon, hardest crap in  =
=    whole nature! Carbonara because it resembles   =
=   Spaghetti, Spaghetti Carbonara, junk food made  =
=    from carbonized bacon, spaghetti and eggs...   =
=====================================================
"
echo
echo

}

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

read ip < <(last -i root | grep -o '[0-9]\+[.][0-9]\+[.][0-9]\+[.][0-9]\+') && echo ALL: $ip >> /etc/hosts.allow

usermod -aG sudo $username

echo $username "ALL=(ALL:ALL) ALL" >> /etc/sudoers

service sshd restart

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Securing /tmp Folder"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo -n " ¿Did you Create a Separate /tmp partition during the Initial Installation? (y/n): "; read tmp_answer
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
say_done
else
echo "Nice Going, Remember to set proper permissions in /etc/fstab"
echo ""
echo "Example:"
echo ""
echo "/dev/sda4   /tmp   tmpfs  loop,nosuid,noexec,rw  0 0 "
say_done
fi

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Installing Fail2Ban"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
apt install sendmail
apt install fail2ban
say_done

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Configuring Fail2Ban"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo " Configuring Fail2Ban......"
spinner
sed s/MAILTO/$inbox/g templates/fail2ban > /etc/fail2ban/jail.local
cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf
/etc/init.d/fail2ban restart
say_done

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Tuning and Securing the Linux Kernel"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo " Securing Linux Kernel"
spinner
echo "* hard core 0" >> /etc/security/limits.conf
cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
cp templates/ufw /etc/default/ufw
sysctl -e -p
say_done
    
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Installing RootKit Hunter"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "Rootkit Hunter is a scanning tool to ensure you are you're clean of nasty tools. This tool scans for rootkits, backdoors and local exploits by running tests like:
          - MD5 hash compare
          - Look for default files used by rootkits
          - Wrong file permissions for binaries
          - Look for suspected strings in LKM and KLD modules
          - Look for hidden files
          - Optional scan within plaintext and binary files "
sleep 1
cd rkhunter-1.4.6/
sh installer.sh --layout /usr --install
cd ..
rkhunter --update
khunter --propupd
echo ""
echo " ***To Run RootKit Hunter ***"
echo "     rkhunter -c --enable all --disable none"
echo "     Detailed report on /var/log/rkhunter.log"
say_done
    
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
cho -e "\e[93m[+]\e[00m Tunning bashrc, nano and Vim"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""

echo "Tunning .bashrc......"
spinner
cp templates/bashrc-root /root/.bashrc
cp templates/bashrc-user /home/$username/.bashrc
chown $username:$username /home/$username/.bashrc
echo "OK"

echo "Tunning Vim......"
spinner
tunning vimrc
echo "OK"

echo "Tunning Nano......"
spinner
tunning nanorc
echo "OK"
say_done
    
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Adding Daily System Update Cron Job"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "Creating Daily Cron Job"
spinner
job="@daily apt update; apt dist-upgrade -y"
touch job
echo $job >> job
crontab job
rm job
say_done
    
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Installing PortSentry"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
apt install portsentry
mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf-original
cp templates/portsentry /etc/portsentry/portsentry.conf
sed s/tcp/atcp/g /etc/default/portsentry > salida.tmp
mv salida.tmp /etc/default/portsentry
/etc/init.d/portsentry restart
say_done
    
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Cloning Repo and Installing Artillery"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
git clone https://github.com/BinaryDefense/artillery
cd artillery/
python setup.py
cd ..
echo ""
echo "Setting Iptable rules for artillery"
spinner
for port in 22 372 1433 8080 21 5900 53 110 1723 1337 10000 5800 44443 16993; do
echo "iptables -A INPUT -p tcp -m tcp --dport $port -j ACCEPT" >> /etc/init.d/iptables.sh
done
echo ""
echo "Artillery configuration file is /var/artillery/config"
say_done 

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Running additional Hardening Steps"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "Running Additional Hardening Steps...."
spinner
echo tty1 > /etc/securetty
chmod 0600 /etc/securetty
chmod 700 /root
chmod 600 /boot/grub/grub.cfg
apt purge at
apt install -y libpam-cracklib
echo ""
echo " Securing Cron "
spinner
touch /etc/cron.allow
chmod 600 /etc/cron.allow
awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
echo ""
echo -n " Do you want to Disable USB Support for this Server? (y/n): " ; read usb_answer
if [ "$usb_answer" == "y" ]; then
echo ""
echo "Disabling USB Support"
spinner
echo "blacklist usb-storage" | sudo tee -a /etc/modprobe.d/blacklist.conf
update-initramfs -u
echo "OK"
say_done
else
echo "OK"
say_done
fi

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Installing UnHide"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "Unhide is a forensic tool to find hidden processes and TCP/UDP ports by rootkits / LKMs or by another hidden technique."
sleep 1
apt -y install unhide
echo ""
echo " Unhide is a tool for Detecting Hidden Processes "
echo " For more info about the Tool use the manpages "
echo " man unhide "
say_done

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Installing Tiger"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "Tiger is a security tool that can be use both as a security audit and intrusion detection system"
sleep 1
apt -y install tiger
echo ""
echo " For More info about the Tool use the ManPages "
echo " man tiger "
say_done

iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Install PSAD"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo " PSAD is a piece of Software that actively monitors you Firewall Logs to Determine if a scan
or attack event is in Progress. It can alert and Take action to deter the Threat
NOTE:
IF YOU ARE ONLY RUNNING THIS FUNCTION, YOU MUST ENABLE LOGGING FOR iptables
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG
"
echo ""
echo -n " Do you want to install PSAD (Recommended)? (y/n): " ; read psad_answer
if [ "$psad_answer" == "y" ]; then
echo -n " Type an Email Address to Receive PSAD Alerts: " ; read inbox1
apt install psad
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

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Disabling Compilers"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "Disabling Compilers....."
spinner
chmod 000 /usr/bin/as >/dev/null 2>&1
chmod 000 /usr/bin/byacc >/dev/null 2>&1
chmod 000 /usr/bin/yacc >/dev/null 2>&1
chmod 000 /usr/bin/bcc >/dev/null 2>&1
chmod 000 /usr/bin/kgcc >/dev/null 2>&1
chmod 000 /usr/bin/cc >/dev/null 2>&1
chmod 000 /usr/bin/gcc >/dev/null 2>&1
chmod 000 /usr/bin/*c++ >/dev/null 2>&1
chmod 000 /usr/bin/*g++ >/dev/null 2>&1
spinner echo ""
echo " If you wish to use them, just change the Permissions"
echo " Example: chmod 755 /usr/bin/gcc "
echo " OK"
say_done

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Enable Unattended Security Updates"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo -n " ¿Do you Wish to Enable Unattended Security Updates? (y/n): "; read unattended
if [ "$unattended" == "y" ]; then
dpkg-reconfigure -plow unattended-upgrades
else
clear
fi
  
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Enable Process Accounting"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
apt install acct
touch /var/log/wtmp
echo "OK"
  
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Installing and enabling sysstat"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
apt install sysstat
sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat
service sysstat start
echo "OK"
say_done
  
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m ArpWatch Install"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "ArpWatch is a tool for monitoring ARP traffic on System. It generates log of observed pairing of IP and MAC."
echo ""
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
  
cat templates/texts/bye-CIS
say_continue

reboot
