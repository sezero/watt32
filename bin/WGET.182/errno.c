#include <stdio.h>
#include <errno.h>

int main (void)
{
  printf ("(*_errno)() = %d\n", errno);
  errno = 99;
  printf ("(*_errno)() = %d\n", errno);
#undef errno
  printf ("&_errno = %p\n", &_errno);
  printf ("*&_errno = %d\n", *(*_errno)());

  return 0;
}