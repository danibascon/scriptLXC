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

	while [ $(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 2) = 'STOPPED' ] ;do
		lxc-start -n $host
	done
	if [[ host='maq1' ]] ;then
		var = $host
	fi
	lxc-device -n $host add /dev/mapper/BASCON-disco
	lxc-attach -n $host-- mount /dev/mapper/BASCON-disco /var/www/html
	ip= $(lxc-ls -f | grep maq1 | tr -s " " | cut -d " " -f 5)
	if [[ $host == 'maq2' ]] ;then
		iptables -t nat -D PREROUTING `iptables -t nat -L --line-number | egrep $ip | cut -d " " -f 1`
		lxc-device -n $var add /dev/mapper/BASCON-disco
		lxc-attach -n $var -- mount /dev/mapper/BASCON-disco /var/www/html
	fi
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip:80
	echo 'Momento de comprobación'
done









