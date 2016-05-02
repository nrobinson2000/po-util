#!/bin/bash
blue_echo() {
    echo "$(tput setaf 6)$(tput bold) $MESSAGE $(tput sgr0)"
}

green_echo() {
    echo "$(tput setaf 2)$(tput bold) $MESSAGE $(tput sgr0)"
}

red_echo() {
    echo "$(tput setaf 1)$(tput bold) $MESSAGE $(tput sgr0)"
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

if [ "$1" == "ci" ];
then
  echo "export PARTICLE_TOOLCHAIN_INSTALL=$HOME/particle" >> ~/.bashrc
  export PARTICLE_TOOLCHAIN_INSTALL="$HOME/particle"
  mkdir $PARTICLE_TOOLCHAIN_INSTALL
else
  read -p "Where should we install the Particle Toolchain?                                 [default: ~/particle] " response
  sleep 1
  if [ "$response" == "" ];
  then
    echo "export PARTICLE_TOOLCHAIN_INSTALL=$HOME/particle" >> ~/.bashrc
    export PARTICLE_TOOLCHAIN_INSTALL="$HOME/particle"
    mkdir $PARTICLE_TOOLCHAIN_INSTALL
  else
  echo "export PARTICLE_TOOLCHAIN_INSTALL=$response" >> ~/.bashrc
  export PARTICLE_TOOLCHAIN_INSTALL="$response"
  mkdir $PARTICLE_TOOLCHAIN_INSTALL
fi
fi

~/po-util.sh install && echo && MESSAGE="Sucessfully installed the Particle Offline Utility and necessary dependencies!" ; green_echo && echo "Read more at http://bit.ly/po-util"
