/*
 * A simple test program for Pull Request 79:
 * https://github.com/gvanem/Watt-32/pull/79
 */
#include <stdio.h>
#include <string.h>
#include "sysdep.h"

#if !defined(_Windows)
  #include <sys/ioctl.h>
  #include <poll.h>
#endif

#ifndef REMOTE_IP
#define REMOTE_IP "10.0.0.1"
#endif

#ifndef REMOTE_PORT
#define REMOTE_PORT 80
#endif

int main (int argc, char **argv)
{
#if defined(_Windows)
  WS_init();
#else
  if (argc >= 2 && !strcmp(argv[1], "-d"))
     dbug_init();
#endif

  int fd = socket (PF_INET, SOCK_STREAM, 0);
  if (fd < 0)
  {
    PERROR ("socket()");
    return (1);
  }

  int opt = 1;
  if (IOCTLSOCKET(fd, FIONBIO, &opt) < 0)
  {
    PERROR ("ioctlsocket()");
    goto fail;
  }

  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons (REMOTE_PORT);
  inet_pton (AF_INET, REMOTE_IP, &addr.sin_addr);

  if (connect(fd, (struct sockaddr*)&addr, sizeof(struct sockaddr_in)))
  {
    if (errno != EINPROGRESS)
    {
      PERROR ("connect()");
      goto fail;
    }
  }

  struct pollfd pfd;
  pfd.fd = fd;
  pfd.events = POLLOUT;
  pfd.revents = 0;
  if (poll(&pfd, 1, -1) < 0)
  {
    PERROR ("poll()");
    goto fail;
  }

  int so_error;
  socklen_t len = sizeof(int);
  if (getsockopt(fd, SOL_SOCKET, SO_ERROR, (SOCKOPT_CAST)&so_error, &len))
  {
    PERROR ("getsockopt()");
    goto fail;
  }

  if (so_error != 0)
  {
    printf("CONNECT FAILED: %d/%s\n", so_error, strerror(so_error));
    goto fail;
  }

  printf ("connected!\n");
  close (fd);
  return (0);

fail:
  close (fd);
  return (1);
}
