#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"



change_password() {

  currentuser="$( whoami)"
  if [ $currentuser != "root" ]; then
      echo " You ran this without sudo privileges or not as root"
      exit 1
  fi
  echo pi:$1 | chpasswd

  echo "successfully changed password"


}
