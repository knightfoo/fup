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
for plik in /etc/rc.conf /etc/resolv.conf /etc/rc.conf.local /etc/rc.conf.d/* /boot/loader.conf /etc/passwd /etc/group /etc/master.passwd /etc/sysctl.conf /etc/login.conf /etc/fstab /etc/ssh/sshd_config;
do
	cp ${plik} /mnt${plik}

done

if grep 'vfs.root.mountfrom' /mnt/boot/loader.conf > /dev/null 2>&1;
then
        sed -i.bck 's#vfs.root.mountfrom#\#vfs.root.mountfrom#g' /mnt/boot/loader.conf
fi


chroot /mnt pwd_mkdb /etc/master.passwd	

#cp -r /dev/* /mnt/dev/
cp -r /root/* /mnt/root/
cp -r /root/.[a-z]* /mnt/root/
#cp -r /usr/home/* /mnt/usr/home/*

#if zfs list -H 

zpool set bootfs=${pool}/ROOT/base${ver} ${pool}
#umount /mnt


gpart show -p | awk '/freebsd-boot/{ print $3 };' | while read dysk;
do
    echo "Dysk $dysk"
    d_=$(echo $dysk|sed 's/\(.*\)p./\1/')
    i_=$(echo $dysk|sed 's/.*\(.\)$/\1/')
    echo "$d_ - $i_"
    gpart bootcode -b /mnt/boot/pmbr -p /mnt/boot/gptzfsboot -i ${i_} ${d_}
done
            

# gdy home jest na datasecie
if [ zfs list -H ${pool}/home 1> /dev/null 2> /dev/null  ||  zfs list -H ${pool}/usr/home > /dev/null 2>&1 ];
then
    echo "dataset home exists"
    zfs set mountpoint=/usr/home ${pool}/home
    chroot /mnt ln -s /usr/home /home
fi    

# zfs create tank0/home && zfs set mountpoint /usr/home tank0/home && ln -s /usr/home /home


#umount /mnt
if [ ${cur_bootfs} ];
then
    zfs set mountpoint=legacy ${cur_bootfs}
    zfs set canmount=noauto ${cur_bootfs} ${pool}
fi    
