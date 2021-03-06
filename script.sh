#!/bin/bash

for (( i=1 ; i<3 ; i++ )) ;do
#definimos las dos máquinas, el tope de la ram y un comentario final
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
			var='maq1'
			;;
	esac
#en esta parte desmontaremos el volumen, quitaremos la egla iptable y redimensionaremos el volumen
	if [[ $host == 'maq2' ]] ;then
		echo "Desmontamos el volumen de $var"
		lxc-attach -n $var -- umount /dev/mapper/BASCON-disco		
		lxc-device -n $var del /dev/mapper/BASCON-disco
		lxc-stop -n $var
		echo 'redimensionamos el volumen'
		lvresize -L +50M /dev/BASCON/disco
		mount /dev/BASCON/disco /mnt/
		xfs_growfs /dev/BASCON/disco 
		umount /mnt/
		iptables -t nat -D PREROUTING `iptables -t nat -L --line-number | egrep $ip | cut -d " " -f 1`
		sleep 2s
		clear
	fi
#arrancamos la maquina
	echo "arrancado $host"
	while [ $(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 2) = 'STOPPED' ] ;do
		lxc-start -n $host
		ip=''
	done
#obtenimos la ip de la maquina	
	while [ "$ip" !=  echo $(echo "$ip" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}') ] ;do
		echo 'obteniendo ip'
		sleep 3s
		ip="$(lxc-ls -f | grep $host | tr -s " " | cut -d " " -f 5)"
	done
	clear
	echo "ip obtenida: $ip"
#añadimos el volumen logico y reiniciamos
	echo 'añadiendo volumen logico'
	lxc-device -n $host add /dev/mapper/BASCON-disco
	lxc-attach -n $host -- mount /dev/mapper/BASCON-disco /var/www/html
	lxc-attach -n $host -- systemctl restart apache2
#añadimos la regla iptable
	echo 'añadiendo regla iptable'
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip:80
	echo 'Momento de comprobación'
	read 
#control sobre el uso de memoria ram	
	while [ $(lxc-attach -n $host -- free | grep Mem | tr -s " " | cut -d " " -f 4) -ge $num ] ;do
		echo 'El consumo de RAM no ha superado el 70% de su capacidad'
		sleep 3s
	done
	echo 'El consumo de RAM a susperado al 70%'
	echo $comentario
#aumento de la ram en vivo
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