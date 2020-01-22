#
#  GNU Makefile for some Waterloo TCP sample applications
#  Gisle Vanem 2004 - 2018
#
#  Target:
#    Clang-CL (Win32/Win64; depends on '%CPU%')
#
# Incase %CL is set, undefine it.
#
export CL=

#
# Set to 1 to link using a debug library:
#   ../lib/$(CPU)/wattcp_clang_imp_d.lib - for 'USE_STATIC_LIB = 0'
#   ../lib/$(CPU)/wattcp_clang_d.lib     - for 'USE_STATIC_LIB = 1'
#
USE_DEBUG_LIB ?= 1

#
# Set to 1 to link using static library:
#   ../lib/$(CPU)/wattcp_clang.lib    - for release
#   ../lib/$(CPU)/wattcp_clang_d.lib  - for debug
#
USE_STATIC_LIB ?= 0

CC = clang-cl

ifeq ($(USE_DEBUG_LIB),1)
  CFLAGS     = -MDd
  LIB_SUFFIX = _d
else
  CFLAGS     = -MD
  LIB_SUFFIX =
endif

CFLAGS += -W3 -O2 -I../inc -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS -D_CRT_OBSOLETE_NO_WARNINGS

#
# clang is rather picky on these things:
#
CFLAGS += -Wno-format-security          \
          -Wno-nonportable-include-path \
          -Wno-pointer-sign             \
          -Wno-pointer-sign             \
          -Wno-invalid-source-encoding

LDFLAGS = -nologo -map

ifeq ($(USE_STATIC_LIB),1)
  CFLAGS   += -DWATT32_STATIC
  WATT_LIB = ../lib/$(CPU)/wattcp_clang$(LIB_SUFFIX).lib
  EX_LIBS  = advapi32.lib user32.lib
else
  WATT_LIB = ../lib/$(CPU)/wattcp_clang_imp$(LIB_SUFFIX).lib
  EX_LIBS  =
endif

PROGS = ping.exe     popdump.exe  rexec.exe    tcpinfo.exe  cookie.exe   \
        daytime.exe  dayserv.exe  finger.exe   host.exe     lpq.exe      \
        lpr.exe      ntime.exe    ph.exe       stat.exe     htget.exe    \
        revip.exe    vlsm.exe     whois.exe    wol.exe      eth-wake.exe \
        ident.exe    country.exe  con-test.exe gui-test.exe tracert.exe

all: $(PROGS)
	@echo 'Clang-CL binaries done.'

con-test.exe: w32-test.c $(WATT_LIB)
	$(CC) -c $(CFLAGS) w32-test.c
	link $(LDFLAGS) -subsystem:console -out:$@ w32-test.obj $(WATT_LIB) $(EX_LIBS)
	@echo

gui-test.exe: w32-test.c $(WATT_LIB)
	$(CC) -c -DIS_GUI=1 $(CFLAGS) w32-test.c
	link $(LDFLAGS) -subsystem:windows -out:$@ w32-test.obj $(WATT_LIB) $(EX_LIBS)
	@echo

tracert.exe: tracert.c geoip.c $(WATT_LIB)
	$(CC) -c -DUSE_GEOIP $(CFLAGS) tracert.c geoip.c
	link $(LDFLAGS) -out:$@ tracert.obj geoip.obj $(WATT_LIB) $(EX_LIBS)
	@echo

%.exe: %.c $(WATT_LIB)
	$(CC) -c $(CFLAGS) $<
	link $(LDFLAGS) -out:$*.exe $*.obj $(WATT_LIB) $(EX_LIBS)
	@echo

clean:
	rm -f $(PROGS)

SOURCES = ping.c    popdump.c rexec.c   tcpinfo.c cookie.c   \
          daytime.c dayserv.c finger.c  host.c    lpq.c      \
          lpr.c     ntime.c   ph.c      stat.c    htget.c    \
          revip.c   vlsm.c    whois.c   wol.c     eth-wake.c \
          ident.c   country.c tracert.c w32-test.c

depend:
	$(CC) $(CFLAGS) -E -showIncludes $(SOURCES) > .depend.clang

-include .depend.clang

#
# These are needed for MSYS' make (sigh)
#
ping.exe:     ping.c
popdump.exe:  popdump.c
rexec.exe:    rexec.c
tcpinfo.exe:  tcpinfo.c
cookie.exe:   cookie.c
daytime.exe:  daytime.c
dayserv.exe:  dayserv.c
finger.exe:   finger.c
host.exe:     host.c
lpq.exe:      lpq.c
lpr.exe:      lpr.c
ntime.exe:    ntime.c
ph.exe:       ph.c
stat.exe:     stat.c
htget.exe:    htget.c
revip.exe:    revip.c
vlsm.exe:     vlsm.c
whois.exe:    whois.c
wol.exe:      wol.c
eth-wake.exe: eth-wake.c
ident.exe:    ident.c
country.exe:  country.c
tracert.exe:  tracert.c geoip.c
wol.exe:      wol.c

