#!/bin/bash
# by deibyd (20200722) : obtiene los reportes mensual para cada cliente

FILE=$1

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function example() {
	write_log "ERROR, faltan parametros"
	write_log "Ejemplos de uso:"
    	write_log  "Uso: ./$(basename $0) <file>"
}

function usage() {
	if [[ $# -ne 1 ]]; then
		example
		exit 1
	fi
}

usage $FILE
if [ ! -f /tmp/monthly_report_$(date -d "1 day ago" +%F)_$(hostname).csv ];then
	rm -rf /tmp/monthly_report_$(date -d "1 day ago" +%F)_$(hostname).csv
fi
while IFS=, read -r CLIENT COUNTRY SERVICE MACHINE IP DB ID_CONTEXT ID_SERVICE APP_ID INTEGRATION_ID AMOUNT_LICENSES WA_API AMOUNT_CLIENTS AGENT_MESSAGES BOT_CASES TEMPLATES;
do 
	./get_monthly_report.sh "$CLIENT" "$COUNTRY" "$SERVICE" "$IP" "$DB" "$ID_CONTEXT" "$ID_SERVICE" "$APP_ID" "$INTEGRATION_ID" "$AMOUNT_LICENSES" "$AMOUNT_CLIENTS" "$BOT_CASES" "$TEMPLATES" "$(date -d "1 day ago" +%Y-%m-%d" 00:00")" "$(date +%Y-%m-%d" 00:00")"
done < $FILE

