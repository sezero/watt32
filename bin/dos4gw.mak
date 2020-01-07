#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom386/DOS4GW executables.
#

.EXTENSIONS:
.EXTENSIONS: .exe .obj .c

COMPILE = *wcc386 -mf -3r -w5 -d2 -zq -zm -of -I..\inc -fr=nul -bt=dos
LINK    = *wlink option quiet, map, verbose, eliminate, caseexact, stack=50k &
            debug all system dos4g

LIBRARY = library ..\lib\wattcpwf.lib

PROGS = ping.exe    popdump.exe rexec.exe   tcpinfo.exe cookie.exe  &
        daytime.exe dayserv.exe finger.exe  host.exe    lpq.exe     &
        lpr.exe     ntime.exe   ph.exe      stat.exe    htget.exe   &
        revip.exe   tracert.exe uname.exe   vlsm.exe    whois.exe   &
        blather.exe lister.exe  ident.exe


all:  $(PROGS) .SYMBOLIC
      @echo Watcom386/DOS4GW binaries done

.c.exe: .PRECIOUS
      $(COMPILE) $*.c
      $(LINK) name $*.exe file $*.obj $(LIBRARY)

clean:
      @del *.obj
      @del *.map

