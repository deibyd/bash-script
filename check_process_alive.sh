#!/bin/bash
# by deibyd (20200903) : script que chequea si un proceso esta vivo. Primero inspecciona si el proceso esta arriba, si lo esta, entonces, mira si el log tiene movimiento.

HOME_SCRIPT_PATH=/home/hydefus/script

MAILS=noc@onemarketer.cl

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function usage() {
	write_log "ERROR: parametros incorrectos"
	write_log "USO: ./$(basename $0) -a <archivo de log> -b <nombre del servicio> {-c <supervisor|nohup>} {-d <carpeta de la aplaicación>}"
	write_log "EJEMPLO: ./$(basename $0) -a /opt/logs/instagram/digicelpa.out.log -b digicel -c nohup -d /opt/OneMarketerGateway.digicelpa.instagram/web/instagram"
}

while getopts ":a:b:c:d:" OPTION; do
	case $OPTION in
	a) LOG_FILE=$OPTARG ;;
	b) SERVICE_NAME=$OPTARG ;;
	c) PROCESS_CONTROL=$OPTARG ;;
	d) APPLICATION_FOLDER=$OPTARG ;;
	*) 
		usage
		exit 70
		;;
	esac
done

if [ -z "${LOG_FILE}" ] || [ -z "${SERVICE_NAME}" ]; then
	usage
	exit 69
fi

PID=$(ps ux | grep "pushReceiver.*$SERVICE_NAME" | grep -v grep | awk '{print $2}')

SUBJECT_MESSAGE="[WARNING] PROCESS ALERT: Check $SERVICE_NAME - $(hostname)"

function restart_service() {
	case $PROCESS_CONTROL in
		"supervisor")
        		supervisorctl restart $SERVICE_NAME
			if [ $? -gt 0 ];then
				RESPONSE="ERROR - ocurrió un problema al tratar de reiniciar el servicio $SERVICE_NAME por supervisor"
				write_log "$RESPONSE"
				$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$RESPONSE" -p2  -s spacealarm -r 30
				exit 66
			fi
    		;;
		"nohup")
			if [ ! -z $PID ];then
				kill -9 $PID
			fi
 			sleep 3
			cd $APPLICATION_FOLDER && nohup php -f pushReceiver.php $SERVICE_NAME &
			if [ $? -gt 0 ];then
				RESPONSE="ERROR - ocurrió un problema al tratar de reiniciar el servicio $SERVICE_NAME por nohup"
				write_log "$RESPONSE"
				$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$RESPONSE" -p2  -s spacealarm -r 30
				exit 67
			fi
		;;
  		*)
			usage
			exit 68
    		;;
	esac
}

RESTART_MESSAGE="Por favor, reinciar el servicio"
if [ ! -z $PROCESS_CONTROL ];then
	RESTART_MESSAGE="Se ha realizado un reinicio del servicio"
fi

if [[ "" !=  "$PID" ]]; then
	write_log "OK - proceso del servicio $SERVICE_NAME esta arriba (PID: $PID)"
else
	MESSAGE="ERROR - El servicio $SERVICE_NAME no esta arriba. $RESTART_MESSAGE"
	HTML_MESSAGE="<strong>ERROR</strong> - El servicio $SERVICE_NAME no esta arriba. $RESTART_MESSAGE<br><strong>Script:</strong> pushReceiver.php<br><strong>Archivo de log: $LOG_FILE</strong>"
	if [ ! -z $PROCESS_CONTROL ];then
		restart_service
	fi
        write_log "$SUBJECT_MESSAGE"
	write_log "$MESSAGE"
        echo "$MESSAGE" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$MESSAGE" -p2  -s spacealarm -r 30
	exit 2
fi

LOG_FILE_SIZE_OLD=$(cat /tmp/${SERVICE_NAME}_log_file_size.log)
LOG_FILE_SIZE_NEW=$(stat -c%s "$LOG_FILE")
echo $LOG_FILE_SIZE_NEW > /tmp/${SERVICE_NAME}_log_file_size.log

if [[ "$LOG_FILE_SIZE_OLD" -eq "$LOG_FILE_SIZE_NEW" ]];then
	MESSAGE="ERROR - No ha cambiado el log $LOG_FILE del servicio $SERVICE_NAME. $RESTART_MESSAGE"
	HTML_MESSAGE="<strong>ERROR</strong> - No ha cambiado el log <string>$LOG_FILE</string> del servicio <strong>$SERVICE_NAME</strong>. $RESTART_MESSAGE<br><strong>Script:</strong> pushReceiver.php<br><strong>Archivo de log: $LOG_FILE</strong>"
	if [ ! -z $PROCESS_CONTROL ];then
		echo "restart_service"
	fi
	restart_service
        write_log "$SUBJECT_MESSAGE"
	write_log "$MESSAGE"
        echo "$MESSAGE" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
	$HOME_SCRIPT_PATH/pushover.sh  -a monitor -t "$SUBJECT_MESSAGE" -m "$MESSAGE" -p2  -s spacealarm -r 30
	exit 2
fi

write_log "OK: El archivo de log $LOG_FILE si cambió de tamaño"
exit 0

