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
	if [[ $host == 'maq2' ]] ;then
		lxc-attach -n $var -- umount /dev/mapper/BASCON-disco /var/www/html		
		lxc-device -n $var del /dev/mapper/BASCON-disco
		lxc-stop -n $var
		lvresize -L +50M /dev/BASCON/disco
		mount /dev/BASCON/disco /mnt/
		xfs_growfs /dev/BASCON/disco 
		umount /mnt/
		iptables -t nat -D PREROUTING `iptables -t nat -L --line-number | egrep $ip | cut -d " " -f 1`
	fi
	lxc-device -n $host add /dev/mapper/BASCON-disco
	lxc-attach -n $host -- mount /dev/mapper/BASCON-disco /var/www/html
	ip= $(lxc-ls -f | grep maq1 | tr -s " " | cut -d " " -f 5)
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip:80
	echo 'Momento de comprobación'
	read 

	while [ $(lxc-attach -n maq1 -- free | grep Mem | tr -s " " | cut -d " " -f 4) -lt 157286 ] ;do
		echo 'El consumo de RAM no ha superado el 70% de su capacidad'
		sleep 3s


	echo 'El consumo de RAM a susperado al 70%'
	echo 'Procedemos la migración'
done


#					stress -d 1 --vm-bytes 512M --timeout 10
#					stress -d 1 --vm-bytes 1024 --timeout 10
