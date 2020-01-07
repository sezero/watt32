#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom-16 real-mode (large/small) executables.
#
#  Usage: 'wmake -f watcom.mak'
#

.EXTENSIONS:
.EXTENSIONS: .exe .obj .c

MODEL = l  # (s)mall or (l)arge model

CC     = *wcc
CFLAGS = -m$(MODEL) -w6 -d2 -zq -zc -zm -I..\inc -fr=nul &
         -bt=dos #-dMAKE_TSR

LINK   = *wlink
LFLAGS = option quiet, map, stack=15k, eliminate, caseexact &
         system dos debug all sort global library ..\lib\wattcpw$(MODEL).lib

PROGS = ping.exe    popdump.exe rexec.exe   tcpinfo.exe &
        cookie.exe  daytime.exe dayserv.exe finger.exe  &
        host.exe    lpq.exe     lpr.exe     ntime.exe   &
        ph.exe      stat.exe    htget.exe   tcpport.exe &
        uname.exe   tracert.exe whois.exe   blather.exe &
        lister.exe  vlsm.exe    revip.exe

all:  $(PROGS)
      @echo Watcom/real-mode (model = $(MODEL)) binaries done

.c.exe: .PRECIOUS
      $(CC) $(CFLAGS) $*.c
      $(LINK) $(LFLAGS) name $*.exe file $*.obj

clean:
      @del *.obj
      @del *.map

