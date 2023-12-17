
%module watt32

#ifndef SWIG
#define SWIG
#endif

/* Don't prefix so callers may do e.g.
 * "cvar.watt32.debug_on=1" from Python.
 */
#ifndef WATT32_NO_NAMESPACE
#define WATT32_NO_NAMESPACE
#endif

#ifndef _WINSOCKAPI_
#define _WINSOCKAPI_
#endif

#ifndef _WINSOCK2API_
#define _WINSOCK2API_
#endif

#define W32_NAMESPACE(func) func

%ignore WIDESTR_FMT;
%ignore WINWATT;
%ignore ABUS_VAL_FMT;
%ignore ADDR_FMT;
%ignore BEEP_FREQ;
%ignore BEEP_MSEC;
%ignore CARRY_BIT;
%ignore DEF_CLOSE_TO;
%ignore DEF_MAX_VJSA;
%ignore DEF_MAX_VJSD;
%ignore DEF_OPEN_TO;
%ignore DEF_RECV_WIN;
%ignore DEF_RETRAN_TIME;
%ignore DEF_RST_TIME;
%ignore DEF_RTO_ADD;
%ignore DEF_RTO_BASE;
%ignore DEF_RTO_SCALE;
%ignore DOSX;

%ignore F_DUPFD;
%ignore F_GETFL;
%ignore F_SETFL;
%ignore F_GETFD;
%ignore F_SETFD;
%ignore F_GETLK;
%ignore F_SETLK;
%ignore F_SETLKW;
%ignore F_GETOWN;
%ignore F_SETOWN;

%ignore __set_ifname;
%ignore _sock_half_open;

%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <signal.h>
  #include <setjmp.h>
  #include <limits.h>
  #include <float.h>
  #include <math.h>
  #include <time.h>
  #include <io.h>
  #include <sys/w32api.h>

  #include "wattcp.h"
  #include "sock_ini.h"
  #include "pcdbug.h"
  #include "pcicmp.h"
  #include "pcdns.h"
  #include "pctcp.h"
  #include "pcsed.h"
  #include "misc.h"
  #include "socket.h"
%}

#define __SYS_CDEFS_H
#define __BEGIN_DECLS
#define __END_DECLS

#define WINWATT   64
#define DOSX      64
#define MS_CDECL

#define W32_DATA
#define W32_FUNC
#define W32_CALL
#define W32_CDECL

%include "sock_ini.h"
%include "pcdbug.h"
%include "pctcp.h"
%include "misc.h"

#undef intel
#undef intel16
#undef ntohs
#undef ntohs
#undef htons
#undef htonl

#if defined(USE_SOCKET_API)
  #define __SYS_SOCKET_H

  %include <netinet/in.h>

  #undef INADDR_ANY
  #undef INADDR_BROADCAST
  #undef INADDR_LOOPBACK
  #undef INADDR_NONE

  #define INADDR_ANY       0x00000000
  #define INADDR_BROADCAST 0xFFFFFFFF
  #define INADDR_LOOPBACK  0x7F000001
  #define INADDR_NONE      0xFFFFFFFF
#endif

#undef udp_Socket

#if defined(SWIG_LINK_RUNTIME)
  #define SWIGINTERN
  #define SWIGRUNTIME
  #define SWIGRUNTIMEINLINE

  %include "pyrun.swg"
#endif

void  dbug_init (void);
DWORD lookup_host (const char *host, char *ip_str);
DWORD _chk_ping (DWORD host, DWORD *ping_num);
void  add_ping  (DWORD host, DWORD tim, DWORD number);
WORD  tcp_tick  (sock_type *s);

int _ping (DWORD       host,
           int         num,  /* is actually a 'DWORD' */
           const BYTE *pattern,
           size_t      len);

unsigned long  intel   (unsigned long x);
unsigned short intel16 (unsigned short x);
unsigned short ntohs   (unsigned short);
unsigned short htons   (unsigned short);
unsigned long  ntohl   (unsigned long);
unsigned long  htonl   (unsigned long);

const char *wattcpVersion (void);      /* Watt-32 target version/date */
const char *wattcpCapabilities (void); /* what features was been compiled in */
const char *wattcpBuildCC (void);      /* what is the compiler __VENDOR__ nane */
const char *wattcpBuildCCexe (void);   /* what is the compiler name */
const char *wattcpBuildCflags (void);  /* what CFLAGS were used */

#if defined(USE_SOCKET_API)
   /*
    * Put this here since Swig has great troubles parsing <sys/socket.h>
    */
  #define SOCK_STREAM  1
  #define SOCK_DGRAM   2

  #define AF_INET      2
  #define AF_INET6    24
  #define AF_PACKET   25

  #include <netinet/in.h>

  int accept (int, struct sockaddr *, socklen_t *);
  int bind (int, const struct sockaddr *, socklen_t);
  int closesocket (int s);
  int connect (int, const struct sockaddr *, socklen_t);
  int ioctlsocket (int s, long cmd, void *argp);
  int fcntlsocket (int s, int cmd, ...);

  int getdomainname (char *name, size_t len);
  int setdomainname (const char *name, size_t len);

  int getpeername (int, struct sockaddr *, socklen_t *);
  int getsockname (int, struct sockaddr *, socklen_t *);
  int getsockopt (int, int, int, void *, socklen_t *);
  int listen (int, int);
  int recv (int, void *, int, int);
  int recvfrom (int, void *, int, int, struct sockaddr *, socklen_t *);
  int recvmsg (int, struct msghdr *, int);
  int send (int, const void *, int, int);
  int sendto (int, const void *, int, int, const struct sockaddr *, socklen_t);
  int sendmsg (int, const struct msghdr *, int);

  int setsockopt (int, int, int, const void *, socklen_t);
  int shutdown (int, int);
  int socket (int, int, int);
#endif

