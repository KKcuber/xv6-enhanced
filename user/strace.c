#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

//user program for strace
int
main(int argc, char *argv[])
{
  int mask;
  if (argc <= 2)
  {
    fprintf(2, "Invalid syntax\n");
    exit(1);
  }

  mask = atoi(argv[1]);

  trace(mask);
  // Executing the command which we have to trace until it exits
  char *execargs[argc - 1];
  for (int i = 0; i < argc - 2; i++)
  {
    execargs[i] = argv[i + 2];
  }
  execargs[argc - 2] = 0;
  exec(execargs[0], execargs);
  fprintf(2, "exec of %s failed\n", execargs[0]);
  exit(0);
}