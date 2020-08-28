#!/bin/bash 
# by deibyd (20200821): Verifica estado de whatsapp por la página https://downdetector.com/
# by deibyd (20200824): Se agrega los demas canales de manera modular en este mismo script
# 			Se parametriza la URL y se obtiene el nombre del canal para poder parametrizar en una sola funcion

MAILS=dlopez@onemarketer.cl,ctenias@onemarketer.cl

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function run_curl {
	CURL_RESPONSE=$(curl -s ${1}|grep -o "${2}")
	if [ "$CURL_RESPONSE" == "${2}" ];then
        	write_log "OK: no hay problemas con $(echo "${1}"|awk -F"/" '{print $(NF-1)}'): $CURL_RESPONSE"
	else
        	SUBJECT_MESSAGE="$(echo "${1}"|awk -F"/" '{print $(NF-1)}') PROBLEM: Posibles problemas en el servicio"
        	RESPONSE_HTML="<br><strong>WARNiNG: </strong>Se ha detectado un cambio de estado en el servicio de $(echo "${1}"|awk -F"/" '{print $(NF-1)}'). <br><strong>$CURL_RESPONSE</strong><br>Para más información ver página en ${1}</strong>"
        	echo "$RESPONSE_HTML" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
        	write_log "ERROR: hay problemas con $(echo "${1}"|awk -F"/" '{print $(NF-1)}') : $CURL_RESPONSE"
	fi
}


run_curl "https://downdetector.cl/problemas/whatsapp/" "Ninguna falla Whatsapp"
run_curl "https://downdetector.cl/problemas/facebook-messenger/" "Ninguna falla Facebook Messenger"
run_curl "https://downdetector.cl/problemas/facebook/" "Ninguna falla Facebook"
run_curl "https://downdetector.cl/problemas/instagram/" "Ninguna falla Instagram"
run_curl "https://developers.facebook.com/status/dashboard/" ">Facebook Platform is Healthy<"

