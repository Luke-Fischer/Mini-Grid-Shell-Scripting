# Mini-Grid-Shell-Scripting
Using FIFO's to create a "mini grid" computer task management system

# Usage

Run ./server.sh

Add jobs: ./jobSubmit "your job"

# Jobs

jobSubmit.sh adds jobs to the server's FIFO

Jobs can be:     
- any system command (i.e ls)
    - the server sends this command to a worker to execute
- status
    - the server reports the status of the workers and jobs completed
        - which workers are busy/available
        - How many jobs a worker has completed
- shutdown
    - server sends a shutdown signal to each worker and waits for them to terminate before terminating itself

# Jobs are to be distributed in round-robin order
This means that if there are 12 workers and 25 jobs, worker 1 will complete jobs (1, 13, 25). If job 1 is still busy when the server receives the 13th job from jobSubmit, the server waits and adds the jobs into an internal queue to ensure that worker 1 compeltes job 13. Once worker one is available the server then sends it the 13th job. 

# Communication
Server FIFO - jobSubmit.sh adds jobs to the FIFO and each worker sends signals to this FIFO indicating it is done its job and ready for a new one
Worker FIFO's - Each worker has its own FIFO that the server uses to send the workers jobs

# Output

log files are located at /tmp/worker-lfischer.{i}.log.txt
