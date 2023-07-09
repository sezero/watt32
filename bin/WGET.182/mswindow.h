/* Declarations for windows
   Copyright (C) 1995, 1997, 1997, 1998 Free Software Foundation, Inc.

This file is part of GNU Wget.

GNU Wget is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

GNU Wget is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Wget; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

In addition, as a special exception, the Free Software Foundation
gives permission to link the code of its release of Wget with the
OpenSSL project's "OpenSSL" library (or with modified versions of it
that use the same license as the "OpenSSL" library), and distribute
the linked executables.  You must obey the GNU General Public License
in all respects for all of the code used other than "OpenSSL".  If you
modify this file, you may extend this exception to your version of the
file, but you are not obligated to do so.  If you do not wish to do
so, delete this exception statement from your version.  */

#ifndef MSWINDOWS_H
#define MSWINDOWS_H

/* Apparently needed for alloca(). */
#include <malloc.h>

#ifdef WATT32
  #include <sys/socket.h>
#else
  #include <winsock.h>
#endif

#ifndef S_ISDIR
#define S_ISDIR(m) (((m) & (_S_IFMT)) == (_S_IFDIR))
#endif

#ifndef S_ISLNK
#define S_ISLNK(a) 0
#endif

/* No stat on Windows.  */
#define lstat stat

#define PATH_SEPARATOR '\\'

/* Microsoft says stat is _stat, Borland doesn't */
#ifdef _MSC_VER
#define stat _stat
#endif

#ifdef HAVE_ISATTY
  /* Microsoft VC supports _isatty; Borland ? */
  #ifdef _MSC_VER
  #define isatty _isatty
  #endif
#endif

#undef  REALCLOSE
#define REALCLOSE(x) closesocket (x)

#define READ(fd, buf, cnt)  recv ((fd), (buf), (cnt), 0)
#define WRITE(fd, buf, cnt) send ((fd), (buf), (cnt), 0)

#ifndef __CYGWIN__
  /* #### Do we need this?  */
  #include <direct.h>

  /* Windows compilers accept only one arg to mkdir. */
  #ifndef __BORLANDC__
  # define mkdir(a, b) _mkdir(a)
  # define MKDIR(a, b) _mkdir(a)
  #else  /* __BORLANDC__ */
  # define mkdir(a, b) mkdir(a)
  # define MKDIR(a, b) mkdir(a)
  #endif /* __BORLANDC__ */
#endif   /* __CYGWIN__ */

#include <windows.h>

/* Redefine only the socket errors we use */

#ifndef WATT32
  #undef  ETIMEDOUT
  #undef  ECONNREFUSED
  #define ETIMEDOUT        WSAETIMEDOUT
  #define ECONNREFUSED     WSAECONNREFUSED
#endif

/* Public functions.  */
#if !defined(__MINGW32__) && !defined(__CYGWIN__)
unsigned int sleep (unsigned);
#endif

void ws_startup (void);
void ws_changetitle (char*, int);
char *ws_mypath (void);
void windows_main_junk (int *, char **, char **);

#endif /* MSWINDOWS_H */
