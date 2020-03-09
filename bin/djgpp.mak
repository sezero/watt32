#
#  GNU Makefile for Waterloo TCP sample applications
#  Gisle Vanem 1997
#
#  Target:
#     GNU C 2.7+  (djgpp2 Dos extender)
#

.SUFFIXES: .exe .pro

# Set to 1 to link to import library (DXE3 module)
#
DYNAMIC = 0

# Set to 1 to make a profiling version
#
PROFILE = 0

#
# Use YAMD malloc debugger (for developement versions only)
#
USE_YAMD = 0

#
# Special exception handler
#
USE_EXCEPT = 0

#
# Set to 1 to make DPMI-host (cwsdstub.exe) contained in .exe-file
#
DPMI_STUB = 0

#
# Define 'MAKE_MAP = 1' if you like a .map-file
#
MAKE_MAP = 0

prefix ?= /dev/env/DJDIR/net/watt

INC_DIR = ../inc

ifeq ($(DYNAMIC),1)
  CFLAGS   = -DDYNAMIC
  USE_YAMD = 0
  PROFILE  = 0
  WATTLIB  = ../lib/impwatt.a
else
  WATTLIB = ../lib/libwatt.a
  EXTRAS  = tiny.c
endif

CC      = gcc
CFLAGS += -Wall -W -Wno-sign-compare -g -O2 -I$(INC_DIR) #-s # strip symbols from .exe

ifeq ($(USE_EXCEPT),1)
  CFLAGS += -DUSE_EXCEPT
  EXTRAS += d:/prog/mw/except/lib/libexc.a
endif

#
# Change '-o' to '-e' for gcc 4.3 (?) or older.
#
ifeq ($(MAKE_MAP),1)
  LINK = $(DJDIR)/bin/redir -o $*.map $(CC) -Wl,--print-map,--sort-common,--cref
else
  LINK = $(CC)
endif


PROGS = ping.exe     popdump.exe  rexec.exe   tcpinfo.exe cookie.exe \
        daytime.exe  dayserv.exe  finger.exe  host.exe    lpq.exe    \
        lpr.exe      ntime.exe    ph.exe      stat.exe    htget.exe  \
        revip.exe    tracert.exe  tcptalk.exe vlsm.exe    whois.exe  \
        bping.exe    uname.exe    blather.exe lister.exe  wol.exe    \
        eth-wake.exe ident.exe    country.exe

all: $(PROGS)
	@echo Protected-mode (djgpp2) binaries done

ifeq ($(USE_YAMD),1)
  CFLAGS += -DYAMD_VERSION=\"0.32\" -Wl,--wrap,malloc,--wrap,realloc,--wrap,free
  EXTRAS += yamd.c
endif

dxe_tst.exe: dxe_tst.c ../lib/dxe/libwatt.a
	$(CC) $(CFLAGS) $*.c ../lib/dxe/libwatt.a -o $*.exe

tracert.exe: EXTRAS += -DUSE_GEOIP geoip.c

%.exe: %.c ../lib/libwatt.a
ifeq ($(PROFILE),1)
	$(LINK) $(CFLAGS) -pg $*.c $(EXTRAS) $(WATTLIB) -o $*.pro
	stubify $*.pro
        #
        # run "prog.exe [args]" as usual, then generate profile by
        # "gprof prog.pro > prog.res"
        #
else
ifeq ($(DPMI_STUB),1)
	$(LINK) $(CFLAGS) -s $*.c $(EXTRAS) $(WATTLIB) -o $*
	@copy /b $(subst /,\,$(DJDIR))\bin\cwsdstub.exe + $* $*.exe
	@del $*
else
	$(LINK) $(CFLAGS) $*.c $(EXTRAS) $(WATTLIB) -o $*.exe
endif
endif

$(PROGS): $(WATTLIB)

clean:
	rm -f *.o $(PROGS)

install: ping.exe tcpinfo.exe
	-mkdir -p "$(prefix)/bin"
	cp -f ./ping.exe ./tcpinfo.exe "$(prefix)/bin"
	@echo Install to $(prefix) done
