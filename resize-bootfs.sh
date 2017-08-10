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

freebsd-swap() {
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


}

swap() {

	if swapinfo | grep dev > /dev/null 2>&1;
	then	
		swapctl -l | grep dev | awk '{print $1}'| while read swap_dev;
		do
			if echo $swap_dev | grep '/mirror/' 1> /dev/null 2> /dev/null;
			then
				echo "Mirror !!!"
				if ! swapoff -a 1> /dev/null 2> /dev/null;
				then
					echo "Swap sie nie wylaczyl"
					exit 
				else
					echo "Swap wylaczony. Przerabiamy ...."	
					echo $swap_dev
					destroy-gmirror	
					#freebsd-swap
				fi
			else
				echo "Swapu brak"	
			fi
		done
	else
		echo "Swapu brak"
		swapon -a	
	fi	
}

swap
