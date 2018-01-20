#!/bin/bash

for (( i=1 ; i<3 ; i++ )) ;do
	case $i in
		1)
			host='maq1'
			num=157286
			comentario='Procedemos a realizar la migración'
			;;
		2)
			host='maq2'
			num=314572
			comentario='Procedemos a aumentar la RAM'		
			;;
	esac
	echo "arrancado $host"
	while [ $(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 2) = 'STOPPED' ] ;do
		lxc-start -n $host
		ip=''
	done
	while [ ip != $(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 5 |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}') ] ;do
		echo 'obteniendo ip'
		ip=$(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 5)
	done
	echo "ip obtenida: $ip"
	if [[ host='maq1' ]] ;then
		var=$host
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
	echo 'añadiendo volumen logico'
	lxc-device -n $host add /dev/mapper/BASCON-disco
	lxc-attach -n $host -- mount /dev/mapper/BASCON-disco /var/www/html
	lxc-attach -n $host -- systemctl restart apache2
	echo 'añadiendo regla iptable'
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip:80
	echo 'Momento de comprobación'
	read 
	while [ $(lxc-attach -n $host -- free | grep Mem | tr -s " " | cut -d " " -f 4) -lt $num ] ;do
		echo 'El consumo de RAM no ha superado el 70% de su capacidad'
		sleep 3s
	done
	echo 'El consumo de RAM a susperado al 70%'
	echo $comentario
	if [[ $host == 'maq2' ]] ;then
		lxc-cgroup -n $host memory.limit_in_bytes 2000M
		echo 'Se ha amuntado la RAM'
		echo 'Comprobación'
		read
	fi
done
iptables -t nat -D PREROUTING `iptables -t nat -L --line-number | egrep $ip | cut -d " " -f 1`
lxc-stop -n $host


#					stress -d 1 --vm-bytes 512M --timeout 10
#					stress -d 1 --vm-bytes 1024 --timeout 10
