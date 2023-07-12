#
# Makefile for WatTCP syslog daemon
#
# Ken Yap <ken@nlc.net.au>
#
SRC         = syslogd.c pidfile.c ntp.c # snprintf.c

BORLAND_EXE = syslogd.exe
PHARLAP_EXP = syslogd.exp
WATCOM_EXE  = syslogd4.exe
DIGMARS_EXE = syslogd2.exe
QUICKC_EXE  = nul

!include ..\common.mak

HEADERS = pidfile.h portable.h version.h

syslogd.obj:  syslogd.c $(HEADERS)
pidfile.obj:  pidfile.c $(HEADERS)
snprintf.obj: snprintf.c
ntp.obj:      ntp.c ntp.h

syslogd.o32:  syslogd.c $(HEADERS)
pidfile.o32:  pidfile.c $(HEADERS)
snprintf.o32: snprintf.c
ntp.o32:      ntp.c ntp.h

syslogd.wo:   syslogd.c $(HEADERS)
pidfile.wo:   pidfile.c $(HEADERS)
snprintf.wo:  snprintf.c
ntp.wo:       ntp.c ntp.h

syslogd.do:   syslogd.c $(HEADERS)
pidfile.do:   pidfile.c $(HEADERS)
snprintf.do:  snprintf.c
ntp.do:       ntp.c ntp.h

