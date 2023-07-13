/*
 * Portability hacks for syslogd
 */

#if defined(__GNUC__) || defined(__HIGHC__)
#include <unistd.h>
#include <sys/time.h>           /* struct timeval */
#endif

#define SYSLOG_INET
#define SYSV           /* to pull the correct headers */
#define RECEIVE_NTP    /* use NTP timestamping */

#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <memory.h>
#include <fcntl.h>
#include <process.h>
#include <dos.h>
#include <io.h>
#include <tcp.h>
#include <sys/socket.h>

#define _PATH_TTY       "con:"
#define _PATH_LOGCONF   "syslog.conf"

#define SYSLOGD_PIDNAME   _w32_ExpandVarStr ("$(TEMP)/syslog.pid")
#define _PATH_LOGPID     SYSLOGD_PIDNAME

#if defined(_MSC_VER) || defined(__BORLANDC__) || defined(__WATCOMC__)
  typedef int pid_t;

  #define sleep(s)               _sleep(s)
#endif

#if !defined(__DJGPP__)
  #define writev(s, vec, count)  writev_s(s, vec, count)
#endif

#if defined(__HIGHC__)
  #define snprintf _bprintf
#endif

#define  kill(a, b)      (errno = ESRCH)
#define  alarm(a)        0
#define  setsid()        0
#define  setlinebuf(a)   0
#define  fsync(a)        0

#define select           select_s
#define sigmask(a)       0
#define sigblock(a)      1
#define sigsetmask(a)    1
#define fork()           0
#define ttyname(x)       "con"
#define close_sock       close_s
#define getdtablesize()  32

extern unsigned long ntp_time (void *p);

#ifndef UTMP_FILE
  #ifdef UTMP_FILENAME
    #define UTMP_FILE UTMP_FILENAME
  #else
    #ifdef _PATH_UTMP
      #define UTMP_FILE _PATH_UTMP
    #else
      #define UTMP_FILE "/etc/utmp"
    #endif
  #endif
#endif

#ifndef MAXHOSTNAMELEN
#define MAXHOSTNAMELEN  64
#endif

#ifndef O_NOCTTY
#define O_NOCTTY        0
#endif

#ifndef O_NONBLOCK
#define O_NONBLOCK      0
#endif

#ifndef TIOCNOTTY
#define TIOCNOTTY       0
#endif

#ifndef _PATH_DEV
#define _PATH_DEV       "/dev/"
#endif

#ifndef _PATH_CONSOLE
#define _PATH_CONSOLE   "/dev/console"
#endif

#ifndef _PATH_TTY
#define _PATH_TTY       "/dev/tty"
#endif

#ifndef _PATH_LOG
#define _PATH_LOG       "/dev/log"
#endif

#ifndef _PATH_LOGCONF
#define _PATH_LOGCONF   "/etc/syslog.conf"
#endif

