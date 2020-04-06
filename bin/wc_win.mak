#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom Win32 executables.
#
#  Usage: 'wmake -h -f wc_win.mak'
#

MODEL   = flat
CC      = *wcc386 -3r
CFLAGS  = -bt=nt -mf -oaxt -DWIN32 -DWATT32_STATIC
LFLAGS  = system nt
LIBRARY = library ../lib/wattcpww.lib

BUILD_MESSAGE = Watcom/Win32 binaries done

!include wccommon.mak
