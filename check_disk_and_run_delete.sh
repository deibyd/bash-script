#!/bin/bash
# by deibyd (20200625)	: script que notifica cuando queda poco espacio en el disco
#			: aplica la contingencia según la lista en el segundo parametro entregado
# by deibyd (20200704)	: se agrega script que notifica a pushover de tal manera que pueda ser atendida la alarma
# by deibyd (20200827)	: se agrega un umbral de criticidad
#			: se agrega getopts

MAILS=noc@onemarketer.cl
#MAILS=dlopez@onemarketer.cl
#WARNING_THRESHOLD=700000
#CRITICAL_THRESHOLD=500000


function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function usage() {
	write_log "ERROR: parametros incorrectos"
	write_log "USO: ./$(basename $0) -a <valor del umbral para warning> -b <valor del umbral para critical> -c <paritcion a monitorear> -d <lista de archivos o carpetas a volcar>"
	write_log "EJEMPLO: ./$(basename $0) -a 700000 -b 500000 -c /dev/dm-0 {-d \"/var/log/tomcat7/ /var/log/apache2/\"}"
	exit 78
}

while getopts ":a:b:c:d:" OPTION; do
	case $OPTION in
	a) WARNING_THRESHOLD=$OPTARG ;;
	b) CRITICAL_THRESHOLD=$OPTARG ;;
	c) PARTITION=$OPTARG ;;
	d) LIST_PATH_OR_FILE=$OPTARG ;;
	*) usage;;
	esac
done

if [ -z "${WARNING_THRESHOLD}" ] || [ -z "${CRITICAL_THRESHOLD}" ] || [ -z "${PARTITION}" ]; then
	usage
fi

IFS=' ' read -r -a FILES_ARRAY <<< $LIST_PATH_OR_FILE

if [ ! -z $FILES_ARRAY ];then
	CONTINGENCY=" - contingencia aplicada"
	CONTINGENCY_HTML="<br><br><strong>contingencia aplicada</strong>"
fi

function get_space_left() {
	echo $(df | grep "$1" | awk '{print $4}')
}

function overturn_the_files() {
	ARRAY="$1"
	if [ ! -z $ARRAY ];then
		for _path in "${ARRAY[@]}";do
			echo "find $_path -type f| while read f; do echo "" > $f; done"
		done
	fi
}

function send_mail() {
	SUBJECT_MESSAGE="[$1] DISK ALERT: check $(hostname) - ${SPACE}kB"
	ECHO_MESSAGE="<br><strong>$1:</strong> Queda poco espacio en <strong>$2</strong> de la maquina <strong>$(hostname)<br>Resultado de la contingencia aplicada:<br>Espacio disponible anterior: <strong>${SPACE}kB</strong><br>Espacio disponible actual: <strong>${NEW_SPACE}kB</strong><br>Se recupera: <strong>$(echo "$SPACE-$NEW_SPACE"|bc)kB</strong><br><br>Nota: Si el resultado es cero, el script no tiene el parametro de archivos a volcar.";
	echo "$ECHO_MESSAGE" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
}

for i in $(df|awk '{print $1}'|grep "^\/")
do
	if [ $PARTITION == "$i" ];then
		SPACE=$(get_space_left "$i")
		if [ $SPACE -gt $CRITICAL_THRESHOLD ] && [ $SPACE -le $WARNING_THRESHOLD ];then
			overturn_the_files $FILES_ARRAY
			NEW_SPACE=$(get_space_left "$i")
			send_mail "WARNING" $i $NEW_SPACE
			write_log "WARNING: Queda poco espacio (${SPACE}kB) en $i. Se aplica contingencia (${NEW_SPACE}kB). Notificacion enviada por correo";
		elif [ $SPACE -le $CRITICAL_THRESHOLD ];then
			
			overturn_the_files $FILES_ARRAY
			send_mail "CRITICAL" $i 
			/home/hydefus/script/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "CRITICAL: Quedaba poco espacio (${SPACE}kB) en $i de la maquina $(hostname)" -p2  -s spacealarm -r 30 && echo ""
			write_log "CRITICAL: Queda poco espacio (${SPACE}kB) en $i. Notificacion enviada por correo y pushover";
		else
			write_log "OK: Queda espacio (${SPACE}kB es mayor a ${WARNING_THRESHOLD}kB) en $i de la maquina $(hostname)";
		fi
	else
		write_log "NOTICE: nada que hacer en $i porque no es la particion a monitorear ($PARTITION)"
	fi
done

