#!/bin/sh -x

version=$1
pool=tank0
ftp_url="ftp://ftp.icm.edu.pl/pub/FreeBSD/releases/amd64/${version}-RELEASE"

cur_ver=$(uname -r | awk -F '-' '{print $1}')
cur_bootfs=$(zpool get -H bootfs ${pool} |  awk '{print $3}')


if [ -z "$*" ]; 
then 
	echo "Which FreeBSD version?" 
	exit
fi

#ver=$(echo $version | sed 's#\.#_#')
ver=$version

echo "Does dataset exists?"
if ! zfs list -H ${pool}/ROOT/base${ver} 1> /dev/null 2> /dev/null;
#if [ $? -eq 1 ];
then
	echo "Creating dataset"
	zfs create -o canmount=noauto -o mountpoint=/ ${pool}/ROOT/base${ver}
	mount -t zfs ${pool}/ROOT/base${ver} /mnt
else
	echo "Dataset exists, check ..."
	exit
fi	

echo "Fetching and extracting FreeBSD packages"
for pkg in base.txz kernel.txz;
do
	echo $pkg
	fetch -o - ${ftp_url}/${pkg} | tar xpf - -C /mnt 

done	

echo "Copying files"
for plik in /etc/rc.conf /etc/rc.conf.local /etc/rc.conf.d/* /boot/loader.conf /etc/passwd /etc/group /etc/master.passwd /etc/sysctl.conf /etc/login.conf /etc/fstab /etc/ssh/sshd_config;
do
	cp ${plik} /mnt${plik}

done	

chroot /mnt pwd_mkdb /etc/master.passwd	

#cp -r /dev/* /mnt/dev/
cp -r /root/* /mnt/root/
<<<<<<< HEAD
#cp -r /usr/home/* /mnt/usr/home/*
=======
#cp -r /home/* /mnt/home/*
>>>>>>> 8d070ccc1395e85bc04dc680f33855472143e7a6


zpool set bootfs=${pool}/ROOT/base${ver} ${pool}
umount /mnt

zfs set canmount=noauto ${cur_bootfs} ${pool}

# gdy home jest na datasecie
# zfs create tank0/home && zfs set mountpoint /usr/home tank0/home && ln -s /usr/home /home

# bootcode 
# gpart bootcode -b /mnt/boot/pmbr -p /mnt/boot/gptzfsboot -i 1 ${DYSK}1

