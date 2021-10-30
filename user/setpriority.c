#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

//user program for setpriority according to given priority and process pid
int
main(int argc, char *argv[])
{
    int priority;
    int pid;
    if(argc != 3)
    {
        printf(2, "Usage: setpriority <priority> <pid>\n");
        exit(0);
    }
    priority = atoi(argv[1]);
    pid = atoi(argv[2]);
    set_priority(priority, pid);
    exit(0);
}