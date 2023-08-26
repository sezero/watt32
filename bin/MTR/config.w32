/*
 * config.w32 for Watt-32 (djgpp/Watcom/MSVC)
 */
#ifndef __MTR_CONFIG_H
#define __MTR_CONFIG_H

#include <string.h>
#include <conio.h>    /* kbhit() */

#if defined(_MSC_VER) || defined(__WATCOMC__)
  #define strcasecmp(s1, s2) _stricmp (s1, s2)
  #include <process.h>
#else
  #define HAVE_UNISTD_H
#endif

/*
 * Pull in the Watt-32 functions
 * unless Winsock is used in 'Makefile.vc6'.
 */
#ifdef USE_WATT32
  #define WATT32_NO_GETOPT  /* don't use getopt in Watt-32 */

  #include <tcp.h>

  #undef byte
  #undef word
  #undef dword
#endif

/* Define if you don't have the GTK+ libraries available.  */
#define NO_GTK

#define select select_s
#define close  close_s

#define HAVE_SYS_TYPES_H
#define HAVE_CURSES_H
#define HAVE_ATTRON

#ifdef __DJGPP__
#define HAVE_SYS_TIME_H
#endif

/*  Define the version string.
 */
#define VERSION "0.4.1"

#endif
