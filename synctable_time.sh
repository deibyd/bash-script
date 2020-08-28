#!/bin/bash

TABLE=$1
DATE1=$2
DATE2=$3
FILTER=$4

function write_log() {
    #logger "$(basename $0) - $1"
    echo "$1"
}

function example() {
    write_log "ERROR - faltan parametros"
    write_log "Uso: ./$(basename $0) <table> <date1> <date2> <other_filter>"
    write_log ""
    write_log "Ejemplos de uso:"
    write_log "Uso: ./$(basename $0) messenger \"2020-03-01 00:00\" \"2020-04-01 00:00\" \"and id_context=9\""
}

# se valida la cantidad de parametros
function usage() {
    if [[ $# -ne 4 ]]; then
        example
        exit 1
    fi
}

#cmd="mysql -u root -psandermaster -D wa -h 186.67.157.130 -P $remote -s -r -N -e ";
usage $TABLE "$DATE1" "$DATE2" "$FILTER"

write_log "Inicio del respaldo en la tabla $TABLE entre los fechas $DATE1 y $DATE2"

mysqldump -u migrador -pmigrador.s -h 192.168.1.32 --skip-triggers --compact --no-create-info wa $TABLE --where="time >= '$DATE1' and time < '$DATE2' $FILTER" > sql/$TABLE."$DATE1"."$DATE2".sql

#mysql -u root -psandermaster -D wa -s -r -N -e "source sql/$TABLE.$DATE1.$DATE2.sql"

