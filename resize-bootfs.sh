#!/bin/sh  


freebsd-boot() {
	gpart show -p | awk '/freebsd-boot/{ print $3 };' | while read dysk;
	do
		echo "Dysk $dysk"
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
				echo "Dysk: $d_ --- bootfs: $b_i --- swap: $s_i"

			fi				
		done				
	done
}	

destroy-gmirror() {
	echo "Rozpinam gmirror na $1"
	d=$(echo $1|awk -F '/' '{print $4}')
	echo "gmirror destroy $d"
	if gmirror destroy $d > /dev/null 2>&1;
	then
		return 0
	else 
		return 1	
	fi	

}


create-gmirror() {
	gmirror label -h swap0 /dev/da0p2 /dev/da1p2
	gmirror label -h swap1 /dev/da2p2 /dev/da3p2

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
					echo "Swap sie nie wylaczyl"
					exit 
				else
					echo "Swap - $swap_dev - wylaczony. Przerabiamy ...."	
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
		echo "Swapu brak wiec go tworze"
		create-gmirror
		swapon /dev/mirror/swap0
		swapon /dev/mirror/swap1	
		swapinfo
	fi	
}

#swap
change-bootfs-size
