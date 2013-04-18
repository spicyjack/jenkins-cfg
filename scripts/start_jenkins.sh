#!/bin/bash

if [ $UID -eq 0 ]; then
    echo "ERROR: Don't start Jenkins as root!"
    exit 1
fi
java -jar $HOME/jenkins.war \
    --httpPort=8080 \
    --httpListenAddress=127.0.0.1 \
    --prefix=/jenkins \
    >> $HOME/jenkins.log 2>&1 &
