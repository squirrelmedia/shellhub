#!/usr/bin/env bash
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

main()
{
  install_dependency
  compile_source
  curl -s https://core.telegram.org/getProxySecret -o proxy-secret
  curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
  SECRET=$(head -c 16 /dev/urandom | xxd -ps)

  read -p "Input server port:" SERVER_PORT
  echo $SERVER_PORT
  # read -p "Input secret (defalut $SERVER_PORT)：" SECRET
  # echo $SECRET
  ./mtproto-proxy -u nobody -p 8888 -H ${SERVER_PORT} -S ${SECRET} --aes-pwd proxy-secret proxy-multi.conf -M 1
}
main
