#!/bin/bash
# by deibyd (20200722) : obtiene los reportes mensual para cada cliente

CLIENT=$1
COUNTRY=$2
SERVICE=$3
IP=$4
DB=$5
ID_CONTEXT=$6
ID_SERVICE=$7
APP_ID=$8
INTEGRATION_ID=$9
AMOUNT_LICENSES=${10}
AMOUNT_CLIENTS=${11}
BOT_CASES=${12}
TEMPLATES=${13}
FECHA_INICIO=${14}
FECHA_FIN=${15}
NO_APLICA="N/A"
CANTIDAD_DE_LICENCIAS=$NO_APLICA
CANTIDAD_DE_CLIENTES_UNICOS=$NO_APLICA
CANTIDAD_TEMPLATE_ENVIADOS=$NO_APLICA
CASOS_BOT=$NO_APLICA
CASOS_BOT_CIERRA_CASO=$NO_APLICA
CASOS_BOT_CIERRA_CASO_DERIVA_CONTINGENCIA=$NO_APLICA
CASOS_BOT_CIERRA_CASO_DERIVA_TECNICA=$NO_APLICA
CANTIDAD_MENSAJES=$NO_APLICA

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function example() {
	write_log "ERROR, faltan parametros"
    	write_log  "Uso: ./$(basename $0) <client> <service> <ip> <country> <id_context> <id_service> <app_id> <integration_id> <id_login> <amount_licenses> <wa_api> <amount_clients> <agent_messages> <bot_cases> <templates> <inicio_fecha> <fin_fecha>"
	write_log "Ejemplos de uso:"

}

function usage() {
	if [[ $# -ne 17 ]]; then
		example
		exit 1
	fi
}

function run_query() {
	RESPONSE=$NO_APLICA
	if [[ $1 != $NO_APLICA ]];then
		while read line
        	do
                	MYSQL_INFO_ARRAY=("$line")
        	done < <( mysql -u root -psandermaster $DB -BNs -e "$1" 2>/dev/null)
		RESPONSE=$MYSQL_INFO_ARRAY
	fi
	echo $RESPONSE
}


if [ ! -z $AMOUNT_LICENSES ] && [ $AMOUNT_LICENSES == 'x'  ]; then
	CANTIDAD_DE_LICENCIAS="select count(1) from login where id_context = $ID_CONTEXT and enabled = 1;"
fi

if [ ! -z $AMOUNT_CLIENTS ] && [ $AMOUNT_CLIENTS == 'x'  ]; then
	CANTIDAD_DE_CLIENTES_UNICOS="select count(distinct(waid)) from sessionlog where idcontext = $ID_CONTEXT and idservice = $ID_SERVICE;"
	if [ ! -z $INTEGRATION_ID ]; then
		CANTIDAD_DE_CLIENTES_UNICOS="select count(distinct(user_id)) from smooch_message where integration_id = $INTEGRATION_ID and create_at >= '$FECHA_INICIO' and create_at < '$FECHA_FIN';"
	fi
fi

if [ ! -z $APP_ID ] && [ ! -z $TEMPLATES ] && [ $TEMPLATES == 'x'  ]; then
	CANTIDAD_TEMPLATE_ENVIADOS="select count(*) from smooch_template_msg temp, messages msg where temp.message_id = msg.id and app = '$APP_ID' and msg.status not in('E','S','W') and temp.created_at >= '$FECHA_INICIO' and temp.created_at < '$FECHA_FIN';"
fi

if [ ! -z $BOT_CASES ] && [ $BOT_CASES == 'x' ];then
	if [ $ID_CONTEXT -eq 1 ] && [ COUNTRY = 'Argentina' ] && [ CLIENT = 'Telefonica' ]; then
		CASOS_BOT="select count(1) from sessionlog where idcontext = $ID_CONTEXT and event = 3 and time >= '$FECHA_INICIO' and time < '$FECHA_FIN';"
	fi

	if [ $ID_CONTEXT -eq 4 ] && [ $COUNTRY = 'Argentina' ] && [ $CLIENT = 'Telefonica' ]; then
		CASOS_BOT_CIERRA_CASO="select count(1) from sessionlog where idcontext = $ID_CONTEXT and idlogin = 925 and event = 4 and idcategory = 15 and time >= '$FECHA_INICIO' and time < '$FECHA_FIN';"
		CASOS_BOT_CIERRA_CASO_DERIVA_CONTINGENCIA="select count(1) from sessionlog where idcontext = $ID_CONTEXT AND idlogin = 925 and event = 4 and idcategory = 19 and time >= '$FECHA_INICIO' and time < '$FECHA_FIN';"
		CASOS_BOT_CIERRA_CASO_DERIVA_TECNICA="select count(1) from sessionlog where idcontext = $ID_CONTEXT and idlogin = 925 and event = 4 and idcategory = 17 and time >= '$FECHA_INICIO' and time < '$FECHA_FIN';"
		CANTIDAD_MENSAJES="select count(1) from messages where id_context = $ID_CONTEXT and time >= '$FECHA_INICIO' and time < '$FECHA_FIN' and remote in(0,1);"
	elif [ $ID_CONTEXT -eq 36 ] && [ "$COUNTRY" = 'Costa Rica' ] && [ $CLIENT = 'Telefonica' ]; then
		CASOS_BOT_CIERRA_CASO="select count(1) from sessionlog where idcontext = $ID_CONTEXT and idlogin = 183 and event = 4 and idcategory = 131 and time >= '$FECHA_INICIO' and time < '$FECHA_FIN';"
	elif [ $ID_CONTEXT -eq 40 ] && [ $COUNTRY = 'Salvador' ] && [ $CLIENT = 'Telefonica' ]; then
		CASOS_BOT_CIERRA_CASO="select count(1) from sessionlog where idcontext = $ID_CONTEXT and idlogin = 193 and event = 4 and idcategory = 10 and time >= '$FECHA_INICIO' and time < '$FECHA_FIN';"
	fi
fi

if [ ! -z $IP ] || [ ! -z $ID_CONTEXT ];then
	usage "$CLIENT" "$SERVICE" "$IP" "$COUNTRY" "$ID_CONTEXT" "$ID_SERVICE" "$APP_ID" "$INTEGRATION_ID" "$ID_LOGIN" "$AMOUNT_LICENSES" "$WA_API" "$AMOUNT_CLIENTS" "$AGENT_MESSAGES" "$BOT_CASES" "$TEMPLATES" "$FECHA_INICIO" "$FECHA_FIN"
else
	example
	exit
fi

CURRENTLY=$(ifconfig|grep -hoP "\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b"|head -1)

if [ $CURRENTLY != $IP ];then
	write_log "ERROR: No se puede obtener el reporte para $CLIENT - $SERVICE - $COUNTRY, por favor, ejecute el script en la máquina según el parametro IP ($IP)"
	exit
fi

if [ ! -f /tmp/monthly_report_$(date -d "1 day ago" +%F)_$(hostname).csv ];then
	echo "CLIENT;COUNTRY;SERVICE;IP;ID_CONTEXT;ID_SERVICE;FECHA_INICIO;FECHA_FIN;CANTIDAD_DE_LICENCIAS;CANTIDAD_DE_CLIENTES_UNICOS;CANTIDAD_TEMPLATE_ENVIADOS;CASOS_BOT;CASOS_BOT_CIERRA_CASO;CASOS_BOT_CIERRA_CASO_DERIVA_CONTINGENCIA;CASOS_BOT_CIERRA_CASO_DERIVA_TECNICA;CANTIDAD_MENSAJES" > /tmp/monthly_report_$(date -d "1 day ago" +%F)_$(hostname).csv
fi

echo "$CLIENT;$COUNTRY;$SERVICE;$IP;$ID_CONTEXT;$ID_SERVICE;$FECHA_INICIO;$FECHA_FIN;$(run_query "$CANTIDAD_DE_LICENCIAS");$(run_query "$CANTIDAD_DE_CLIENTES_UNICOS");$(run_query "$CANTIDAD_TEMPLATE_ENVIADOS");$(run_query "$CASOS_BOT");$(run_query "$CASOS_BOT_CIERRA_CASO");$(run_query "$CASOS_BOT_CIERRA_CASO_DERIVA_CONTINGENCIA");$(run_query "$CASOS_BOT_CIERRA_CASO_DERIVA_TECNICA");$(run_query "$CANTIDAD_MENSAJES")" >> /tmp/monthly_report_$(date -d "1 day ago" +%F)_$(hostname).csv

