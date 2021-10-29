# xv6
## Spec 1 : Syscall tracing
1. Added a `sys_trace()` function in `kernel/sysproc.c` that implements the new system call by remembering its argument in a trace_mask variable in the proc structure.
2. copied the trace mask from parent to child whenever fork was called.
3. modified syscall function in syscall.c to print the trace output.
4. Added a user program strace which calls the system call trace on the specified process.