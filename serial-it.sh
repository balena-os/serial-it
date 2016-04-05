#!/bin/bash

set -e

mountpoint=/run/media/andrei/resin-root

cp ./over/etc/systemd/system/getty.target.wants/serial-getty@ttyAMA0.service $mountpoint/etc/systemd/system/getty.target.wants/serial-getty@ttyAMA0.service
cp ./over/lib/systemd/system/serial-getty@.service $mountpoint/lib/systemd/system/serial-getty@.service
sync
