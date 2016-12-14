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

ver=$(echo $version | sed 's#\.#_#')

echo "Does dataset exists?"
if ! zfs list -H ${pool}/ROOT/basefs${ver} 1> /dev/null 2> /dev/null;
#if [ $? -eq 1 ];
then
	echo "Creating dataset"
	zfs create -o canmount=noauto -o mountpoint=/ ${pool}/ROOT/basefs${ver}
	mount -t zfs ${pool}/ROOT/basefs${ver} /mnt
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

cp -r /dev/* /mnt/dev/
cp -r /root/* /mnt/root/
cp -r /home/* /mnt/home/*


zpool set bootfs=${pool}/ROOT/basefs${ver} ${pool}
umount /mnt

zfs set canmount=noauto ${cur_bootfs} ${pool}


