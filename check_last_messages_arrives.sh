#!/bin/bash
# by deibyd (20200903) : script que chequea si un proceso esta vivo. Primero inspecciona si el proceso esta arriba, si lo esta, entonces, mira si el log tiene movimiento.

HOME_SCRIPT_PATH=/home/hydefus/script
MAILS=noc@onemarketer.cl
TABLE="<html><head><style>table, th, td {border: 1px solid black;}</style></head><table><tr><th>context</th><th>nombre</th><th>service</th><th>segundos</th><th>estado</th><th>nota</th></tr>"
SEND_MAIL="false"
IS_PUSHOVER="false"
SUBJECT_MESSAGE="[ALERT] SENT MESSAGES: check $(hostname)"

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function usage() {
	write_log "ERROR: parametros incorrectos"
	write_log "USO: ./$(basename $0) -a <warning en segundos> -b <critical en segundos> -c <usuario de la base de datos> -d <password de la base de datos> -e <ip de la base de datos>"
	write_log "EJEMPLO: ./$(basename $0) -a 1800 -b 900 -c root -d sandermaster -e 127.0.0.1"
}

function get_databases() {
        local RESPONSE=()
        while read line
        do
                RESPONSE+=("$line")
        done < <( mysql -u${DATA_BASE_USER} -p${DATA_BASE_PASSWORD} -h${DATA_BASE_IP} wa -BNs -e "$QUERY" 2>/dev/null )

        echo ${RESPONSE[*]}
}

while getopts ":a:b:c:d:e:" OPTION; do
	case $OPTION in
	a) WARNING=$OPTARG ;;
	b) CRITICAL=$OPTARG ;;
	c) DATA_BASE_USER=$OPTARG ;;
	d) DATA_BASE_PASSWORD=$OPTARG ;;
	e) DATA_BASE_IP=$OPTARG ;;
	*) 
		usage
		exit 70
		;;
	esac
done

if [ -z "${WARNING}" ] || [ -z "${CRITICAL}" ] || [ -z "${DATA_BASE_USER}" ] || [ -z "${DATA_BASE_PASSWORD}" ] || [ -z "${DATA_BASE_IP}" ]; then
	usage
	exit 69
fi

function send_mail() {
	ECHO_MESSAGE="<strong>ALERTA:</strong> Hay servicios que no han enviado mensajes dentro de los umbrales definidos.<br><br>$1<br>Los umbrales definidos son:<br><strong>warning:</strong> $WARNING[s]<br><strong>critical:</strong> $CRITICAL[s]";
	echo "$ECHO_MESSAGE" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
}

EXCEPTION=""

if [ -f $HOME_SCRIPT_PATH/exception_to_check_last_messages_arrives.txt ];then
	EXCEPTION=$(grep "$(hostname)" $HOME_SCRIPT_PATH/exception_to_check_last_messages_arrives.txt)
fi

IFS='|' read -ra HOSTNAME_EXCEPTION <<< "$EXCEPTION"

for event in "${HOSTNAME_EXCEPTION[@]}"; do
	if [ $(echo "$event"|grep -c ",") -gt 0 ];then
		IFS=',' read -ra FILTERS <<< "$event"
		APPEND_WHERE="and (c.id_context!=${FILTERS[0]} or c.idservice!=${FILTERS[1]}) "$APPEND_WHERE
	fi
done

QUERY="select concat(a.id,'.*',c.id_context,'.*',c.idservice,'.*',if(c.remote=1, time_to_sec(timediff(now(), c.time)), 'NA'),'.*',a.push_name) from context a left join (select max(id) max_id, id_context, idservice from messages  group by id_context, idservice) b on b.id_context = a.id left join messages c on b.max_id = c.id where a.status in ('G', 'R') and c.remote = 1 $APPEND_WHERE;"

IFS=' ' read -ra EVENTS <<< "$(get_databases)"

for event in "${EVENTS[@]}"; do
	IFS='.*' read -ra COLUMN <<< $event
	if [ ! -z ${COLUMN[6]} ];then
		if [ ${COLUMN[6]} -gt $CRITICAL ];then
			write_log "CRTICAL: context: ${COLUMN[2]} - push_name: ${COLUMN[8]} - service: ${COLUMN[4]} - segundos: ${COLUMN[6]} tiene mas de $CRITICAL segundos"
			SEND_MAIL="true"
			IS_PUSHOVER="true"
			TABLE="$TABLE<tr><td>${COLUMN[2]}</td><td>${COLUMN[8]}</td><td>${COLUMN[4]}</td><td>${COLUMN[6]}</td><td>CRITICAL</td><td>tiene más de $CRITICAL segundos</td></tr>"
		elif [ ${COLUMN[6]} -gt $WARNING ] && [ ${COLUMN[6]} -le $CRITICAL ];then
			write_log "WARNING: context: ${COLUMN[2]} - push_name: ${COLUMN[8]} - service: ${COLUMN[4]} - segundos: ${COLUMN[6]} tiene mas de $WARNING segundos"
			SEND_MAIL="true"
			TABLE="$TABLE<tr><td>${COLUMN[2]}</td><td>${COLUMN[8]}</td><td>${COLUMN[4]}</td><td>${COLUMN[6]}</td><td>WARNING</td><td>tiene más de $WARNING segundos</td></tr>"
		else
			write_log "OK: context: ${COLUMN[2]} - push_name: ${COLUMN[8]} - service: ${COLUMN[4]} - segundos: ${COLUMN[6]} está dentro de los tiempos esperados"
			TABLE="$TABLE<tr><td>${COLUMN[2]}</td><td>${COLUMN[8]}</td><td>${COLUMN[4]}</td><td>${COLUMN[6]}</td><td>OK</td><td>está dentro de los tiempos esperados</td></tr>"
		fi
	fi
done
TABLE="$TABLE</table></html>"

if [ $SEND_MAIL == "true" ];then
	send_mail "$TABLE"
	write_log "correo enviado"
	if [ IS_PUSHOVER == "true" ];then
		#$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "CRITICAL: Hay servicios que no han enviado mensajes dentro de los umbrales definidos. Revisar correo enviado para el detalle" -p2  -s spacealarm -r 30 && echo ""
		write_log "pushover enviado"
	fi
fi

