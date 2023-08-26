#ifndef _WIN32_MTR_H
#define _WIN32_MTR_H

#if defined(_WIN32) && !defined(USE_WATT32)
  #include <winsock2.h>
  #include <ws2tcpip.h>
  #include <time.h>
  #include <sys/timeb.h>
  #include <stdlib.h>

  #include "Missing/arpa/nameser.h"
  #include "Missing/resolv.h"

  struct timezone {
         int tz_minuteswest;           /* minutes west of Greenwich */
         int tz_dsttime;               /* type of dst correction */
       };

  extern int         gettimeofday (struct timeval *tv, struct timezone *tz);
  extern const char *hstrerror (int err);
  extern void        herror (const char *s);
  extern u_long      inet_aton (const char *name, struct in_addr *adr);
  extern int         win_dns_open (void);
#endif  /* _WIN32 && && !USE_WATT32 */
#endif  /* _WIN32_MTR_H */

