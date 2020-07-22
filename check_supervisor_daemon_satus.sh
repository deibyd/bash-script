#!/bin/bash
# by deibyd (20200722) : script que notifica si el supervisor tiene algun problema de estado

MAILS=dlopez@onemarketer.cl

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

COUNT_FATAL=$(supervisorctl status 2> /tmp/supervisorctl_status|grep -c FATAL)

if [ $COUNT_FATAL -gt 0 ];then
	write_log "ERROR: se detectan $COUNT_FATAL programas en estado FATAL en $(hostname)"
	FATAL_PROGRAM=$(supervisorctl status 2> /tmp/supervisorctl_status|grep FATAL|sed 's/$/<br>/g')
	SUBJECT_MESSAGE="SUPERVISOR CRITICAL PROBLEM: se detectan $COUNT_FATAL programas en estado FATAL en $(hostname)"
	ECHO_MESSAGE_HTML="<br><strong>Lista de procesos en FATAL</strong><br><br>$(echo $FATAL_PROGRAM)";
	ECHO_MESSAGE="Hay $COUNT_FATAL procesos en FATAL en $(hostname)";
	echo "$ECHO_MESSAGE_HTML" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	/home/hydefus/script/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$ECHO_MESSAGE" -p2  -s spacealarm -r 30
else
	write_log "OK: no hay programas en estado FATAL"
fi

