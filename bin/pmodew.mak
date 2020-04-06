#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom386 + Pmode/W executables.
#

#
# Turn off these:
# wlink  Warning! W1027: file clib3r.lib(strerror.c): redefinition of strerror_ ignored
#

CC     = *wcc386
CFLAGS = -bt=dos -mf -3r -wx -d2 -zq -oilrtf -fo=.obj -I"../inc" -DWATT32_STATIC
LINK   = *wlink
LFLAGS = debug all system pmodew option stack=50k, eliminate &
         option quiet, map, verbose disable 1027
#        system pmodew option osname='PMODE/W', stub=pmodew.exe           &
#        format os2 le libpath                                            &
#        $(%watcom)\lib386 libpath $(%watcom)\lib386\dos


LIBRARY = library ../lib/wattcpwf.lib

PROGS = ping.exe    popdump.exe rexec.exe  tcpinfo.exe cookie.exe  &
        daytime.exe dayserv.exe finger.exe host.exe    lpq.exe     &
        lpr.exe     ntime.exe   ph.exe     stat.exe    htget.exe   &
        revip.exe   tracert.exe uname.exe  vlsm.exe    whois.exe   &
        blather.exe lister.exe


all:  $(PROGS) .SYMBOLIC
      @echo Watcom386/PmodeW binaries done

.c.exe: .PRECIOUS
      $(CC) $(CFLAGS) $[@
      $(LINK) $(LFLAGS) name $^@ file $*.obj $(LIBRARY)

clean: .SYMBOLIC
      @del *.obj
      @del *.map
      @del $(PROGS)

