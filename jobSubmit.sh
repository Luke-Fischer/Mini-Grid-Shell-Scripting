#! /bin/bash
umask 0077

if [ ! -p /tmp/server-lfischer-inputfifo ] ; then 
    mkfifo /tmp/server-lfischer-inputfifo
fi

count=0
if [ $1 == "-s" ] ; then
    echo "status" > /tmp/server-lfischer-inputfifo
    count=1
fi

if [ $1 == "-x" ] ; then
    echo "shutdown" > /tmp/server-lfischer-inputfifo
    count=1
fi

if [ $count -eq 0 ] ; then
    string="CMD $*"
    echo $string > /tmp/server-lfischer-inputfifo
fi








