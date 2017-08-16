#!/bin/sh   

#sysctl kern.geom.debugflags=16

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
				gpart delete -i $s_i $d_
				gpart resize -i $b_i -s 512K $d_
				gpart add -t freebsd-swap $d_
				gpart bootcode -p /boot/gptzfsboot -b /boot/pmbr -i $b_i $d_

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


create-gmirror-swap() {
	ile=0
	swap_count=$(gpart show -p | grep 'freebsd-swap' | wc -l)
	spans=$((${swap_count}/2))
	span=0
	#while [ "${span}" -lt "${spans}" ]
	#do
	#	if [ ${span} -eq 0 ]
	#	then
	#		`echo | awk -v span=${span} -v zfsparts="${ZFSPARTS}" '{ split(zfsparts,arr," "); print arr[span+span+1] " " arr[span+span+2] }'`
	#	else
	#		`echo | awk -v span=${span} -v zfsparts="${ZFSPARTS}" '{ split(zfsparts,arr," "); print arr[span+span+1] " " arr[span+span+2] }'`
        #	fi
	 #       span=$((${span}+1))
	#done


	gpart show -p | grep 'freebsd-swap' |awk '{print $3}' | while read disk;
	do
		if [ $ile -lt $spans ];
		then
			echo "$disk - ILE: $ile - $spans"
			#ile=$((${ile}+1))

		else
			#ile=1	
			echo "TU $disk - ILE: $ile - $spans"
			
		fi

	 	ile=$((${ile}+1)) 	
#		gmirror label -h swap0 /dev/da0p2 /dev/da1p2
#		gmirror label -h swap1 /dev/da2p2 /dev/da3p2
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
#change-bootfs-size
create-gmirror-swap


sysctl kern.geom.debugflags=0
