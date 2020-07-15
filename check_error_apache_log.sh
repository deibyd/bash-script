#!/bin/bash 
# by deibyd (20200627): Verifica si hay errores en el logs de apache
# by deibyd (20200630): Se agrega logica de filtro de logs, para tomar decision del reinicio del apache
# by deibyd (20200701): Se volca el logs cuando se encuentra error que amerite un reinico
# by deibyd (20200702): Se respalda el logs antes de volcar

MAILS=max@psychoworld.cl,noc@onemarketer.cl

CONTROL_FILE="/tmp/check_error_apache_log.control.$(date +%F)"
APACHE_LOG_ERROR="/var/log/apache2/error.log"

PATRON_ERROR="\[.*:error\]"

# Patrones de error para aplicar reinicio del servicio web
FILTER_ERROR_TO_RESTART_1="\[core:notice\] \[pid.*\] AH00051: child pid.*exit signal Bus error.*possible coredump in /etc/apache2"
FILTER_ERROR_TO_RESTART_2="\[mpm_prefork:error\] \[pid.*\].*Cannot allocate memory: AH00159: fork: Unable to fork new process"

function write_log() {
	logger "$(basename $0) - $1"
	echo "$1"
}

CANTIDAD_ERRORES=$(tail -n 10000 $APACHE_LOG_ERROR|grep "$PATRON_ERROR"|grep -v "^#"|wc -l)
THE_LAST_ROW=$(tail -n 10000 $APACHE_LOG_ERROR|grep "$PATRON_ERROR"|grep -v "^#"|tail -n 5|sed 's/^/=> /g'|sed 's/$/<br>/g')
IS_A_FILTER_ERROR=$(grep -E "$FILTER_ERROR_TO_RESTART_1|$FILTER_ERROR_TO_RESTART_2" $APACHE_LOG_ERROR|wc -l)

if [ "$IS_A_FILTER_ERROR" -gt "0" ]; then
	service apache2 restart
	if [ $? -eq 0 ]; then
		write_log "WARNING: apache correctamente reiniciado"
		APACHE_RESTARTED_HTML="<br><br><strong>ALERT: apache tuvo que ser reiniciado por error conocido y filtrado</strong><br><br>"
		APACHE_RESTARTED="ALERT: apache tuvo que ser reiniciado por error conocido y filtrado - "
		cp $APACHE_LOG_ERROR $APACHE_LOG_ERROR.$(date +%F_%T)
		if [ $? -eq 0 ]; then
			write_log "INFO: respaldo de archivo realizado con exito"
			echo "" > $APACHE_LOG_ERROR
		else
			write_log "ERROR: por alguna razon, no se pudo respaldar el archivo de log"
		fi
	fi
fi

RESPONSE="OK: No se encuentran errores en los logs del apache"
CODIGO=0

if [ "$CANTIDAD_ERRORES" -gt "0" ]; then
	SUBJECT_MESSAGE="APACHE LOGS PROBLEM: $(hostname)"
	RESPONSE_HTML="$APACHE_RESTARTED_HTML<br><strong>CRITICAL: </strong>Se han encontrado <strong>$CANTIDAD_ERRORES</strong> errores en los logs de apache - maquina <strong>$(hostname)</strong>"
	RESPONSE="${APACHE_RESTARTED}CRITICAL: Se han encontrado $CANTIDAD_ERRORES errores en los logs de apache - maquina $(hostname)"
	CODIGO=2
	echo "$RESPONSE_HTML<br><br><strong>Ultimos registros de logs:</strong><br>$THE_LAST_ROW" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	/home/hydefus/script/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$RESPONSE" -p2  -s spacealarm -r 30
fi

write_log "$RESPONSE"
exit $CODIGO

