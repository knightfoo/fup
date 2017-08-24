#!/bin/sh 

sysctl kern.geom.debugflags=16

freebsd-boot() {
	gpart show -p | awk '/freebsd-boot/{ print $3 };' | while read dysk;
	do
		echo "Disk $dysk"
		d_=$(echo $dysk|sed 's/\(.*\)p./\1/')
		i_=$(echo $dysk|sed 's/.*\(.\)$/\1/')
		echo "$d_ - $i_"
	done
}	

change-bootfs-size() {
	gpart show -p | awk '/freebsd-boot/{ print $3 };' | while read dysk;
	do
		d_=$(echo $dysk|sed 's/\(.*\)p./\1/')
		b_i=$(echo $dysk|sed 's/.*\(.\)$/\1/')
		gpart show -p $d_ | awk '/freebsd-swap/{ print $3 };' | while read s_dysk;
		do	
			s_i=$(echo $s_dysk|sed 's/.*\(.\)$/\1/')
			if [ $s_i -eq 2 ];
			then
				echo "Disk: $d_ --- bootfs: $b_i --- swap: $s_i"
				gpart delete -i $s_i $d_
				gpart resize -i $b_i -s 512K $d_
				gpart add -t freebsd-swap $d_
				gpart bootcode -p /boot/gptzfsboot -b /boot/pmbr -i $b_i $d_

			fi				
		done				
	done
}	

destroy-gmirror() {
	echo "Destroing gmirror on $1"
	d=$(echo $1|awk -F '/' '{print $4}')
	echo "gmirror destroy $d"
	if gmirror destroy $d > /dev/null 2>&1;
	then
		return 0
	else 
		return 1	
	fi	

}

create-gmirror-swap() {
	ile=0
	swap_count=$(gpart show -p | grep 'freebsd-swap' | wc -l)
	spans=$((${swap_count}/2))
	span=0
	dyski=""
	gmirror load

	gpart show -p | grep 'freebsd-swap' |awk '{print $3}' | while read dysk;
	do
		if [ $ile -lt 2 ];
		then
			ile=$((${ile}+1))
			dyski="$dyski /dev/$dysk"
		else
			span=$((${span}+1))
			ile=1
			dyski=""
			dyski="$dyski /dev/$dysk"
		fi
		
		[ ${ile} -eq 2 ] && (echo "Creating: gmirror label -v -b round-robin -h swap${span} $dyski"; gmirror label -v -b round-robin -h swap${span} $dyski; swapon /dev/mirror/swap${span} )
	done		

}

swap() {

	if swapinfo | egrep -v 'Total|Device' > /dev/null 2>&1;
	then	
		swapctl -l | grep dev | awk '{print $1}'| while read swap_dev;
		do
			if echo $swap_dev | egrep '/mirror/|/label/' 1> /dev/null 2> /dev/null;
			then
				if ! swapoff $swap_dev 1> /dev/null 2> /dev/null;
				then
					echo "The Swap did not turn on"
					exit 
				else
					echo "Swap - $swap_dev - disabled."	
					destroy-gmirror	$swap_dev
					echo $?
					#freebsd-swap
				fi
			elif echo $swap_dev | grep '/dev/' > /dev/null 2>&1;
			then				
				echo "Bez mirrora"				
			else
				echo "Mirrora brak"	
			fi
		done
	else
		echo "There is no swap, let's create it"
		create-gmirror-swap
		#swapon /dev/mirror/swap0
		#swapon /dev/mirror/swap1	
		swapinfo
	fi	
}

# Wylaczam swap
if [ "$1" == "swap" ];
then
	swap
else	
	swap
	change-bootfs-size
	create-gmirror-swap
fi	

sysctl kern.geom.debugflags=0
