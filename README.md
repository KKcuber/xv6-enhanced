# xv6
## Spec 1 : Syscall tracing
1. Added a `sys_trace()` function in `kernel/sysproc.c` that implements the new system call by remembering its argument in a trace_mask variable in the proc structure.
2. copied the trace mask from parent to child whenever fork was called.
3. modified syscall function in syscall.c to print the trace output.
4. Added a user program strace which calls the system call trace on the specified process.

## Spec 2 : Schedulers
### FCFS
1. Added a variable ctime to `struct proc` to store creation time.
2. Initialised ctime to 0 when process is allocated in allocproc.
3. Made a new scheduling logic for FCFS in `scheduler()` which schedules according to ctime.
4. Disabled preemption in `kerneltrap` and `usertrap`.

### PBS
1. Added variables in struct proc which store all stuff required by the scheduler to decide priority
2. Made a new scheduling logic for PBS in `scheduler()` which schedules according to dynamic priority.
3. Found run time by incrementing it in `clock_intr`
4. Found sleeping time by finding difference in time when it was switched to runnable and the time when it went to sleep.
5. Added new syscall `set_priority` which changes static priority of the process.

### MLFQ
1. Made 5 queues to store the processes.
2. On the initiation of a process, it is pushed to the end of the highest priority queue i.e queue 0.
3. If the process uses the complete time slice assigned for its current priority queue, it is preempted and inserted at the end of the next lower level queue. This is done in kernel and user trap.
4. Imlemented aging to prevent starvation.