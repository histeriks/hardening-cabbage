# CARBONARA                     
# savagely butchered from jshielder by yours trully! torn to shreads and rebuilt again, aiding my lazy-ass roots bretheren from all over!
# script's purpose is hardening of Ubuntu 18.04, achieving CIS regulatory compliance without having to move a finger!
                                               
Carbonara not because diamonds are the hardest, purest, densest form of carbon, the hardest crap in whole damn universe...
Carbonara because it resembles spaghetti, Spaghetti Carbonara, trashy food made from carbonized bacon, spaghetti and eggs...

Also, it's done in 5, same as mentioned specialty...

To use, log in into your VPS as root, and type:

git clone https://github.com/histeriks/hardening.git

^^^ to clone the repo...

cd hardening

^^^ to enter the directory...

chmod +x carbonara-ubuntu-CIS.sh

^^^ to make the script executable...

and

./carbonara-ubuntu-CIS.sh

^^^ to finally run the script!

After that, just follow the instructions (you might have to press enter a few times, though i did my best to make it almost fully autonomous).

Script will automatically extract your current IP address and add it to /etc/hosts.allow file, near the end of the installation procedure. This is a must, so, if you change your IP too often you might want to consider using a VPN to access and protect your infrastructure (which is recommended anyway. you can follow my tutorial on creation of your own VPN's on affordable $2.5/month VPS instances on Hetzner & DigitalOcean. You can read it on my website: www.penetration.zone).

User you create in the hardening process is automatically added to Sudo group and has all administrative privileges. After hardening, you won't be able to log in directly as root anymore, but you can always use "sudo passwd" to reset your root pass and log in as root with "su".

Also, SSH communication port will change from 22 to 372, so you will have to adjust that as well (use "ssh -p 372 username@server-address", or make permanent changes in your .ssh/config file).

If you find the script handy, visit my blog and share the fuck out of me furher. I'm an attention whore, a bottomless pit munching ego boosts of all shapes and sizes:

http://www.penetration.zone
