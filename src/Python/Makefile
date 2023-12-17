#
# A GNU Makefile for _watt32.pyd - A simple Python module
# for Watt-32 library.
#
# Supports MSVC, clang-cl or MinGW (MinGW little tested).
# Needs SWIG and off-course Python 2/3 to build and test.
#
define Usage

  Usage:
    make CC=[cl | clang-cl | gcc] <PYTHON="py -2.x" | "py -3.x"> <WATT32_STATIC=1> [all | clean | vclean | install]'
      CC=gcc      - use MinGW
      CC=cl       - use MSVC
      CC=clang-cl - use clang-cl
endef

#
# Using the Python Launcher argument 'PYTHON="py -x.y"', in a 'make py_info'
# invokations, things could look like this:
#
#   %WATT_ROOT%\src\Python> make CC=cl PYTHON="py -2" py_info
#   PY_ROOT:      F:/ProgramFiler/Python27.
#   PY_MAJOR_VER: 2.
#   PY_MINOR_VER: 7.
#
#   %WATT_ROOT%\src\Python> make CC=cl PYTHON="py -3.6" py_info
#   PY_ROOT:      f:/ProgramFiler/Python36.
#   PY_MAJOR_VER: 3.
#   PY_MINOR_VER: 6.
#
#   %WATT_ROOT%\src\Python> make CC=cl PYTHON="py -3.9" py_info
#   PY_ROOT:      f:/ProgramFiler/Python36.
#   PY_MAJOR_VER: 3.
#   PY_MINOR_VER: 9.
#
#   %WATT_ROOT%\src\Python> make CC=cl PYTHON="py -3" py_info
#   PY_ROOT:      F:/ProgramFiler/Python310.
#   PY_MAJOR_VER: 3.
#   PY_MINOR_VER: 10.
#
# A 'PYTHON="py -3"', reporting Python 3.9 just means that the default
# Python version 3 is '3.9'. Allthough one have a version 3.6 installed
# as non-default.
#

export CL=

#
# The 'CPU' MUST match the bitness of chosen 'PYTHON'.
# E.g. if you run 'make CC=cl PYTHON="py -2"' and your Python 2.x is 32-bit,
# call the 'vcvarsall.bat x86' first.
#
CPU ?= x86

ifeq ($(CPU),x86)
  BITS          = 32
  WINDRES_FLAGS = --target=pe-i386

else ifeq ($(CPU),x64)
  BITS          = 64
  WINDRES_FLAGS = --target=pe-x86-64
else
  $(error CPU must be 'x86' or 'x64')
endif

#
# The only option at the moment:
#
WATT32_STATIC ?= 1

#
# Could be set in envronment of on the cmd-line:
#
PYTHON ?= py -3

PY_ROOT      = $(realpath  $(shell $(PYTHON) -c "import sys; print (sys.prefix)"))
PY_MAJOR_VER = $(shell $(PYTHON) -c "import sys; print(sys.version_info.major)" )
PY_MINOR_VER = $(shell $(PYTHON) -c "import sys; print(sys.version_info.minor)" )

ifeq ($(CC),cl)
  OBJ_DIR = MSVC_obj
  CFLAGS  = -nologo -MD -Ox -Zi -W3
  RCFLAGS = -nologo -D_MSC_VER
  LDFLAGS = -nologo -debug -dll -map -verbose -incremental:no -nodefaultlib:uuid.lib -libpath:$(PY_ROOT)/libs
  PY_LIB  = $(wildcard $(PY_ROOT)/libs/python$(PY_MAJOR_VER)*.lib)

else ifeq ($(CC),clang-cl)
  OBJ_DIR = clang_obj
  CFLAGS  = -nologo -MD -Ox -Zi -W3
  RCFLAGS = -nologo -D__clang__
  LDFLAGS = -nologo -debug -dll -map -verbose -incremental:no -nodefaultlib:uuid.lib -libpath:$(PY_ROOT)/libs
  PY_LIB  = $(wildcard $(PY_ROOT)/libs/python$(PY_MAJOR_VER)*.lib)

else ifeq ($(CC),gcc)
  OBJ_DIR = gcc_obj
  CFLAGS  =  -m$(BITS) -Wall -O2 -s
  RCFLAGS = -O COFF -D__MINGW32__ $(WINDRES_FLAGS)
  LDFLAGS = -m$(BITS) -s -shared -static-libgcc -Wl,--print-map
  PY_LIB  = $(wildcard $(PY_ROOT)/libs/libpython$(PY_MAJOR_VER)*.a)

else
  $(error $(Usage))
endif

RCFLAGS += -I../../inc \
           -I$(PY_ROOT)/include

CFLAGS  += -I.. -I../../inc     \
           -I$(PY_ROOT)/include \
           -DPy_ENABLE_SHARED   \
           -DSWIG

# CFLAGS += -DSWIG_LINK_RUNTIME \
#           -DSWIGRUNTIME_DEBUG

#
# Without a '-DSWIG_PYTHON_SILENT_MEMLEAK', there is this exception:
#   TypeError: in method '_ping', argument 2 of type 'DWORD'
#   swig/python detected a memory leak of type 'DWORD *', no destructor found.
#
CFLAGS += -DSWIG_PYTHON_SILENT_MEMLEAK

ifneq ($(CC),cl)
  CFLAGS += -Wno-unused-function \
            -Wno-visibility
endif

ifeq ($(WATT32_STATIC),1)
  CFLAGS += -DWATT32_STATIC

  ifeq ($(CC),cl)
    W32_LIB = ../../lib/$(CPU)/wattcpvc.lib
  else ifeq ($(CC),clang-cl)
    W32_LIB = ../../lib/$(CPU)/wattcp_clang.lib
  else
    W32_LIB = ../../lib/$(CPU)/libwatt32.a
  endif

  ifeq ($(CC),gcc)
    OS_LIBS = -luser32 -ladvapi32
  else
    OS_LIBS = user32.lib advapi32.lib
  endif

else
  CFLAGS  += -DWATT32_BUILD
  OS_LIBS =

  ifeq ($(CC),cl)
    W32_LIB = ../../lib/$(CPU)/wattcpvc_imp.lib
  else ifeq ($(CC),clang-cl)
    W32_LIB = ../../lib/$(CPU)/wattcp_clang_imp.lib
  else
    W32_LIB = ../../lib/$(CPU)/libwatt32.dll.a
  endif
endif

SWIG_FLAGS = -macroerrors -python $(filter -D% -I%, $(CFLAGS)) # -nodefaultctor -nodefaultdtor -debug-symbols
SWIG_FLAGS += -w451 -w454

all: py_info py_check _watt32.pyd epilogue

epilogue:
	$(call green_msg, Do a $(BRIGHT_WHITE)$(PYTHON) ./runme.py -d www.google.com $(BRIGHT_GREEN)to test it.)
	$(call green_msg, Do a $(BRIGHT_WHITE)make CC=$(CC) install $(BRIGHT_GREEN)to install it.)

py_info:
	$(call green_msg, Detected Python variables:)
	$(call green_msg0,  PY_ROOT:      $(BRIGHT_WHITE)$(PY_ROOT).)
	$(call green_msg0,  PY_MAJOR_VER: $(BRIGHT_WHITE)$(PY_MAJOR_VER).)
	$(call green_msg0,  PY_MINOR_VER: $(BRIGHT_WHITE)$(PY_MINOR_VER).)

py_check:
ifeq ($(PY_LIB),)
	$(error A suiteable 'PY_LIB' was not found)
else
	$(call green_msg0,  PY_LIB:       $(BRIGHT_WHITE)$(PY_LIB).)
endif

_watt32.pyd: $(OBJ_DIR)/watt32_swig_wrap.o $(OBJ_DIR)/_watt32.res $(W32_LIB) $(PY_LIB) | check-for-unused-libs.py
	$(call link_PYD, $@, $^ $(OS_LIBS))

$(OBJ_DIR)/_watt32.res: _watt32.rc | $(OBJ_DIR)
	$(call create_res, $@, $<)

$(OBJ_DIR)/watt32.py: $(OBJ_DIR)/watt32_swig_wrap.c

$(OBJ_DIR)/watt32_swig_wrap.c: watt32_swig.i | $(OBJ_DIR)
	$(call green_msg, Generating Swig wrapper $@)
	swig $(SWIG_FLAGS) -o $@ watt32_swig.i
	@echo

$(OBJ_DIR)/%.o: $(OBJ_DIR)/%.c | $(OBJ_DIR)
	$(call compile, $@, $<)

$(OBJ_DIR):
	mkdir $@

clean:
	rm -f link.tmp check-for-unused-libs.py *.pdb *.pyc vc1*.pdb \
	   _watt32.{exp,lib,map,pyc} watt32.pyo
	rm -fr $(OBJ_DIR) __pycache__

vclean realclean: clean
	rm -f _watt32.pyd

install: _watt32.pyd $(OBJ_DIR)/watt32.py
	cp --update $(OBJ_DIR)/watt32.py  $(PY_ROOT)/Lib/site-packages
	cp --update _watt32.pyd           $(PY_ROOT)/DLLs
ifneq ($(CC),gcc)
	cp --update _watt32.pdb  $(PY_ROOT)/DLLs
endif

uninstall:
	rm -f $(PY_ROOT)/dlls/_watt32.{pyd,pdb}
	rm -f $(PY_ROOT)/Lib/site-packages/watt32.py

check-for-unused-libs.py: Makefile
	$(call green_msg, Generating $@)
	$(file >  $@,#!/usr/env/python)
	$(file >> $@,if 1:)
	$(file >> $@,$(check_for_unused_libs_PY))

#
# The dependency must be updated by hand.
#
$(OBJ_DIR)/watt32_swig_wrap.c: \
  ../../inc/sys/w32api.h       \
  ../wattcp.h                  \
  ../sock_ini.h                \
  ../pcdbug.h                  \
  ../pcicmp.h                  \
  ../pcdns.h                   \
  ../pctcp.h                   \
  ../misc.h                    \
  ../misc.c


#
# GNU-make macros:
#
# This assumes you have a MSys/Cygwin's 'echo.exe' program with ANSI colour support.
#
BRIGHT_GREEN = \e[1;32m
BRIGHT_WHITE = \e[1;37m
green_msg    = @echo -e "$(BRIGHT_GREEN)$(strip $(1))\e[0m"
green_msg0   = @echo -e "$(BRIGHT_GREEN)$(1)\e[0m"

ifeq ($(CC),gcc)
  define compile
    $(CC) -c $(CFLAGS) -o $(strip $(1) $(2))
    @echo
  endef

  define link_PYD
    $(call green_msg, Linking $(1))
    $(CC) -o $(1) $(LDFLAGS) $(2) > $(1:.pyd=.map)
    @echo
  endef

  define create_res
    windres -o $(1) $(RCFLAGS) $(2)
    @echo
  endef

else
  define compile
    $(CC) -c $(CFLAGS) -Fo$(strip $(1) $(2))
    @echo
  endef

  define link_PYD
    $(call green_msg, Linking $(1))
    link -out:$(strip $(1)) $(LDFLAGS) $(2) > link.tmp
    @cat link.tmp >> $(1:.pyd=.map)
    @rm -f $(1:.pyd=.exp) $(1:.pyd=.lib)
    @$(PYTHON) check-for-unused-libs.py link.tmp
  endef

  define create_res
    rc -Fo $(1) $(RCFLAGS) $(2)
    @echo
  endef
endif

define check_for_unused_libs_PY
  #
  # Check a MSVC .map-file for lines after a 'Unused libraries:'
  #
  import os, sys

  map_file    = sys.argv[1]
  ignore_libs = [ ]

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

  def report (unused):
    num = len(unused)
    plural = [ "library", "libraries" ]
    if num > 0:
       print ("%s%d unused %s in %s:%s" % (Color.RED, num, plural[num > 1], map_file, Color.RESET))
       for u in sorted(unused):
           print ("  " + u)
    print ("%sDone%s\n" % (Color.WHITE, Color.RESET))

  def process_map (state):
    unused_libs = []
    f = open (map_file, "rt")
    lines = f.readlines()
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

  report (process_map(State.IDLE))
endef

