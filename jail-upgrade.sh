#!/bin/sh

jls -N | grep -v 'JID' | while read j_;
do
	j_name=$(echo $j_|awk '{print $1}')
	j_path=$(echo $j_|awk '{print $4}')
	echo "$j_name - $j_path"
done
