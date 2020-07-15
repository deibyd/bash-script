#!/bin/bash
FECHA=$(date)
gt=$(ls -la /home/hydefus/command_listener/ | grep "REBOOT_APACHE.PENDING" | wc -l)

if [ $gt -gt "0" ]:
then
    echo $FECHA
    mv /home/hydefus/command_listener/REBOOT_APACHE.PENDING "/home/hydefus/command_listener/REBOOT_APACHE.OK.$FECHA"
    echo "reboot apache service apache2 restart" | mail -s "reinicio proxyssl" max@psychoworld.cl,fernando@psychoworld.cl
    service apache2 restart
else
    echo "no hace nada"    
fi

