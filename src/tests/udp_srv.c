/*
 * listener.c -- a datagram sockets "server" demo
 */
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>

#include "sysdep.h"

#if !defined(_Windows)   /* Real Watt-32, Not native Winsock2 programs */
  #include <netinet/in.h>
  #include <sys/socket.h>
  #include <sys/ioctl.h>
  #include <arpa/inet.h>
#endif

#define MYPORT 6543    /* the port users will be connecting to */

#define MAXBUFLEN 100

#if defined(WATT32)
  #define OPTS_SHORT "dn"
  #define OPTS_HELP  "  -d  enable Watt-32 debug\n" \
                     "  -n  use non-blocking socket\n"
#else
  #define OPTS_SHORT "n"
  #define OPTS_HELP  "  -n  use non-blocking Winsock2 socket\n"
#endif

void usage (void)
{
  printf ("udp_srv [%s]\n"
          "  listen for UDP-traffic on port %d.\n%s\n",
          OPTS_SHORT, MYPORT, OPTS_HELP);
  exit (0);
}

int main (int argc, char **argv)
{
  struct sockaddr_in my_addr;    /* my address information */
  struct sockaddr_in their_addr; /* connector's address information */
  char   buf [MAXBUFLEN];
  int    sockfd, addr_len, numbytes, debug = 0;
  __ms_u_long non_block = 0;

  while (argc > 1)
  {
    if (!strcmp(argv[1], "-n"))
       non_block = 1;
    if (!strcmp(argv[1], "-d"))
       debug = 1;
    if (!strcmp(argv[1], "-?") || !strcmp(argv[1], "-h"))
       usage();
    argc--;
    argv++;
  }

#if defined(WATT32)
  if (debug)
     dbug_init();
  sock_init();

#elif defined(_Windows)
  WS_init();
#endif

  sockfd = socket (AF_INET, SOCK_DGRAM, 0);
  if (sockfd == -1)
  {
    PERROR ("socket");
    return (1);
  }

  memset (&my_addr,0,sizeof(my_addr));  /* zero the rest of the struct */
  my_addr.sin_family = AF_INET;         /* host byte order */
  my_addr.sin_port   = htons(MYPORT);   /* short, network byte order */
  my_addr.sin_addr.s_addr = INADDR_ANY; /* automatically fill with my IP */

  if (bind(sockfd, (struct sockaddr*)&my_addr, sizeof(struct sockaddr)) == -1)
  {
    PERROR ("bind");
    return (1);
  }

  IOCTLSOCKET (sockfd, FIONBIO, &non_block);

  printf ("Waiting for UDP messages at port %d...", MYPORT);
  fflush (stdout);

  while (!kbhit())
  {
    if (non_block)
    {
      fd_set fd;
      struct __ms_timeval tv = { 0, 10000 };
      int    n;

      FD_ZERO (&fd);
      FD_SET (sockfd, &fd);
#ifdef _Windows
      n = select (sockfd+1, &fd, NULL, NULL, &tv);
#else
      n = select_s (sockfd+1, &fd, NULL, NULL, (struct timeval*)&tv);
#endif

      if (n < 0)
      {
        PERROR ("select");
        return (1);
      }
      if (n == 0)
         continue;
    }

    /*  --- Wait for UDP message */

    addr_len = sizeof (struct sockaddr);
    numbytes = recvfrom (sockfd, buf, MAXBUFLEN, 0,
                         (struct sockaddr *)&their_addr, &addr_len);
    if (numbytes < 0)
    {
      PERROR ("recvfrom");
      return (1);
    }

    printf ("\007got packet from %s\n", inet_ntoa(their_addr.sin_addr));
    printf ("packet is %d bytes long\n", numbytes);
    buf [numbytes] = '\0';
    printf ("packet contains \"%s\"\n", buf);

    /*  --- Reply to this message (echo) */

    numbytes = sendto (sockfd, buf, numbytes, 0,
                       (struct sockaddr*)&their_addr, sizeof(struct sockaddr));
    if (numbytes < 0)
    {
      PERROR ("sendto");
      return (1);
    }
    printf ("sent %d bytes to %s\n", numbytes, inet_ntoa(their_addr.sin_addr));
  }

  close (sockfd);
  (void) debug;
  return (0);
}

