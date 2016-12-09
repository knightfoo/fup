#!/bin/sh -x

version=$1
pool=tank0
ftp_url="ftp://ftp.icm.edu.pl/pub/FreeBSD/releases/amd64/${version}-RELEASE"

cur_ver=$(uname -r | awk -F '-' '{print $1}')
cur_bootfs=$(zpool get all ${pool} | grep bootfs | awk '{print $3}')


if [ -z "$*" ]; 
then 
	echo "Which FreeBSD version?" 
	exit
fi

# wycinam kropke z wersji, zeby dataset stworzyc odpowiedni
ver=$(echo $version | tr -d '.')

echo "Is dataset exists?"
if ! zfs list -H ${pool}/ROOT/base${ver} 1> /dev/null 2> /dev/null;
#if [ $? -eq 1 ];
then
	echo "Nie istnieje tworze"
	#zfs create -o mountpoint=/storage/ROOT/base${ver} ${pool}/ROOT/base${ver}
	zfs create -o canmount=noauto -o mountpoint=/ ${pool}/ROOT/base${ver}
	mount -t zfs ${pool}/ROOT/base${ver} /mnt
else
	echo "Istnieje sprawdz to"
	exit
fi	

echo "Pobieram co potrzebne"
for pkg in base.txz kernel.txz;
do
	echo $pkg
	#fetch -o - ${ftp_url}/${pkg} | tar xpf - -C /storage/ROOT/base${ver} 
	fetch -o - ${ftp_url}/${pkg} | tar xpf - -C /mnt 

done	

echo "Kopiuje wymagane pliki"
for plik in /etc/rc.conf /etc/rc.conf.local /etc/rc.conf.d/* /boot/loader.conf /etc/passwd /etc/group /etc/master.passwd /etc/sysctl.conf /etc/login.conf /etc/fstab /etc/ssh/sshd_config;
do
	#cp ${plik} /storage/ROOT/base${ver}${plik}
	cp ${plik} /mnt${plik}

done	

chroot /mnt pwd_mkdb /etc/master.passwd	

cp -r /dev/* /mnt/dev/
cp -r /root/* /mnt/root/
cp -r /home/* /mnt/home/*


zpool set bootfs=${pool}/ROOT/base${ver} ${pool}
umount /mnt

zfs set canmount=noauto ${cur_bootfs} ${pool}


