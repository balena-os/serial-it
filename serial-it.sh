#!/bin/bash

set -e

help () {
    cat << EOF
Helper script for activating getty on supported boards.
serial-it.sh [options]

Options:
    -h, --help
        Display this help and exit.

    --root-mountpoint PATH
        Mandatory argument.

    --boot-mountpoint PATH

    -b, --board BOARD
        Mandatory argument.
EOF
}

# Get the absolute script location
pushd `dirname $0` > /dev/null 2>&1
SCRIPTPATH=`pwd`
popd > /dev/null 2>&1

# Parse arguments
while [[ $# > 0 ]]; do
    key=$1
    case $key in
        -h|--help)
            help
            exit 0
            ;;
        --root-mountpoint)
            if [ -z "$2" ]; then
                log ERROR "\"$1\" argument needs a value."
            fi
            ROOT_MOUNTPOINT=$(realpath $2)
            shift
            ;;
        --boot-mountpoint)
            if [ -z "$2" ]; then
                log ERROR "\"$1\" argument needs a value."
            fi
            BOOT_MOUNTPOINT=$(realpath $2)
            shift
            ;;
        -b|--board)
            if [ -z "$2" ]; then
                log ERROR "\"$1\" argument needs a value."
            fi
            BOARD=$2
            shift
            ;;
        *)
            echo "ERROR: Argument '$1' unknown."
            exit 1
            ;;
    esac
    shift
done

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root"
   exit 1
fi
echo "[INFO] Root detected ... ok."

# Make sure the board has been specified
if [ -z "$BOARD" ]; then
    echo "[ERROR] No board specified"
    exit 1
fi
echo "[INFO] Board detected ... ok."

# Make sure the root mountpoint has been specified
if [ ! -d $ROOT_MOUNTPOINT ]; then
    echo "[ERROR] Root mountpoint $ROOT_MOUNTPOINT doesn't exist."
    exit 1
fi
echo "[INFO] Root mountpoint detected ... ok."

# Make sure the boot mountpoint has been specified if needed
if [ "$BOARD" == "raspberrypi3" ]; then
    if [ -z "$BOOT_MOUNTPOINT" ] || [ ! -f $BOOT_MOUNTPOINT/config.txt ]; then
        echo "[ERROR] A valid boot mountpoint is needed."
        exit 1
    fi
    echo "[INFO] Boot mountpoint detected ... ok."
fi

# Board specific stuff
case $BOARD in
    raspberry-pi)
        serialdev=ttyAMA0
        baudrate=9600
        ;;
    raspberry-pi2)
        serialdev=ttyAMA0
        baudrate=9600
        ;;
    raspberrypi3)
        # This assumes pi3-miniuart-bt-overlay.dtb is not used
        serialdev=ttyS0
        baudrate=9600

        # Raspberrypi3 needs a stable CORE freq - https://github.com/RPi-Distro/repo/issues/22
        echo "[INFO] Setting 'enable_uart=1' in $BOOT_MOUNTPOINT/config.txt ."
        if grep -Fxq "enable_uart=1" $BOOT_MOUNTPOINT/config.txt; then
            echo "[WARN] $BOOT_MOUNTPOINT/config.txt already contains 'enable_uart=1'."
        else
            echo "enable_uart=1" >> $BOOT_MOUNTPOINT/config.txt
        fi
        ;;
    qemux86)
        serialdev=ttyS0
        baudrate=9600
        ;;
    qemux86-64)
        serialdev=ttyS0
        baudrate=9600
        ;;
    intel-edison)
        serialdev=ttyMFD2
        baudrate=115200
        ;;
    iot2000)
        serialdev=ttyS1
        baudrate=115200
        ;;
    odroid-c1)
        serialdev=ttyS0
        baudrate=115200
        ;;
    *)
        echo "[ERROR] Unsupported board."
        exit 1
        ;;
esac

# Enable getty
echo "[INFO] Enable service in $ROOT_MOUNTPOINT/etc/systemd/system/getty.target.wants/serial-getty@${serialdev}.service ..."
if [ -f $ROOT_MOUNTPOINT/etc/systemd/system/getty.target.wants/serial-getty@${serialdev}.service ]; then
    echo "[WARN] $ROOT_MOUNTPOINT/etc/systemd/system/getty.target.wants/serial-getty@${serialdev}.service already exists."
else
    mkdir -p $ROOT_MOUNTPOINT/etc/systemd/system/getty.target.wants
    ln -sf $ROOT_MOUNTPOINT/lib/systemd/system/serial-getty@.service $ROOT_MOUNTPOINT/etc/systemd/system/getty.target.wants/serial-getty@${serialdev}.service
fi

# Empty password for root
echo "[INFO] Set no pass in $ROOT_MOUNTPOINT/etc/shadow"
if [ -f $ROOT_MOUNTPOINT/etc/shadow ]; then
    sed -i 's%^root:\*:%root::%' $ROOT_MOUNTPOINT/etc/shadow
else
    echo "[WARN] $ROOT_MOUNTPOINT/etc/shadow doesn't exist."
fi
echo "[INFO] Set no pass in $ROOT_MOUNTPOINT/etc/passwd"
if [ -f $ROOT_MOUNTPOINT/etc/passwd ]; then
    sed -i 's%^root:x:%root::%' $ROOT_MOUNTPOINT/etc/passwd
else
    echo "[WARN] $ROOT_MOUNTPOINT/etc/shadow doesn't exist."
fi

echo "[INFO] Serial configuration done."
echo "[INFO] Make sure you use baudrate=$baudrate in your terminal emulator tool. Ex: minicom."
echo "[NOTE] If your using a development image make you sure you use baudrate=115200"

#
# TODO - kernel console
#

sync
