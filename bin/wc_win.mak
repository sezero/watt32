#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom Win32 executables.
#
#  Usage: 'wmake -h -f wc_win.mak'
#

#
# Turn off these:
# wlink  Warning! W1027: file clib3r.lib(strerror.c): redefinition of strerror_ ignored
#

CC     = *wcc386
CFLAGS = -bt=nt -3r -wx -d2 -zq -zc -zm -fo=.obj -I"../inc" -DWIN32 -DWATT32_STATIC
LINK   = *wlink
LFLAGS = debug all system nt option eliminate &
         option quiet, map disable 1027 &
         library ../lib/wattcpww.lib

PROGS = ping.exe     popdump.exe rexec.exe   tcpinfo.exe &
        cookie.exe   daytime.exe dayserv.exe finger.exe  &
        host.exe     lpq.exe     lpr.exe     ntime.exe   &
        ph.exe       stat.exe    htget.exe   revip.exe   &
        uname.exe    tracert.exe whois.exe   blather.exe &
        lister.exe   ident.exe   vlsm.exe                &
        con-test.exe gui-test.exe

all:  $(PROGS) .SYMBOLIC
      @echo Watcom/Win32 binaries done

con-test.exe: w32-test.c .PRECIOUS
      $(CC) $(CFLAGS) $[@
      $(LINK) $(LFLAGS) runtime console name $^@ file $[&.obj

gui-test.exe: w32-test.c .PRECIOUS
      $(CC) $(CFLAGS) -DIS_GUI $[@
      $(LINK) $(LFLAGS) runtime windows name $^@ file $[&.obj

.c.exe: .PRECIOUS
      $(CC) $(CFLAGS) $[@
      $(LINK) $(LFLAGS) name $^@ file $[&.obj

clean: .SYMBOLIC
      -@del *.obj
      -@del *.map
      -@del $(PROGS)

