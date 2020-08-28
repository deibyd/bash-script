#!/bin/bash
# by deibyd (20200828) : script que notifica cuando aparece una excepcion en el log

HOME_SCRIPT_PATH=/home/hydefus/script

MAILS=max@psychoworld.cl,noc@onemarketer.cl

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function usage() {
	write_log "ERROR: parametros incorrectos"
	write_log "USO: ./$(basename $0) -a <archivo_de_log> -b <archivo_con_la_lista_de_excepciones>"
	write_log "EJEMPLO: ./$(basename $0) -a /var/log/tomcat7/catalina.out -b /home/hydefus/dlopez/script/list_exception_tomcat_log.txt"
	exit 78
}

while getopts ":a:b:" OPTION; do
	case $OPTION in
	a) LOG_FILE=$OPTARG ;;
	b) LIST_EXCEPTION_FILE=$OPTARG ;;
	*) usage;;
	esac
done

if [ -z "${LOG_FILE}" ] || [ -z "${LIST_EXCEPTION_FILE}" ]; then
	usage
fi

if [ -f $LIST_EXCEPTION_FILE ] && [ -s $LIST_EXCEPTION_FILE ];then
        while read -r line; do
                PATRON="$line|$PATRON"
        done < $LIST_EXCEPTION_FILE
else
	write_log "ERROR: No existe o esta vacio el archivo $LIST_EXCEPTION_FILE"
	exit 45
fi

PATRON=$(echo "$PATRON"|sed 's/|$//g')

CANTIDAD_ERRORES=$(tail -n 10000 $LOG_FILE|grep "$PATRON"|wc -l)
THE_LAST_ROW=$(tail -n 10000 $LOG_FILE|grep "$PATRON"|grep -v "^#"|tail -n 5|sed 's/^/=> /g'|sed 's/$/<br>/g')

RESPONSE="OK: No se encuentran errores segun el patron ($PATRON) en el archivo $LOG_FILE"
CODIGO=0

if [ "$CANTIDAD_ERRORES" -gt "0" ]; then
	SUBJECT_MESSAGE="[CRITICAL] TOMCAT ALERT: check $(hostname)"
	RESPONSE_HTML="<br>Se han encontrado <strong>$CANTIDAD_ERRORES</strong> errores en el archivo <strong>$LOG_FILE</strong>"
	RESPONSE="Se han encontrado $CANTIDAD_ERRORES errores en el archivo $LOG_FILE"
	CODIGO=2
	echo "$RESPONSE_HTML<br><br><strong>Ultimos errores encontrados:</strong><br>$THE_LAST_ROW" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$RESPONSE" -p2  -s spacealarm -r 30
fi

write_log "$RESPONSE"
exit $CODIGO

