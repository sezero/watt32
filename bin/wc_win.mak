#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom Win32 executables.
#
#  Usage: 'wmake -f wc_win.mak'
#

.EXTENSIONS:
.EXTENSIONS: .exe .obj .c

CC     = *wcc386
CFLAGS = -bt=nt -3s -w6 -d2 -zq -zc -zm -I..\inc -fr=nul -DWIN32

LINK   = *wlink
LFLAGS = option quiet, map, eliminate, caseexact &
         system nt debug all sort global library ..\lib\wattcpww_imp.lib

PROGS = ping.exe     popdump.exe rexec.exe   tcpinfo.exe &
        cookie.exe   daytime.exe dayserv.exe finger.exe  &
        host.exe     lpq.exe     lpr.exe     ntime.exe   &
        ph.exe       stat.exe    htget.exe   revip.exe   &
        uname.exe    tracert.exe whois.exe   blather.exe &
        lister.exe   ident.exe   vlsm.exe                &
        con-test.exe gui-test.exe

all:  $(PROGS)
      @echo Watcom/Win32 binaries done

con-test.exe: w32-test.c .PRECIOUS
      $(CC) $(CFLAGS) w32-test.c
      $(LINK) $(LFLAGS) runtime console name con-test.exe file w32-test.obj

gui-test.exe: w32-test.c .PRECIOUS
      $(CC) $(CFLAGS) -DIS_GUI w32-test.c
      $(LINK) $(LFLAGS) runtime windows name gui-test.exe file w32-test.obj

.c.exe: .PRECIOUS
      $(CC) $(CFLAGS) $*.c
      $(LINK) $(LFLAGS) name $*.exe file $*.obj

clean:
      -@del *.obj
      -@del *.map

