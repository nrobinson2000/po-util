#!/bin/bash
curl -fsSLO https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
cp po-util.sh ~/po-util.sh

~/po-util.sh install && echo && echo "Sucessfully installed the Particle Offline Utility and necessary dependencies!" && echo "Read more at https://github.com/nrobinson2000/po-util"
