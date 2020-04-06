#
#  Makefile for Waterloo TCP sample applications
#
#  Watcom386/DOS32A executables.
#

#
# Turn off these:
# wlink  Warning! W1027: file clib3r.lib(strerror.c): redefinition of strerror_ ignored
#

CC     = *wcc386
CFLAGS = -bt=dos -mf -3r -wx -d2 -zq -zm -of -s -fo=.obj -I..\inc -DWATT32_STATIC
LINK   = *wlink
LFLAGS = debug all system dos32a option stack=50k, eliminate &
         option quiet, map, verbose disable 1027

LIBRARY = library ..\lib\wattcpwf.lib

PROGS = ping.exe    popdump.exe rexec.exe   tcpinfo.exe cookie.exe  &
        daytime.exe dayserv.exe finger.exe  host.exe    lpq.exe     &
        lpr.exe     ntime.exe   ph.exe      stat.exe    htget.exe   &
        revip.exe   tracert.exe uname.exe   vlsm.exe    whois.exe   &
        blather.exe lister.exe  ident.exe

all:  $(PROGS) .SYMBOLIC
      @echo Watcom386/DOS32A binaries done

.c.exe: .PRECIOUS
      $(CC) $(CFLAGS) $[@
      $(LINK) $(LFLAGS) name $^@ file $[&.obj $(LIBRARY)

clean: .SYMBOLIC
      - rm *.obj *.map $(PROGS)


