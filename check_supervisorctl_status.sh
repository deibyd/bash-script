#!/bin/bash
# by deibyd (20200722) : script que notifica si el supervisor tiene algun problema de estado

MAILS=noc@onemarketer.cl

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}


service supervisor status &> /tmp/supervisor_status
if [ $? == 0 ];then
	write_log "OK: el supervisor está corriendo"
else
	write_log "ERROR: se detectan problemas con el supervisor en $(hostname)"
	SUBJECT_MESSAGE="SUPERVISOR CRITICAL PROBLEM: maquina $(hostname)"
	ECHO_MESSAGE_HTML="<br><strong>Se detecta problemas con el supervisor en <strong>$(hostname)</strong><br>$(cat /tmp/supervisor_status)";
        ECHO_MESSAGE="Se detectan problemas con el supervisor en $(hostname)";
	echo "$ECHO_MESSAGE_HTML" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	/home/hydefus/script/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$ECHO_MESSAGE" -p2  -s spacealarm -r 30
fi
