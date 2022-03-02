# CABBAGE                     
# was "jshielder" until it got butchered into this salad for lazy brethern who value their time...
# dark art of achieving plenty while doing nothing - CIS compliant Ubuntu without moving a pinky! As old saying goes: work created a man but leisure created a gentleman. Work smart, not hard.

To use Cabbage, log into your VPS as root, and type:

git clone https://github.com/histeriks/hardening.git 
cd hardening
chmod +x cabbage.sh
./cabbage.sh

Script extracts your workstation's current public IP address and adds it to the /etc/hosts.allow file. If you use more than one public IP address, add them as well, or finally start using a VPN. User you create during hardening process is automatically added to Sudo group. After hardening, you won't be able to log in directly as root anymore, but you can always use "sudo passwd" to reset your root pass and log in as root with "su" if needed for whatever reason...

SSH communication port will change from 22 to 372, so you will have to adjust that as well (connect with "ssh -p 372 username@server-address", or make permanent changes in your .ssh/config file).
