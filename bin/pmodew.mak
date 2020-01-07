#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom386 + Pmode/W executables.
#

.EXTENSIONS:
.EXTENSIONS: .exe .obj .c

COMPILE = *wcc386 -mf -3r -w5 -d2 -zq -oilrtf -I..\inc -fr=nul -bt=dos

LINK = *wlink option quiet, map, verbose, eliminate, caseexact, stack=50k &
         debug all system pmodew
#        system pmodew option osname='PMODE/W', stub=pmodew.exe           &
#        format os2 le libpath                                            &
#        $(%watcom)\lib386 libpath $(%watcom)\lib386\dos


LIBRARY = library ..\lib\wattcpwf.lib

PROGS = ping.exe    popdump.exe rexec.exe  tcpinfo.exe cookie.exe  &
        daytime.exe dayserv.exe finger.exe host.exe    lpq.exe     &
        lpr.exe     ntime.exe   ph.exe     stat.exe    htget.exe   &
        revip.exe   tracert.exe uname.exe  vlsm.exe    whois.exe   &
        blather.exe lister.exe


all:  $(PROGS)
      @echo Watcom386/PmodeW binaries done

.c.exe: .PRECIOUS
      $(COMPILE) $*.c
      $(LINK) name $*.exe file $*.obj $(LIBRARY)

clean:
      @del *.obj
      @del *.map

