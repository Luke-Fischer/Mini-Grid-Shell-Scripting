#! /bin/bash
umask 0077
terminate=1
coreCount=1
currentProcess=1
jobsComplete=0
shutdown=0
numCores=`cat /proc/cpuinfo | grep processor | wc -l`

pidArray=()
coreArray=()
jobQueue=()
jobCompletedArray=()

for (( i=0; i<${numCores}; i++ ));
do
  let "coreArray[i] = 0"
  let "jobCompletedArray[i] = 0"
done

echo "Starting up $numCores processing units"

#create worker-server FIFOs
for i in $(seq $numCores); do
    if [ ! -p /tmp/worker$i-lfischer-inputfifo ] ; then 
        mkfifo /tmp/worker$i-lfischer-inputfifo
    fi
done

#create workers
for i in $(seq $numCores); do
    ./worker.sh $i &
    let "coreArray[i] = 0"
    let "pidArray[i] = $!"
done

echo "Ready for processing : place tasks into /tmp/server-lfischer-inputfifo"

#Create server-user FIFOs
if [ ! -p /tmp/server-lfischer-inputfifo ] ; then 
    mkfifo /tmp/server-lfischer-inputfifo
fi

trap "trap_ctrlc" INT

function trap_ctrlc()
{
    echo "shutdown" > /tmp/server-lfischer-inputfifo
}

#While user has not terminated the program - keep waiting for input from submitJob
while [ $terminate != 0 ]
do
    if read line; then
        #echo "Core $coreCount is dealing with process $totalProcesses: $line"
        string="$currentProcess $line"
        set -- $line
        statusVar=$1

        if [ $statusVar = "status" ] ; then
            echo "Total workers = $numCores"
            echo "total jobs completed = $jobsComplete"
            wker=1
            for i in "${jobCompletedArray[@]}"
            do
                if [ ${coreArray[i]} == 0 ] ; then
                    echo "Worker $wker has completed: $i tasks ---- currently available"
                    let "wker = wker + 1"
                else
                    echo "Worker $wker has completed: $i tasks ---- currently busy"
                    let "wker = wker + 1"
                fi
            done
        fi

        if [ $statusVar = "CMD" ] && [ $shutdown == 0 ] ; then
        let "currentProcess += 1"
            if [ ${coreArray[coreCount]} == 0 ] ; then
                if [ ${#jobQueue[@]} -gt 0 ] ; then
                    pop=${jobQueue[0]}
                    jobQueue=("${jobQueue[@]:1}")
                    echo $pop > /tmp/worker$coreCount-lfischer-inputfifo
                    let "coreArray[coreCount] = 1"
                    let "coreCount += 1"
                else
                    echo $string > /tmp/worker$coreCount-lfischer-inputfifo
                    let "coreArray[coreCount] = 1"
                    let "coreCount += 1"
                fi
            else
                #echo "Worker $coreCount not ready for job - posted job to queue"
                jobQueue+=("$string")
            fi
        fi

        if [ $statusVar = "worker" ] ; then
            index=$2
                let "coreArray[index] = 0"
                let "jobCompletedArray[index - 1] = jobCompletedArray[index - 1] + 1"
                let "jobsComplete = jobsComplete + 1"
        fi

        if [ $coreCount -gt $numCores ] ; then
            let "coreCount = 1"
        fi

        if [ $statusVar = "shutdown" ] || [ $shutdown == 1 ]; then
            shutdown=1
            if [ ${#jobQueue[@]} -lt 1 ] ; then
                readyToExit=0
                for i in $(seq $numCores) 
                do
                    if [ ${coreArray[i]} != 0 ] ; then
                        readyToExit=1
                    fi
                done
                iter=1
                if [ $readyToExit == 0 ] ; then
                    for i in $(seq $numCores) 
                    do
                        echo "$iter shutdown" > /tmp/worker$iter-lfischer-inputfifo
                        let "iter = iter + 1"
                    done
                    #wait for workers to terminate
                    for pid in ${pidArray[*]}; do
                        wait $pid
                    done

                    #server exits
                    break;
                fi
            fi
        fi
    fi
    if [ ${coreArray[coreCount]} == 0 ] ; then
        if [ ${#jobQueue[@]} -gt 0 ] ; then
            pop=${jobQueue[0]}
            jobQueue=("${jobQueue[@]:1}")
            echo $pop > /tmp/worker$coreCount-lfischer-inputfifo
            let "coreArray[coreCount] = 1"
            let "coreCount += 1"
            if [ $coreCount -gt $numCores ] ; then
                let "coreCount = 1"
            fi
        fi
    fi
done </tmp/server-lfischer-inputfifo

#Close fifo
rm /tmp/server-lfischer-inputfifo
