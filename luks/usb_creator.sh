#!/usr/bin/env bash

#title           :usb_creator.sh
#description     :It helps to create LUKS key holding USB stick
#author          :H.R. Shadhin <dev@hrshadhin.me>
#date            :2024-12-29
#version         :0.1
#usage           :bash usb_creator.sh
#bash_version    :4.4 or later
#============================================================

# Functions
welcome() {
  cat << "EOF"
  _   _   _   _     _   _   _     _   _   _   _   _   _   _
 / \ / \ / \ / \   / \ / \ / \   / \ / \ / \ / \ / \ / \ / \
( L | U | K | S ) ( U | S | B ) ( C | R | E | A | T | O | R )
 \_/ \_/ \_/ \_/   \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/
EOF
}

helpme(){
    echo ":::   LUKS key holding USB stick creator   :::"
    echo ":::"
    echo "::: Usage: usb_creator.sh <command> [option]"
    echo ":::"
    echo "::: Commands:"
    echo ":::  -c,   create Create USB"
    echo ":::  -h,   help   Show help "
    echo ":::"
    echo "::: Examples:"
    echo ":::  usb_creator.sh help"
    echo ":::  usb_creator.sh create"
    exit 0
}

ok() { echo -e '\033[1;32m'$1'\033[0m'; } # Light Green
die() { echo -e '\033[1;31m'$1'\033[0m'; exit $2; } # Red

yoyo () {
    ok "Checking prerequisite"
    # check sudo user
    if [ "$(id -u)" -ne 0 ]; then die "Please run with sudo"; fi

    devs=$(lsblk --noheadings --nodeps --output NAME,SIZE,TRAN,RM | sed 's/\s\s*/|/g' | grep "usb|1$")
    if [ -z $devs ]; then
        die "no removable USB drives found" 1
    fi
    ok "Which removable USB drives do you want to ERASE?"
    select dev in $devs; do
        dev=$(echo $dev | cut -d'|' -f1)
        if [ ! -b /dev/$dev ]; then
            die "invalid option" 2
        fi
        spec="start=2048 size=32768 type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B bootable attrs=RequiredPartition name=luks"
        echo $spec | sfdisk -q --wipe always /dev/${dev} -X gpt
        if [ $? -ne 0 ]; then
            die "sfdisk failed, needs sudo?" 3
        fi
        mkfs.fat /dev/${dev}1
        if [ $? -ne 0 ]; then
            die "mkfs failed" 4
        fi
        mount /dev/${dev}1 /mnt
        if [ $? -ne 0 ]; then
            die "mount failed" 5
        fi
        find keys -type f -name "*.lek" -exec echo {} \; -exec cp {} /mnt \;
        umount /mnt
        ok "completed (•‿•)"
        exit 0
    done
}

main () {
  welcome

  if [ $# = 0 ]; then
      helpme
  fi

  # handle specific function based on args
  case "$1" in
  "-c"   | "create"  ) shift; yoyo "$@";;
  "-h"   | "help"    )           helpme;;
  *                  )           helpme;;
  esac
}

# exec from here
main "$@"