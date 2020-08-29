#!/bin/bash
# by deibyd (20200828) : script que notifica cuando el peso de una tabla pasa el umbral

HOME_SCRIPT_PATH=/home/hydefus/script

MAILS=max@psychoworld.cl,kp6mefsp1d@pomail.net,noc@onemarketer.cl

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function usage() {
	write_log "ERROR: parametros incorrectos"
	write_log "USO: ./$(basename $0) -a <umbral de peso> -b <tabla>"
	write_log "EJEMPLO: ./$(basename $0) -a 50 -b loginlog"
	exit 78
}

while getopts ":a:b:" OPTION; do
	case $OPTION in
	a) UMBRAL=$OPTARG ;;
	b) TABLE=$OPTARG ;;
	*) usage;;
	esac
done

if [ -z "${UMBRAL}" ] || [ -z "${TABLE}" ]; then
	usage
fi

SIZE_TABLE=$(mysql -u root -psandermaster -D wa -A -Ns -e "SELECT ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024) AS \`Size (MB)\` FROM information_schema.TABLES WHERE TABLE_SCHEMA = \"wa\" and TABLE_NAME in ('$TABLE') ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;" 2>/dev/null)

RESPONSE="OK: El peso de la tabla $TABLE esta segun lo esperado (${SIZE_TABLE}MB)"
CODIGO=0

if [ $SIZE_TABLE -gt $UMBRAL ];then
	SUBJECT_MESSAGE="[CRITICAL] TABLE ALERT: $TABLE (${SIZE_TABLE}MB) - $(hostname)"
        RESPONSE_MESSAGE="<br><strong>CRITICAL:</strong> El tamaño de la tabla <strong>$TABLE</strong> es de <strong>${SIZE_TABLE}MB</strong> - <strong>$(hostname)</strong>"
        RESPONSE="CRITICAL: El tamaño de la tabla $TABLE es de ${SIZE_TABLE}MB - $(hostname)"
        echo "$RESPONSE_MESSAGE" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$RESPONSE" -p2  -s spacealarm -r 30
	CODIGO=2
fi

write_log "$RESPONSE"
exit $CODIGO
