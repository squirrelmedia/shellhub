#!/usr/bin/env bash
GREEN='\033[0;31m'
NC='\033[0m' # No Color

init_release(){
  if [ -f /etc/os-release ]; then
      # freedesktop.org and systemd
      . /etc/os-release
      OS=$NAME
  elif type lsb_release >/dev/null 2>&1; then
      # linuxbase.org
      OS=$(lsb_release -si)
  elif [ -f /etc/lsb-release ]; then
      # For some versions of Debian/Ubuntu without lsb_release command
      . /etc/lsb-release
      OS=$DISTRIB_ID
  elif [ -f /etc/debian_version ]; then
      # Older Debian/Ubuntu/etc.
      OS=Debian
  elif [ -f /etc/SuSe-release ]; then
      # Older SuSE/etc.
      ...
  elif [ -f /etc/redhat-release ]; then
      # Older Red Hat, CentOS, etc.
      ...
  else
      # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
      OS=$(uname -s)
  fi

  # convert string to lower case
  OS=`echo "$OS" | tr '[:upper:]' '[:lower:]'`

  if [[ $OS = *'ubuntu'* || $OS = *'debian'* ]]; then
    PM='apt'
  elif [[ $OS = *'centos'* ]]; then
    PM='yum'
  else
    exit 1
  fi
}

install_dependency()
{
  init_release
  if [[ $PM = 'apt' ]]; then
    apt install git curl build-essential libssl-dev zlib1g-dev -y
  elif [[ $PM = 'yum' ]]; then
    #statements
    yum install openssl-devel zlib-devel -y
    yum groupinstall "Development Tools" -y
  fi
}

compile_source()
{
  git --version 2>&1 >/dev/null # improvement by tripleee
  GIT_IS_AVAILABLE=$?
  if [[ $GIT_IS_AVAILABLE -eq 0 ]]; then
    if [[ ! -d "MTProxy" ]]; then
      git clone https://github.com/TelegramMessenger/MTProxy
    fi
    cd MTProxy
    make && cd objs/bin
  else
    $PM install git -y
    compile_source
  fi
}

complete()
{
  IP_ADDRESS=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
  clear
  echo
  echo -e "${GREEN}***************************************************${NR}"
  echo -e "* Server : ${GREEN}${IP_ADDRESS}${NR}"
  echo -e "* Port   : ${GREEN}${SERVER_PORT}${NR}"
  echo -e "* Secret : ${GREEN}${SECRET}${NR}"
  echo -e "Here is a link to your proxy server:\n${GREEN}https://t.me/proxy?server=${IP_ADDRESS}&port=${SERVER_PORT}&secret=${SECRET}${NR}"
  echo
  echo -e "And here is a direct link for those who have the Telegram app installed:\n${GREEN}tg://proxy?server=${IP_ADDRESS}&port=${SERVER_PORT}&secret=${SECRET}${NR}"
  echo -e "${GREEN}***************************************************${NR}"
  echo
}


main()
{
  install_dependency
  compile_source
  curl -s https://core.telegram.org/getProxySecret -o proxy-secret
  curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
  clear
  echo
  read -p "Input server port:" SERVER_PORT
  echo $SERVER_PORT
  read -p "Input secret (defalut: Auto Generated)：" SECRET
  if [[ -z ${SECRET} ]]; then
    SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo $SECRET
  fi
  nohup ./mtproto-proxy -u nobody -p 3333 -H ${SERVER_PORT} -S ${SECRET} --aes-pwd proxy-secret proxy-multi.conf -M 1 &
  if [[ $? -eq 0 ]]; then
    complete
  else
    echo "Sorry, Install failed"
  fi
}
main
