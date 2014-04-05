#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ $(uname -n) == "raspberrypi" ]]; then
  USER=pi
  NAME=2014-01-07-wheezy-raspbian
  IMAGE_FILE=2014-01-07-wheezy-raspbian.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.zip
  IMAGE_URL="http://downloads.raspberrypi.org/raspbian_latest -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
  BOARD=raspberrypi
elif [[ $(uname -n) == "arm" ]]; then
  USER=ubuntu
  IMAGE_FILE=BBB-eMMC-flasher-ubuntu-13.10-2014-02-16-2gb.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  IMAGE_URL=https://rcn-ee.net/deb/flasher/saucy/$IMAGE_FILE_ZIP
  UNZIP=unxz
  BOARD=beagleboneblack
fi

GIT_URL=https://github.com/syncloud/owncloud-setup
REV_FILE=.revision
LATEST_REV=$(git ls-remote $GIT_URL refs/heads/master | cut -f1)
if [ -f $REV_FILE ]; then
  CURRENT_REV=$(<$REV_FILE)
  if [ "$CURRENT_REV" == "$LATEST_REV" ]; then
    echo "No changes since last check"
    exit 1
  fi
fi

apt-get install xz-utils git makeself

rm -rf owncloud-setup
git clone https://github.com/syncloud/owncloud-setup
cd owncloud-setup
git rev-parse HEAD > ../$REV_FILE
SYNCLOUD_IMAGE=syncloud-$BOARD-$(date +%F-%H-%M-%S)-$(git rev-parse --short HEAD).img
./build.sh
cd ..

if [ ! -f $IMAGE_FILE ]; then
  wget $IMAGE_URL
  $UNZIP $IMAGE_FILE_ZIP
fi

cp $IMAGE_FILE $SYNCLOUD_IMAGE
STARTSECTOR=$(file $SYNCLOUD_IMAGE | grep -oP 'partition 2.*startsector \K[0-9]*(?=, )')
losetup -o $(($STARTSECTOR*512)) /dev/loop0 $SYNCLOUD_IMAGE
mkdir image
chmod 700 image
mount /dev/loop0 image
#sudo mount --bind /dev image/dev
#sudo mount --bind /proc image/proc
mkdir image/run/resolvconf
cp /run/resolvconf/resolv.conf image/run/resolvconf/resolv.conf
cp owncloud-setup/syncloud_setup.sh image/home/$USER

chroot image
if [ $? -ne 0 ]; then
  echo "unable to chroot into image"
  exit 1 
fi

cd /home/$USER

rm -rf /var/cache/apt/archives/*.deb
rm -rf /opt/Wolfram

./syncloud_setup.sh

/etc/init.d/minissdpd stop

exit
#umount image/proc
#umount image/dev
umount image
rm -rf image
losetup -d /dev/loop0

xz -z0 $SYNCLOUD_IMAGE
