#!/bin/bash
cd ~
curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
chmod +x po-util.sh
echo 'alias po="~/po-util.sh"' >> .bashrc
~/po-util.sh install && echo && echo "Sucessfully installed the Particle Offline Utility and necessary dependencies!" && echo "Read more at https://raw.githubusercontent.com/nrobinson2000/po-util/"
