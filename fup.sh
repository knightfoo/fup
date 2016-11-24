#!/bin/sh

version=$1
pool=tank0
ftp_url="ftp://ftp.icm.edu.pl/pub/FreeBSD/releases/amd64/10.3-RELEASE"

if [ -z "$*" ]; 
then 
	echo "Jaka wersja?" 
	exit
fi

# wycinam kropke z wersji, zeby dataset stworzyc odpowiedni
ver=$(echo $version | tr -d '.')

echo "Czy dataset istnieje?"
zfs list -H ${pool}/ROOT/base${ver}

if [ $? -eq 1 ];
then
	echo "Nie istnieje tworze"
	zfs create -o mountpoint=/storage/ROOT/base${ver} ${pool}/ROOT/base${ver}
else
	echo "Istnieje sprawdz to"
	exit
fi	

echo "Pobieram co potrzebne"
for pkg in base.txz kernel.txz;
do
	echo $pkg
	#fetch -o - ${ftp_url}/${pkg} | tar xpf - -C /storage/ROOT/base${ver} 
done	

echo "Kopiuje wymagane pliki"
for plik in /etc/rc.conf /etc/rc.conf.local /etc/rc.conf.d/* /boot/loader.conf /etc/passwd /etc/group /etc/master.passwd /etc/sysctl.conf /etc/login.conf;
do
	echo "cp ${plik} /storage/ROOT/base${ver}${plik}"
done	

