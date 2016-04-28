#!/bin/bash
if [ -f ~/po-util.sh ];
then
  rm ~/po-util.sh
  cp po-util.sh ~/po-util.sh
else
  cp po-util.sh ~/po-util.sh
fi

if [ -f ~/.bashrc ];
then
  echo ".bashrc present"
  if cat ~/.bashrc | grep "po-util.sh" ;
  then
    echo "po alias already in place."
  else
    echo "no po alias."
    echo 'alias po="~/po-util.sh"' >> ~/.bashrc
  fi
else
  echo "No .bashrc present"
  echo 'alias po="~/po-util.sh"' >> ~/.bashrc
fi

if [ "$1" == "install" ];
then
~/po-util.sh install && echo && echo "Sucessfully installed the Particle Offline Utility and necessary dependencies!" && echo "Read more at https://github.com/nrobinson2000/po-util"
fi
