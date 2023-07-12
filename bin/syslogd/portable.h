/*
 * Portability hacks for syslogd
 */

#if defined(__DJGPP__) || defined(__HIGHC__) || defined(unix)
#include <unistd.h>
#include <sys/time.h>           /* struct timeval */
#endif

#if defined(__DJGPP__) || defined(__HIGHC__) || \
    defined(__BORLANDC__) || defined(__WATCOMC__)

  #define SYSLOG_INET
  #define NO_SCCS
  #define SYSV           /* to pull the correct headers */
  #define RECEIVE_NTP    /* use NTP timestamping */

  #include <stdlib.h>
  #include <string.h>
  #include <time.h>
  #include <memory.h>
  #include <process.h>
  #include <dos.h>
  #include <io.h>
  #include <tcp.h>
  #include <sys/socket.h>

  #define _PATH_TTY       "con:"
  #define _PATH_LOGCONF   "syslog.conf"

  #if defined(__BORLANDC__) || defined(__WATCOMC__)
    typedef int pid_t;
  #endif

  #ifdef __HIGHC__
    #define snprintf _bprintf
  #endif

  #ifndef __DJGPP__
    #define  kill(a,b)     (errno=ESRCH)
    #define  alarm(a)      0
    #define  setsid()      0
    #define  setlinebuf(a) 0
    #define  fsync(a)      0
  #endif

  #define select           select_s
  #define sigmask(a)       0
  #define sigblock(a)      1
  #define sigsetmask(a)    1
  #define fork()           0
  #define ttyname(x)       "con"
  #define close_sock       close_s
  #define getdtablesize()  32

//extern int writev (int f, struct iovec *iov, int len);

  extern unsigned long ntp_time (void *p);

#else
  #include <unistd.h>
  #include <utmp.h>
  #include <sys/uio.h>
  #include <sys/un.h>
  #include <sys/wait.h>
  #include <sys/file.h>
  #include <sys/resource.h>
  #include <sys/param.h>
  #include <sys/errno.h>
  #include <sys/ioctl.h>
  #include <sys/stat.h>
  #include <sys/socket.h>
  #include <sys/time.h>

  #include <syscall.h>

  #define close_sock  close
#endif

#if defined(unix) && defined(SYSV)
  #include <sys/times.h>
  #include <sys/param.h>
#endif

#ifdef SYSV
#include <sys/types.h>
#endif

#ifdef SYSV
#include <fcntl.h>
#else
#include <sys/msgbuf.h>
#endif

#if defined(__linux__)
#include <paths.h>
#endif


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

#if defined(SYSLOGD_PIDNAME)
  #undef _PATH_LOGPID
  #if defined(FSSTND)
    #define _PATH_LOGPID  _PATH_VARRUN SYSLOGD_PIDNAME
  #else
    #define _PATH_LOGPID  "/etc/" SYSLOGD_PIDNAME
  #endif
#else
  #ifndef _PATH_LOGPID
    #if defined(FSSTND)
      #define _PATH_LOGPID  _PATH_VARRUN "syslogd.pid"
    #else
      #define _PATH_LOGPID  "/etc/syslogd.pid"
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

