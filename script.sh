#!/bin/bash



for (( i=1 ; i<3 ; i++ )) ;do
	case $i in
		1)
			host='maq1'
			;;
		2)
			host='maq2'
			;;
	esac

	do
		lxc-start -n $host
		while [[ $estado == 'STOPPED' ]] 
			estado= $(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 2)










done

































































































