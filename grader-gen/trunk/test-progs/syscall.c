#include <syscall.h>
#include <stdio.h>

int main()
{
  syscall(SYS_pause);
  return 0;
}
