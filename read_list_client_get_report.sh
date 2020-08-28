#!/bin/bash
# by deibyd (20200722) : obtiene los reportes mensual para cada cliente

FILE=$1
HOME_SCRIPT=/home/hydefus/script
FECHA_INICIAL=$2
FECHA_FINAL=$3
YEAR_MONTH=$(date --date="$FECHA_INICIAL" +%Y-%m)

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function example() {
	write_log "ERROR, faltan parametros"
	write_log "Ejemplos de uso:"
    	write_log  "Uso: ./$(basename $0) <file> <fecha_inicial> <fecha_final>"
}

function usage() {
	if [[ $# -ne 3 ]]; then
		example
		exit 1
	fi
}

usage $FILE "$FECHA_INICIAL" "$FECHA_FINAL"

if [ -f /tmp/monthly_report_${YEAR_MONTH}_$(hostname).csv ];then
	rm -rf /tmp/monthly_report_${YEAR_MONTH}_$(hostname).csv
fi

while IFS=, read -r CLIENT COUNTRY SERVICE MACHINE IP DB ID_CONTEXT ID_SERVICE APP_ID INTEGRATION_ID AMOUNT_LICENSES WA_API AMOUNT_CLIENTS AGENT_MESSAGES BOT_CASES TEMPLATES;
do 
	$HOME_SCRIPT/get_monthly_report.sh "$CLIENT" "$COUNTRY" "$SERVICE" "$IP" "$DB" "$ID_CONTEXT" "$ID_SERVICE" "$APP_ID" "$INTEGRATION_ID" "$AMOUNT_LICENSES" "$AMOUNT_CLIENTS" "$BOT_CASES" "$TEMPLATES" "$FECHA_INICIAL" "$FECHA_FINAL"
done < $FILE

