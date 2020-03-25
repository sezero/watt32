#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom386/Causeway executables.
#

.EXTENSIONS:
.EXTENSIONS: .exe .obj .c

COMPILE = *wcc386 -mf -3r -w5 -d2 -zq -zm -of -I..\inc -fr=nul -bt=dos
LINK    = *wlink
LFLAGS  = option quiet, map, verbose, eliminate, caseexact, stack=50k &
          debug all system causeway # zrdx

#
# Turn off these:
#   Warning! W1027: file clib3r.lib(strerror.c): redefinition of strerror_ ignored
#
LFLAGS += disable 1027

LIBRARY = library ..\lib\wattcpwf.lib

PROGS = ping.exe    popdump.exe rexec.exe   tcpinfo.exe cookie.exe  &
        daytime.exe dayserv.exe finger.exe  host.exe    lpq.exe     &
        lpr.exe     ntime.exe   ph.exe      stat.exe    htget.exe   &
        revip.exe   tracert.exe uname.exe   vlsm.exe    whois.exe   &
        blather.exe lister.exe  ident.exe

all:  $(PROGS) .SYMBOLIC
      @echo Watcom386/Causeway binaries done

.c.exe: .PRECIOUS
      $(COMPILE) $*.c
      $(LINK)  $(LFLAGS) name $*.exe file $*.obj $(LIBRARY)

clean: .SYMBOLIC
      - rm -f *.obj *.map



