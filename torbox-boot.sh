#!/usr/bin/env bash

SCRIPTS_PATH=/home/pi
SETCAP=/sbin/setcap

# Clear current iptable rules
$SCRIPTS_PATH/iptable-clear.sh

while [ -f /var/run/tor/tor.pid ] ;
do
    TOR_PID=`cat /var/run/tor/tor.pid`
    TOR_RUNNING=$(ps -ef | grep $TOR_PID | grep torrc | wc -l )

    if [[ $TOR_RUNNING -eq 1 ]] ;
    then
        TOR_READY=$(echo -e 'PROTOCOLINFO\r\n' | nc 127.0.0.1 9051 | grep "250 OK" | wc -l)
        if [[ $TOR_READY -eq 1 ]] ;
        then
            # Set iptable rules
            $SCRIPTS_PATH/ipt-anonymizing-middlebox.sh
            $SETCAP 'cap_net_bind_service=+ep' /usr/bin/obfs4proxy
            break
        fi
    fi
done

echo "Done."
exit 0
