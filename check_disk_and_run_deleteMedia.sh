#!/bin/bash
#MAILS=max@psychoworld.cl,noc@onemarketer.cl
MAILS=noc@onemarketer.cl
THRESHOLD=700000

PARTITION=$1
IFS=' ' read -r -a LOGS <<< $2

if [ ! -z $LOGS ];then
	CONTINGENCY=" - contingencia aplicada"
	CONTINGENCY_HTML="<br><br><strong>contingencia aplicada</strong>"
fi

function write_log() {
        logger "$(basename $0) - $1"
        echo "$1"
}

function get_space_left() {
	echo $(df | grep "$1" | awk '{print $4}')
}

function overturn_the_files() {
	find $1 -type f| while read f; do echo "" > $f; done
}

for i in $(df|awk '{print $1}'|grep "^\/")
do
	if [ $PARTITION == "$i" ];then
		SPACE=$(get_space_left "$i")
		if [ $SPACE -lt $THRESHOLD ];
		then
			SUBJECT_MESSAGE="[ALERTA MEDIA]: Queda poco espacio en $(hostname): $SPACE Kb"
			ECHO_MESSAGE="WARNING: Quedaba poco espacio ($SPACE) en $i de la maquina $(hostname)$CONTINGENCY";
			write_log "$ECHO_MESSAGE"
			SPACE=$(get_space_left "$i")
			ECHO_MESSAGE_HTML="<br><strong>WARNING:</strong> Quedaba poco espacio <strong>($SPACE)</strong> en <strong>$i</strong> de la maquina <strong>$(hostname)$CONTINGENCY_HTML ($SPACE)";
			for _path in "${LOGS[@]}"
			do
				overturn_the_files $_path
			done
			echo "$ECHO_MESSAGE_HTML" | mail -a "Content-type: text/html;" -s "$SUBJECT_MESSAGE" $MAILS
		else
			write_log "OK: Queda espacio ($SPACE mayor a $THRESHOLD) en $i de la máquina $(hostname)";
		fi
	else
		write_log "WARNING: nothing to do for $i because is not $PARTITION"
	fi
done

