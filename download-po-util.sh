#!/bin/bash
blue_echo() {
    echo "$(tput setaf 6)$MESSAGE $(tput sgr0)"
}

green_echo() {
    echo "$(tput setaf 2)$MESSAGE $(tput sgr0)"
}

red_echo() {
    echo "$(tput setaf 1)$MESSAGE $(tput sgr0)"
}

if [ "$1" == "ci" ];
then
  cp po-util.sh ~/po-util.sh
else
  rm ~/po-util.sh
  curl -fsSLo ~/po-util.sh https://raw.githubusercontent.com/nrobinson2000/po-util/master/po-util.sh
  chmod +x ~/po-util.sh
fi

if [ -f ~/.bash_profile ];
then
  MESSAGE=".bash_profile present." ; green_echo
else
MESSAGE="No .bash_profile present. Installing.." ; red_echo
echo "
export PATH=\"/usr/local/sbin:$PATH\"
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi" >> ~/.bash_profile
fi

if [ -f ~/.bashrc ];
then
  MESSAGE=".bashrc present." ; green_echo
  if grep "po-util.sh" ~/.bashrc ;
  then
    MESSAGE="po alias already in place." ; green_echo
  else
    MESSAGE="no po alias.  Installing..." ; red_echo
    echo 'alias po="~/po-util.sh"' >> ~/.bashrc
  fi
else
  MESSAGE="No .bashrc present.  Installing..." ; red_echo
  echo 'alias po="~/po-util.sh"' >> ~/.bashrc
fi

~/po-util.sh install && echo && MESSAGE="Sucessfully installed the Particle Offline Utility and necessary dependencies!" ; green_echo && echo "Read more at https://github.com/nrobinson2000/po-util"
