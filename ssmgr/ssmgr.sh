#!/usr/bin/env bash
GREEN='\033[0;32m'
NC='\033[0m' # No Color

isRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}

init_release(){
  # if [ -f /etc/os-release ]; then
  #     # freedesktop.org and systemd
  #     . /etc/os-release
  #     OS=$NAME
  # elif type lsb_release >/dev/null 2>&1; then
  #     # linuxbase.org
  #     OS=$(lsb_release -si)
  # elif [ -f /etc/lsb-release ]; then
  #     # For some versions of Debian/Ubuntu without lsb_release command
  #     . /etc/lsb-release
  #     OS=$DISTRIB_ID
  # elif [ -f /etc/debian_version ]; then
  #     # Older Debian/Ubuntu/etc.
  #     OS=Debian
  # elif [ -f /etc/SuSe-release ]; then
  #     # Older SuSE/etc.
  #     ...
  # elif [ -f /etc/redhat-release ]; then
  #     # Older Red Hat, CentOS, etc.
  #     ...
  # else
  #     # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
  #     OS=$(uname -s)
  # fi
  #
  # # convert string to lower case
  # OS=`echo "$OS" | tr '[:upper:]' '[:lower:]'`
  #
  # if [[ $OS = *'ubuntu'* || $OS = *'debian'* ]]; then
  #   PM='apt'
  # elif [[ $OS = *'centos'* ]]; then
  #   PM='yum'
  # else
  #   exit 1
  # fi
  PM='apt'
}

# install shadowsocks
install_shadowsocks(){
  # init package manager
  init_release
  echo ${PM}
  #statements
  if [[ ${PM} = "apt" ]]; then
    apt-get install dnsutils -y
    apt install net-tools -y
    apt-get install python-pip -y
  elif [[ ${PM} = "yum" ]]; then
    yum install bind-utils -y
    yum install net-tools -y
    yum install python-setuptools -y && easy_install pip
  fi
  pip install shadowsocks
  # start ssserver and run manager background
  ssserver -m aes-256-cfb -p 12345 -k abcedf --manager-address 127.0.0.1:4000 --user nobody -d start
}

config(){
  #download config file

  #modify config ss.yml
  CONFIG_FILE=ss.yml
  TARGET_KEY=password
  read -p "Type webgui manage passwor('')d:" TARGET_VALUE
  #quote('') VALUE
  TARGET_VALUE=\'$TARGET_VALUE\'
  sed  -i "s/\($TARGET_KEY *: *\).*/\1$TARGET_VALUE/" $CONFIG_FILE

  #config manager password
  CONFIG_FILE=webgui.yml
  sed  -i "s/\($TARGET_KEY *: *\).*/\1$TARGET_VALUE/" $CONFIG_FILE
  #config ip address
  TARGET_KEY=address
  IP_ADDRESS=$(dig +short myip.opendns.com @resolver1.opendns.com)
  sed  -i "s/\($TARGET_KEY *: *\).*/\1$IP_ADDRESS/" $CONFIG_FILE

  # config email.username
  read -p "Input your email username:" email_username
  TARGET_KEY=username
  # quote email username
  TARGET_VALUE=\'${email_username}\'
  sed  -i "s/\($TARGET_KEY *: *\).*/\1$TARGET_VALUE/" $CONFIG_FILE

  # config email.password
  # sed -r 's/^(\s*)(email\s*:\s*password\s*$)/\1email: password/dyclogin' $CONFIG_FILE

  # config host
  TARGET_KEY=host
  TARGET_VALUE=$(dig +short myip.opendns.com @resolver1.opendns.com)
  #quote host value
  TARGET_VALUE=\'${TARGET_VALUE}\'
  sed  -i "s/\($TARGET_KEY *: *\).*/\1$TARGET_VALUE/" $CONFIG_FILE

  # config site
  TARGET_KEY=site
  TARGET_VALUE=$(dig +short myip.opendns.com @resolver1.opendns.com)
  #quote host value
  HTTP="http:\/\/"
  TARGET_VALUE=\'${HTTP}${TARGET_VALUE}\'
  sed  -i "s/\($TARGET_KEY *: *\).*/\1$TARGET_VALUE/" $CONFIG_FILE

}

install_ssmgr(){
  curl -sL https://rpm.nodesource.com/setup_8.x | bash -
  yum install -y nodejs
  npm i -g shadowsocks-manager --unsafe-perm
}

run_ssgmr(){
  npm i -g pm2
  pm2 --name "ss" -f start ssmgr -x -- -c ss.yml
  pm2 --name "webgui" -f start ssmgr -x -- -c webgui.yml
}

go_workspace(){
  mkdir ~/.ssmgr/
  cd ~/.ssmgr/
}

main(){
  #check root permission
  isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
    install_shadowsocks
    install_ssmgr
    config
    run_ssgmr
  fi
}

# start run script
main
