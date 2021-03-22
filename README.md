# CABBAGE                     
# "jshielder" which got butchered into a salad for lazy brethern...
# dark art of achieving plenty while doing nothing - CIS compliant Ubuntu without moving a pinky! As old saying goes: work created a man but leisure created a gentleman. Work smart, not hard.

To use Cabbage, log into your VPS as root, and type:

git clone https://github.com/histeriks/hardening.git  <--- to clone the repo...

cd hardening  <--- to enter the directory...

chmod +x cabbage.sh  <--- to make the script executable...

&

./cabbage.sh <--- to finally run the script!

After that, just follow the instructions (you might have to press enter a few times, still working on making it fully autonomous).

Script will automatically extract your current IP address and add it to /etc/hosts.allow file, near the end of the installation procedure. This is a must, so, if you change your IP too often you might want to consider using a VPN to access and protect your infrastructure (which you should anyway. You can create a VPN server on a dirt-cheap $2.5/month VPS on Hetzner or DigitalOcean).

User you create in the hardening process is automatically added to Sudo group and has all administrative privileges. After hardening, you won't be able to log in directly as root anymore, but you can always use "sudo passwd" to reset your root pass and log in as root with "su" if needed, for whatever reason...

SSH communication port will change from 22 to 372, so you will have to adjust that as well (use "ssh -p 372 username@server-address", or make permanent changes in your .ssh/config file).

If you find the script handy, visit my blog and share the fuck out of me furher, i'm an attention whore...

http://www.penetration.zone
