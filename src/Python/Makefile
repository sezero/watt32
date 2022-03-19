#
# A GNU Makefile for _watt32.pyd - A simple Python module
# for Watt-32 library.
#
# Supports MSVC, clang-cl or MinGW (MinGW little tested).
# Needs SWIG and off-course Python 2/3 to build and test.
#
define Usage

  Usage:
    make CC=[cl | clang-cl | gcc] <PYTHON="py -2.x" | "py -3.x"> <STATIC=1> [all | clean | vclean]'
      CC=gcc      - use MinGW
      CC=cl       - use MSVC
      CC=clang-cl - use clang-cl
endef

#
# This assumes you have a MSys/Cygwin's 'echo.exe' program with ANSI colour support.
#
BRIGHT_GREEN = \e[1;32m
BRIGHT_WHITE = \e[1;37m

green_msg = @echo -e "$(BRIGHT_GREEN)$(strip $(1))\e[0m"

export CL=

STATIC ?= 1
PYTHON ?= py -3

PYTHON_ROOT = $(realpath  $(shell $(PYTHON) -c "import sys; print(sys.prefix)"))
PYTHON_VER  = $(shell $(PYTHON) -c "import os,sys; print('%c%c' % (sys.version[0], sys.version[2]))")

ifeq ($(CC),cl)
  CFLAGS  = -nologo -MD -Ox -EHsc -Zi -W3
  RCFLAGS = -nologo -D_MSC_VER
  LDFLAGS = -nologo -debug -dll -map -verbose -incremental:no -nodefaultlib:uuid.lib
  EX_LIBS = $(PYTHON_ROOT)/libs/python$(PYTHON_VER).lib

else ifeq ($(CC),clang-cl)
  CFLAGS  = -nologo -MD -Ox -EHsc -Zi -W3
  RCFLAGS = -nologo -D__clang__
  LDFLAGS = -nologo -debug -dll -map -verbose -incremental:no -nodefaultlib:uuid.lib
  EX_LIBS = $(PYTHON_ROOT)/libs/python$(PYTHON_VER).lib

else ifeq ($(CC),gcc)
  CFLAGS =  -m32 -Wall -O2 -s
  RCFLAGS = -O COFF -D__MINGW32__
  LDFLAGS = -m32 -s -shared -Wl,--print-map,--sort-common,--cref
  EX_LIBS  = $(PYTHON_ROOT)/libs/libpython$(PYTHON_VER).a

else
  $(error $(Usage))
endif

CFLAGS  += -I.. -I../../inc \
           -I$(PYTHON_ROOT)/include

# CFLAGS  += -DSWIG_LINK_RUNTIME

# CFLAGS += -DSWIGRUNTIME_DEBUG

#
# Without a '-DSWIG_PYTHON_SILENT_MEMLEAK', there is this exception:
#   TypeError: in method '_ping', argument 2 of type 'DWORD'
#   swig/python detected a memory leak of type 'DWORD *', no destructor found.
#
CFLAGS += -DSWIG_PYTHON_SILENT_MEMLEAK

ifeq ($(CC),clang-cl)
  CFLAGS += -Wno-unused-function \
            -Wno-visibility
endif

RCFLAGS += -I../../inc -DRC_PY_VER=\"$(PYTHON_VER)\"

ifeq ($(STATIC),1)
  CFLAGS += -DWATT32_STATIC
  ifeq ($(CC),cl)
    EX_LIBS += ../../lib/x86/wattcpvc.lib
  else ifeq ($(CC),clang-cl)
    EX_LIBS += ../../lib/x86/wattcp_clang.lib
  else
    EX_LIBS += ../../lib/x86/libwatt32.a
  endif

  ifeq ($(CC),gcc)
    SYS_LIBS += -luser32 -ladvapi32
  else
    SYS_LIBS += user32.lib advapi32.lib
  endif

else
  CFLAGS += -DWATT32_BUILD

  ifeq ($(CC),cl)
    EX_LIBS += ../../lib/x86/wattcpvc_imp.lib
  else ifeq ($(CC),clang-cl)
    EX_LIBS += ../../lib/x86/wattcp_clang_imp.lib
  else
    EX_LIBS += ../../lib/x86/libwatt32.dll.a
  endif
endif

SWIG_FLAGS = -macroerrors -Wall -python $(filter -D% -I%, $(CFLAGS)) # -nodefaultctor -nodefaultdtor -debug-symbols

# SWIG_FLAGS += -v -v

GENERATED = watt32_swig_wrap.c watt32.py check-for-unused-libs.py

all: py_info _watt32.pyd epilogue

epilogue:
	$(call green_msg, Do a $(BRIGHT_WHITE)$(PYTHON) ./runme.py -d www.google.com $(BRIGHT_GREEN)to test it.)

py_info:
	@echo '$$(PYTHON_ROOT): $(PYTHON_ROOT).'
	@echo '$$(PYTHON_VER):  $(PYTHON_VER).'

install: _watt32.pyd watt32.py
	cp --update _watt32.pyd $(PYTHON_ROOT)/DLLs
	cp --update watt32.py   $(PYTHON_ROOT)/Lib/site-packages

uninstall:
	rm -f $(PYTHON_ROOT)/dlls/_watt32.pyd
	rm -f $(PYTHON_ROOT)/Lib/site-packages/watt32.py

ifeq ($(CC),gcc)
  _watt32.pyd: watt32_swig_wrap.o _watt32.res $(EX_LIBS)
	$(call green_msg, Linking $@)
	$(CC) $(LDFLAGS) $^ -o $@ $(SYS_LIBS) > _watt32.map
	@rm -f _watt32.pyc
	@echo

  _watt32.res: _watt32.rc
	windres -o $@ $(RCFLAGS) $<
	@echo

else
  _watt32.pyd: watt32_swig_wrap.obj _watt32.res  $(EX_LIBS) | check-for-unused-libs.py
	$(call green_msg, Linking $@)
	link $(LDFLAGS) $^ -out:$@ $(SYS_LIBS) > link.tmp
	@cat link.tmp >> _watt32.map
	@rm -f _watt32.exp _watt32.lib
	@$(PYTHON) check-for-unused-libs.py link.tmp

  _watt32.res: _watt32.rc
	rc -Fo $@ $(RCFLAGS) $<
	@echo
endif

watt32.py: watt32_swig_wrap.c

watt32_swig_wrap.c: watt32_swig.i
	$(call green_msg, Gerating Swig wrapper $@)
	swig $(SWIG_FLAGS) -o $@ watt32_swig.i
	@echo

#
# The dependency must be updated by hand.
#
watt32_swig_wrap.c: ../wattcp.h ../sock_ini.h ../pcdbug.h \
                    ../pcdns.h  ../pctcp.h    ../misc.h

%.o: %.c
	$(CC) $(CFLAGS) -DSWIG -c $<
	@echo

%.obj: %.c
	$(CC) $(CFLAGS) -DSWIG -c $<
	@echo

clean:
	rm -f *.obj *.o *.pdb *.pyc *.res vc1*.pdb link.tmp $(GENERATED)

vclean realclean: clean
	rm -f _watt32.pyd _watt32.res _watt32.exp _watt32.lib _watt32.map watt32.pyo

check-for-unused-libs.py: Makefile
	$(call green_msg, Generating $@)
	$(file >  $@,#!/usr/env/python)
	$(file >> $@,if 1:)
	$(file >> $@,$(check_for_unused_libs_PY))

define check_for_unused_libs_PY
  #
  # Check a MSVC .map-file for lines after a 'Unused libraries:'
  #
  import os, sys

  class State():
    IDLE   = 0
    UNUSED = 1

  class Color():
    RED = WHITE = RESET = ""

  try:
    from colorama import init, Fore, Style
    init()
    Color.RED   = Fore.RED + Style.BRIGHT
    Color.WHITE = Fore.WHITE + Style.BRIGHT
    Color.RESET = Style.RESET_ALL
  except:
    pass

  ignore_libs = [ ]

  def report (map_file, unused):
    num = len(unused)
    plural = [ "library", "libraries" ]
    if num > 0:
      print ("%s%d unused %s in %s:%s" % (Color.RED, num, plural[num > 1], map_file, Color.RESET))
      for u in sorted(unused):
        print ("  " + u)
    print ("%sDone%s\n" % (Color.WHITE, Color.RESET))

  def process_map (file, state):
    unused_libs = []
    f = open (file, "rt")
    try:
      lines = f.readlines()
    except IOError:
      return []
    finally:
      f.close()

    for l in lines:
      l = l.strip()
      if l == "Unused libraries:":
        state = State.UNUSED
        continue
      if state == State.UNUSED:
        if l == "":
          break
        if os.path.basename (l).lower() not in ignore_libs:
          unused_libs.append (l)
    return unused_libs

  map_file = sys.argv[1]
  report (map_file, process_map(map_file, State.IDLE))
endef

