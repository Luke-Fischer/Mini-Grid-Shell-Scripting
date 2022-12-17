#!/bin/bash
#Create server-user FIFOs
terminate=1
id=$1
index=0
let "index = id - 1"
umask 0077
echo "" > /tmp/worker-lfischer.${index}.log.txt
coreCount=1
totalProcesses=1
if [ ! -p /tmp/worker$1-lfischer-inputfifo ] ; then 
    mkfifo /tmp/worker$1-lfischer-inputfifo
fi

if [ ! -p /tmp/server-lfischer-inputfifo ] ; then 
    mkfifo /tmp/server-lfischer-inputfifo
fi

while [ $terminate != 0 ]
do
    if read line; then
        set -- $line

        #Shutdown
        if [ $2 = "shutdown" ] ; then
            terminate=0
            echo "Worker received a request to shutdown" >> /tmp/worker-lfischer.${index}.log.txt
            rm /tmp/worker$1-lfischer-inputfifo
        fi

        cmd(){
        #Execute command
            if [ $2 = "CMD" ] ; then
                shift 2
                echo "Received command: $*" >> /tmp/worker-lfischer.${index}.log.txt
                $* >> /tmp/worker-lfischer.${index}.log.txt
                echo "" >> /tmp/worker-lfischer.${index}.log.txt
                echo "worker $id" > /tmp/server-lfischer-inputfifo
            fi
        }
        cmd $line        
    fi
done </tmp/worker$id-lfischer-inputfifo

