#!/bin/sh


jail-upgrade() {
	name_=$1
	path_=$2

	echo "freebsd-update -b ${path_} --currently-running 10.3-RELEASE -r 11.1-RELEASE upgrade"

}

jls -N | grep -v 'JID' | while read j_;
do
	j_name=$(echo $j_|awk '{print $1}')
	j_path=$(echo $j_|awk '{print $4}')
	echo "$j_name - $j_path"
	#jail-upgrade ${j_name} ${j_path}
done
