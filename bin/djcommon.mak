#
# djcommon.mak: make rules for Watt-32 binaries (djgpp2)
#
# Notes: This file requires GNU Make 3.75 or later
#        This file requires a non-Unix shell.
#        This file is only used by 'makefile' under './bin'.
#        Not in './bin' itself. Refer 'djgpp.mak' for that.
#
# by Gisle Vanem 1997 - 2024
#
MAKEFLAGS += --warn-undefined-variables

.SUFFIXES: .l .y .exe
.PHONY:    check_src check_exe check_gcc

#
# If building on Windows or Linux, '$(DJGPP_PREFIX)-gcc' should become
# something like 'i586-pc-msdosdjgpp-gcc' or a full path like
# 'f:/gv/djgpp/bin/i586-pc-msdosdjgpp-gcc'.
#
# If building on plain old DOS, it is simply 'gcc' which 'make' should
# find on %PATH.
#
ifneq ($(DJGPP_PREFIX),)
  BIN_PREFIX     = $(DJGPP_PREFIX)-
  MACHINE_PREFIX = i586-pc-msdosdjgpp
else ifeq ($(OS),Windows_NT)
  $(error Define a DJGPP_PREFIX to invoke the djgpp cross compiler).
else
  #
  # A 'gcc -dumpmachine' on plain DOS, should print 'djgpp'.
  #
  MACHINE_PREFIX  = djgpp
endif

#
# In case %DJDIR is not set under Windows. Why would it exist?
#
DJDIR ?= e:/djgpp

#
# Normally a '-Wall' would suite us.
#
USE_Wall ?= 1

#
# Default to off for these. See below.
#
CWSDPMI_STUB  ?= 0
GENERATED     ?=
LDFLAGS       ?=
MAKE_MAP      ?= 0
NO_OPTIMIZE   ?= 0
PREREQUISITES ?=
PACK_EXE      ?= 0
STRIP_EXE     ?= 0
USE_YAMD      ?= 0

#
# Override any Unix-like SHELL set in environment or djgpp.env
# At least "make depend" needs a DOS-style shell. Specifically
# the "sed" command doesn't work with `SHELL=/bin/sh' or `bash'.
#
# MAKESHELL = command.com  # doesn't have the wanted effect
# SHELL = $(COMSPEC)       # doesn't work
#
CC_SRC ?=

ifeq ($(SRC),)
  ifeq ($(CC_SRC),)
check_src:
	@echo \"SRC\" or \"CC_SRC\" not defined.
	@echo Define \"SRC = C-files\".. or \"CC_SRC = CC-files\".. before including DJCOMMON.MAK
  endif
endif

ifeq ($(DJGPP_EXE),)
check_exe:
	@echo \"DJGPP_EXE\" not defined. Define \"DJGPP_EXE = file.exe\".. before including DJCOMMON.MAK
endif

OBJS    += $(SRC:.c=.o)
CC_OBJS += $(CC_SRC:.cc=.o)

WATT32_ROOT = $(realpath $(WATT_ROOT))
WATTLIB     = $(WATT32_ROOT)/lib/libwatt.a
MAP_FILE    = $(DJGPP_EXE:.exe=.map)

CC = $(BIN_PREFIX)gcc

ifeq ($(USE_Wall),1)
  CFLAGS += -Wall
endif

CFLAGS += -g -DWATT32 -I$(WATT32_ROOT)/inc \
          -Wno-unused-variable             \
          -Wno-strict-aliasing

ifneq ($(CC_SRC),)
  LDFLAGS += -lstdcxx
endif

#
# Define 'NO_OPTIMIZE = 1' to ease debugging
#
ifeq ($(NO_OPTIMIZE),1)
  CFLAGS += -O0
else
  CFLAGS += -O2
endif

#
# These stupid '$GCC_COLORS' messed up my shell big-time.
# Turn colours off.
#
ifeq ($(USER),gv)
  CFLAGS += -fdiagnostics-color=never
endif

#
# Define 'STRIP_EXE = 1' if you like a smaller .exe-file (DJGPP_EXE)
# Define 'PACK_EXE = 1' to also compress using UPX .exe-packer
#
ifeq ($(STRIP_EXE),1)
  LDFLAGS += -s
endif

ifeq ($(PACK_EXE),1)
  LDFLAGS += -s
endif

#
# Define 'MAKE_MAP = 1' if you like a .map-file
# Change '-o' to '-e' for gcc 4.3 (?) or older.
#
ifeq ($(MAKE_MAP),1)
  LINK ?= $(DJDIR)/bin/redir -o $(MAP_FILE) $(CC) -Wl,--print-map,--sort-common,--cref
else
  LINK ?= $(CC)
endif

#
# Define 'USE_YAMD = 1' to include a malloc debugged version
#
ifeq ($(USE_YAMD),1)
  CFLAGS  += -DYAMD_VERSION=\"0.32\"
  LDFLAGS += -Wl,--wrap,malloc,--wrap,realloc,--wrap,free
  SRC     += ../yamd.c
endif

all: check_gcc $(PREREQUISITES) $(DJGPP_EXE)

#
# Define 'CWSDPMI_STUB = 1' to make a DPMI-host contained .exe-file
#
$(DJGPP_EXE): $(OBJS) $(CC_OBJS) $(WATTLIB)
ifeq ($(CWSDPMI_STUB),1)
	$(LINK) $^ $(strip $(LDFLAGS))
	@copy /b $(subst /,\,$(DJDIR))\bin\cwsdstub.exe + a.out $@
	@del a.out
else
	$(LINK) $^ -o $@ $(strip $(LDFLAGS))
endif
ifeq ($(PACK_EXE),1)
	@upx -9 $@
endif

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.cc
	$(CC) -x c++ -c $(CFLAGS) -fno-rtti -fno-exceptions -o $@ $<

clean:
	rm -f $(OBJS) $(CC_OBJS) $(DJGPP_EXE:.exe=.map)

vclean scrub dist-clean: clean
	rm -f $(DJGPP_EXE) $(GENERATED)

depend: $(PREREQUISITES)
	@echo Generating dependencies..
	echo "# Generated by djcommon.mak"    > depend.dj
	$(CC) -MM $(CFLAGS) $(SRC) $(CC_SRC) >> depend.dj

check_gcc:
ifneq ($(shell $(BIN_PREFIX)gcc -dumpmachine), $(MACHINE_PREFIX))
	@echo '$(BIN_PREFIX)gcc seems not to be djgpp compiled. Maybe your $$PATH is wrong?'
else
	@echo '$(BIN_PREFIX)gcc seems OK'
endif

