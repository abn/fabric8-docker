#!/bin/sh

echo Welcome to fabric8: http://fabric8.io/
echo
echo Starting Fabric8 container: $FABRIC8_KARAF_NAME 
echo Connecting to ZooKeeper: $FABRIC8_ZOOKEEPER_URL using environment: $FABRIC8_FABRIC_ENVIRONMENT
echo Using bindaddress: $FABRIC8_BINDADDRESS

if [ ${SHOW_PASSWORD:-0} -eq 1 ]; then
    echo -n "Fabric8 Administrator Password: "
    grep -o '^admin=.*,' $FABRIC8_HOME/fabric8-karaf/etc/users.properties \
        | sed -n 's/^admin=\(.*\),/\1/p'
fi

# TODO if enabled should we tail the karaf log to work nicer with docker logs?
#tail -f /home/fabric8/data/log/karaf.log

#sudo -u fabric8 /home/fabric8/fabric8-karaf/bin/fabric8 server
$FABRIC8_HOME/fabric8-karaf/bin/fabric8 server
