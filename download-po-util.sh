#!/bin/bash
cd ~
curl -O https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
chmod +x po-util.sh
echo 'alias po="~/po-util.sh"' >> .bashrc
alias po="~/po-util.sh"

if [ "$1" == "install" ];
then
po install && echo && echo "Sucessfully installed the Particle Offline Utility and necessary dependencies!" && echo "Read more at https://raw.githubusercontent.com/nrobinson2000/po-util/"
exit
fi

echo && echo "Sucessfully downloaded the Particle Offline Utility!" && echo "Run - po install - to install dependencies and complete setup." && echo "Read more at https://raw.githubusercontent.com/nrobinson2000/po-util/"
