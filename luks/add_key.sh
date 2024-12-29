#!/usr/bin/env bash

#title           :add_key.sh
#description     :It helps to generate & add LUKS key. Also add unlock usb script
#author          :H.R. Shadhin <dev@hrshadhin.me>
#date            :2024-12-29
#version         :0.1
#usage           :bash add_key.sh
#bash_version    :4.4 or later
#============================================================

# Functions
welcome() {
  cat << "EOF"
  _   _   _   _     _   _   _     _   _   _   _   _   _   _   _   _
 / \ / \ / \ / \   / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \
( L | U | K | S ) ( K | E | Y ) ( G | E | N | E | R | A | T | O | R )
 \_/ \_/ \_/ \_/   \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/
EOF
}

helpme(){
    echo ":::         LUKS KEY GENERATOR            :::"
    echo ":::"
    echo "::: Usage: add_key.sh <command> [option]"
    echo ":::"
    echo "::: Commands:"
    echo ":::  -d,   do Add key"
    echo ":::  -h,   help   Show help "
    echo ":::"
    echo "::: Examples:"
    echo ":::  add_key.sh help"
    echo ":::  add_key.sh do"
    exit 0
}

ok() { echo -e '\033[1;32m'$1'\033[0m'; } # Light Green
die() { echo -e '\033[1;31m'$1'\033[0m'; exit $2; } # Red

gen_keys(){
    
    # Create keyfile
    keypath=$1
    keyname=$2

    dd if=/dev/urandom bs=1 count=256 2>/dev/null > "$keypath/$keyname.lek"

    # Create recovery key
    keyarr=()
    for i in {1..8}; do
    keyarr+=($(tr -cd 0-9 </dev/urandom | head -c 6))
    done
    recoverkey=$(echo ${keyarr[*]} | tr ' ' '-')
    cat << EOF > "keys/$machinename/recover-key.txt"
Recovery key for LUKS root partition encryption

You can verify that the key name in /etc/crypttab matches the following UUID:

    $keyname

If this is the UUID based filename in /etc/crypttab, then you can use the following recovery key to unlock the partition:

    $recoverkey

If the above UUID does not match, then you can still use the installation passphrase in keyslot 0.
EOF
    echo $recoverkey
}

update_crypttab(){
    sed -i "s/none luks,discard/$1 luks,discard,keyscript=\/bin\/luksunlockusb/g" /etc/crypttab
    if [ $? -ne 0 ]; then
        die "altering /etc/crypttab failed, needs sudo?" 1
    fi
}

write_unlock_usb(){
    cat << "END" > /bin/luksunlockusb
#!/bin/sh
set -e
if [ $CRYPTTAB_TRIED -eq "0" ]; then
    sleep 3
fi
if [ ! -e /mnt ]; then
    mkdir -p /mnt
fi
for usbpartition in /dev/disk/by-id/usb-*-part1; do
    usbdevice=$(readlink -f $usbpartition)
    if mount -t vfat $usbdevice /mnt 2>/dev/null; then
        if [ -e /mnt/$CRYPTTAB_KEY.lek ]; then
            cat /mnt/$CRYPTTAB_KEY.lek
            umount $usbdevice
            exit
        fi
        umount $usbdevice
    fi
done
/lib/cryptsetup/askpass "Insert USB key and press ENTER: "
END

# change permission
chmod 755 /bin/luksunlockusb
}

yoyo(){
    ok "Checking prerequisite"
    # check sudo user
    if [ "$(id -u)" -ne 0 ]; then die "Please run with sudo"; fi

    # Ensure 'uuid' tool is installed
    if ! command -v uuid > /dev/null; then
        die "command 'uuid' not found" 1
    fi

    # Ask for non-existing machine name
    echo -n "Identify this machine: "
    read machinename
    if [[ -d "keys/$machinename" ]]; then
        die "machine already exists" 2
    fi

    # Create keys folder
    ok "Generating key"
    keypath="keys/$machinename"
    mkdir -p $keypath

    # keyfile & recovery key
    keyname=`uuid`
    local recoverkey=$(gen_keys $keypath $keyname)

    # modify crypttab
    ok "Updating crypttab"
    update_crypttab $keyname

    # crete unlock script
    ok "Writing luksunlockusb"
    write_unlock_usb

    # add keys
    ok "Adding keys"
    base64key=$(cat "$keypath/$keyname.lek" | base64 -w 0)
    echo -n "$base64key" | base64 -d > $keyname.lek
    echo -n "$recoverkey" > $keyname.txt
    for device in $(blkid --match-token TYPE=crypto_LUKS -o device); do
        ok "Adding key"
        cryptsetup luksAddKey $device $keyname.lek
        ok "Recovery key"
        cryptsetup luksAddKey $device $keyname.txt
        echo $device
    done
    ok "Cleaning files"
    rm $keyname.lek
    rm $keyname.txt

    ok "Updating initramfs"
    update-initramfs -u

    ok "done (•‿•)"
}

main () {
  welcome

  # handle specific function based on args
  case "$1" in
  "-d"   | "do"   ) shift; yoyo "$@";;
  "-h"   | "help" )           helpme;;
  *               )           helpme;;
  esac
}

# exec from here
main "$@"