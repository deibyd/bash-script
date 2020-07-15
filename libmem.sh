#!/bin/bash
FECHA=$(date)
echo "Generado" > /usr/local/dropcache.txt
echo $FECHA >> /usr/local/dropcache.txt
sync
sysctl -w vm.drop_caches=3
sleep 3
sysctl -w vm.drop_caches=1

