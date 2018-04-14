#!/usr/bin/env bash

RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
NO_COLOR='\033[0m'

# Encryption
ciphers=(
  aes-128-cfb
  aes-192-cfb
  aes-256-cfb
  chacha20
  salsa20
  rc4-md5
  aes-128-ctr
  aes-192-ctr
  aes-256-ctr
  aes-256-gcm
  aes-192-gcm
  aes-128-gcm
  camellia-128-cfb
  camellia-192-cfb
  camellia-256-cfb
  chacha20-ietf
  bf-cfb
)
# current/working directory
CUR_DIR=`pwd`

# script introduction
intro() {
  clear
  echo
  echo "******************************************************"
  echo "* OS     : CentOS                                    *"
  echo "* Desc   : auto install shadowsocks on CentOS server *"
  echo "* Author : https://github.com/shellhub               *"
  echo "******************************************************"
  echo
}

isRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}

config(){

  # config encryption password
  read -p "Password used for encryption (Default: shellhub):" sspwd
  if [[ -z "${sspwd}" ]]; then
    sspwd="shellhub"
  fi
  echo -e "encryption password: ${GREEN_COLOR}${sspwd}${NO_COLOR}"

  # config server port
  while [[ true ]]; do
    local port=$(shuf -i 2000-65000 -n 1)
    read -p "Server port(1-65535) (Default: ${port}):" server_port
    if [[ -z "${server_port}" ]]; then
      server_port=${port}
    fi

    # make sure port is number
    expr ${server_port} + 1 &> /dev/null
    if [[ $? -eq 0 ]]; then
      # make sure port in range(1-65535)
      if [ ${server_port} -ge 1 ] && [ ${server_port} -le 65535 ]; then
        #make sure port is free
        lsof -i:${server_port} &> /dev/null
        if [[ $? -ne 0 ]]; then
          echo -e "server port: ${GREEN_COLOR}${server_port}${NO_COLOR}"
          break
        else
          echo -e "${RED_COLOR}${server_port}${NO_COLOR} is occupied"
          continue
        fi
      fi
    fi
    echo -e "${RED_COLOR}Invalid${NO_COLOR} port:${server_port}"
  done

  # config encryption method
  while [[ true ]]; do
    for (( i = 0; i < ${#ciphers[@]}; i++ )); do
      echo -e "${GREEN_COLOR}`expr ${i} + 1`${NO_COLOR}:\t${ciphers[${i}]}"
    done
    read -p "Select encryption method (Default: aes-256-cfb):" pick
    if [[ -z ${pick} ]]; then
      # default is aes-256-cfb
      pick=3
    fi
    expr ${pick} + 1 &> /dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},try again"
      continue
    elif [ ${pick} -lt 1 ] || [ ${pick} -gt ${#ciphers[@]} ]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},should be is(1-${#ciphers[@]})"
      continue
    else
      encryption_method=${ciphers[${pick}-1]}
      echo -e "encryption method: ${GREEN_COLOR}${encryption_method}${NO_COLOR}"
      break
    fi
  done
  # add shadowsocks config file
  cat <<EOT > /etc/shadowsocks.json
{
  "server":"0.0.0.0",
  "server_port":${server_port},
  "local_address": "127.0.0.1",
  "local_port":1080,
  "password":"${sspwd}",
  "timeout":300,
  "method":"${encryption_method}",
  "fast_open": false
}
EOT
}

containsIgnoreCase(){
  # convert arg1 to lower case
  str=`echo "$1" | tr '[:upper:]' '[:lower:]'`
  # convert arg2 to lower case
  searchStr=`echo "$2" | tr '[:upper:]' '[:lower:]'`
  echo ${1}
  echo ${2}
  if [[ ${str} = *${searchStr}* ]]; then
    echo "true"
  else
    echo "false"
  fi
}

addTcpPort(){
  tcpPort=${1}
  cat /etc/*elease | grep -q VERSION_ID=\"14.04\"
  if [[ $? = 0 ]]; then
    firewall-cmd --zone=public --add-port=${tcpPort}/tcp --permanent
    firewall-cmd --reload
  else
    iptables -I INPUT -p tcp -m tcp --dport ${tcpPort} -j ACCEPT
    service iptables save
  fi
}

# show install success information
successInfo(){
  clear
  echo
  echo "Install completed"
  echo -e "server_port:\t${GREEN_COLOR}${server_port}${NO_COLOR}"
  echo -e "password:\t${GREEN_COLOR}${sspwd}${NO_COLOR}"
  echo -e "encryption:\t${GREEN_COLOR}${encryption_method}${NO_COLOR}"
  echo -e "visit:\t\t${GREEN_COLOR}https://www.github.com/shellhub${NO_COLOR}"
  echo
}

#check root permission
isRoot=$( isRoot )

if [[ "${isRoot}" != "true" ]]; then
  echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
  exit 1
else
  intro
  config
  yum update -y && yum upgrade -y
  yum install python-setuptools && easy_install pip
  pip install shadowsocks
  addTcpPort ${server_port}
  # run background
  nohup ssserver -c /etc/shadowsocks.json &
  successInfo
fi
