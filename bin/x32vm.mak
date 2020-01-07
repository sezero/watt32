#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom386/X32VM executables.
#

.EXTENSIONS:
.EXTENSIONS: .exe .obj .c

COMPILE = *wcc386 -mf -3r -w5 -d2 -zq -zm -of -I..\inc -fr=nul -bt=dos
LINK    = *wlink option quiet, map, verbose, eliminate, caseexact, stack=50k &
             debug all system x32vm option stub=$(DIGMARS)\lib\zlx.lod

LIBRARY = library ..\lib\wattcpwf.lib, $(DIGMARS)\lib\x32.lib

PROGS = ping.exe    popdump.exe rexec.exe   tcpinfo.exe cookie.exe  &
        daytime.exe dayserv.exe finger.exe  host.exe    lpq.exe     &
        lpr.exe     ntime.exe   ph.exe      stat.exe    htget.exe   &
        revip.exe   tracert.exe uname.exe   vlsm.exe    whois.exe   &
        blather.exe lister.exe


all:  $(PROGS)
      @echo Watcom386/X32VM binaries done

.c.exe: .PRECIOUS
      $(COMPILE) $*.c
      $(LINK) name $*.exe file $*.obj $(LIBRARY)

clean:
      @del *.obj
      @del *.map


