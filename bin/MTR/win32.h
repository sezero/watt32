#pragma once

#if defined(_WIN32)  /* Rest of file */
#include <stdlib.h>
#include <time.h>

#if defined(USE_KERBEROS)
  /*
   * In '$(KRB_ROOT)/include/windows'
   */
  #include <resolv.h>
  #include <winsock2.h>
  #include <ws2tcpip.h>

#elif !defined(USE_WATT32)
  /*
   * This plain Winsock2 version does not work.
   */
  #include <winsock2.h>
  #include <ws2tcpip.h>
  #include "Missing/arpa/nameser.h"
  #include "Missing/resolv.h"

  extern const char *hstrerror (int err);
  extern void        herror (const char *s);
#endif

#if !defined(USE_WATT32)
  extern int win_dns_open (void);
  extern int gettimeofday (struct timeval *tv, void *tz_not_needed);
#endif
#endif

