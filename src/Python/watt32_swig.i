
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
%}

#define WINWATT   64
#define DOSX      64
#define MS_CDECL

#define W32_DATA
#define W32_FUNC
#define W32_CALL

// %include "wattcp.h"
%include "sock_ini.h"
%include "pcdbug.h"
// %include "pcicmp.h"
// %include "pcdns.h"
%include "pctcp.h"
%include "misc.h"

#if defined(USE_SOCKET_API)
  %include "../socket.h"
#endif

#undef udp_Socket

#ifdef SWIG_LINK_RUNTIME
  #define SWIGINTERN
  #define SWIGRUNTIME
  #define SWIGRUNTIMEINLINE

  %include "pyrun.swg"
#endif

// extern int sock_init (void);

W32_FUNC void  W32_CALL dbug_init (void);
W32_FUNC DWORD W32_CALL lookup_host (const char *host, char *ip_str);
W32_FUNC DWORD W32_CALL _chk_ping (DWORD host, DWORD *ping_num);
W32_FUNC void  W32_CALL add_ping  (DWORD host, DWORD tim, DWORD number);
W32_FUNC WORD  W32_CALL tcp_tick  (sock_type *s);
W32_FUNC int   W32_CALL _ping     (DWORD       host,
                                   int         num,  /* is actually a 'DWORD' */
                                   const BYTE *pattern,
                                   size_t      len);

W32_FUNC const char *W32_CALL wattcpVersion (void);      /* Watt-32 target version/date */
W32_FUNC const char *W32_CALL wattcpCapabilities (void); /* what features was been compiled in */
W32_FUNC const char *W32_CALL wattcpBuildCC (void);      /* what is the compiler __VENDOR__ nane */
W32_FUNC const char *W32_CALL wattcpBuildCCexe (void);   /* what is the compiler name */
W32_FUNC const char *W32_CALL wattcpBuildCflags (void);  /* what CFLAGS were used */
