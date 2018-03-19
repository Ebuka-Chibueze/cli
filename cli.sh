#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
./scripts.d/rpi_model_array.sh

function expandfs () {
  # expandfs is way too complex, it should be handled by raspi-config
  raspi-config --expand-rootfs 2>&1 >/dev/null
  echo "Success: the filesystem will be expanded on the next reboot"
  exit 0
}

function rename () {
  CURRENT_HOSTNAME=$(cat /etc/hostname | tr -d " \t\n\r")
  echo $1 > /etc/hostname
  sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$1/g" /etc/hosts
  hostname $1
  echo "Success: the hostname has been modified"
  exit 0
}

function password () {
  currentuser="$( whoami)"
  if [ $currentuser != "root" ]; then
      echo " You ran this without sudo privileges or not as root"
      exit 1
  fi
  echo "pi:$1" | chpasswd
  echo "password change success"
  exit 0
}

function sshkeyadd () {
  mkdir -p /root/.ssh /home/pi/.ssh
  chmod 700 /root/.ssh /home/pi/.ssh

  echo "$@" >> /home/pi/.ssh/authorized_keys
  chmod 600 /home/pi/.ssh/authorized_keys
  chown -R pi:pi /home/pi/.ssh

  echo "$@" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  echo "====== Added to 'pi' and 'root' user's authorized_keys ======"
  echo "$@"
}

function detectrpi () {
  declare -A RPI_array

  rpi_revision_version="$(cat /proc/cpuinfo | grep Revision | cut -d ':' -f2 | tr -d '[:space:]')"

  echo ${!RPI_array[@]};

  for key in "${!RPI_array[@]}"; do
  	if [[ "$key" == "$rpi_revision_version" ]]; then
  		echo "Your model is ${RPI_array[${key}]}"
          fi
  done

}

function static_wifi () {
  #Set
  ip=""
  mask=""
  gateway=""
  dns=""
  if [ -z $ip | -z $mask | -z $gateway | -z $dns ]; then
      echo "Set the variables ip mask gateway dns"
  else
          ifconfig wlan0 up || true
          ifconfig wlan0 down || true
          mkdir -p /etc/network/interfaces.d/wlan0
          interface_file="$SCRIPTPATH/lib/templates/network/wlan0/static"
          cp -r $interface /etc/network/interfaces.d/wlan0
          sed -i "s/$ip/IPADDRESS/g" /etc/network/interfaces.d/wlan0/static
          sed -i "s/$mask/NETMASK/g" /etc/network/interfaces.d/wlan0/static
          sed -i "s/$gateway/GATEWAY/g" /etc/network/interfaces.d/wlan0/static
          sed -i "s/$dns/DNS/g" /etc/network/interfaces.d/wlan0/static
          ifconfig wlan0 up || true
          echo "This pirateship has anchored successfully!"
  fi
}


# function detectwifi {
#   declare -A RPI_array
#
#   rpi_revision_version="$(cat /proc/cpuinfo | grep Revision | cut -d ':' -f2 | tr -d '[:space:]')"
#
#   echo ${!RPI_array[@]};
#
#   for key in "${!RPI_array[@]}"; do
#   	if [[ "$key" == "$rpi_revision_version" ]]; then
#   		echo "Your model is ${RPI_array[${key}]}"
#           fi
#   done
#
# }



function version {
  echo $(npm info '@treehouses/cli' version)
}

function help {
  echo "Usage: $(basename $0)"
  echo
  echo "   expandfs                  expands the partition of the RPI image to the maximum of the SDcard"
  echo "   rename <hostname>         changes hostname"
  echo "   password <password>       change the password for 'pi' user"
  echo "   sshkeyadd <public_key>    add a public key to 'pi' and 'root' user's authorized_keys"
  echo "   version                   returns the version of $(basename $0) command"
  echo
  exit 1
}

function checkroot {
  if [ $(id -u) -ne 0 ];
  then
      echo "Error: Must be run with root permissions"
      exit 1
  fi
}


case $1 in
  expandfs)
    checkroot
    expandfs
    ;;
  rename)
    checkroot
    rename $2
    ;;
  password)
    checkroot
    password $2
    ;;
  sshkeyadd)
    checkroot
    shift
    sshkeyadd $@
    ;;
  version)
    version
    ;;
  *)
    help
    ;;
esac
