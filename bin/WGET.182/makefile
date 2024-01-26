#
# Makefile for `wget' utility
# Copyright (C) 1995, 1996, 1997 Free Software Foundation, Inc.
#
# Version: 1.8.2 (DOS)
#
# No SSL is available. Use makefile.dj for SSL version.
#
SRC = cmpt.c connect.c cookies.c fnmatch.c ftp-basi.c ftp-ls.c \
      ftp-opie.c ftp.c gen-md5.c gen_sslf.c getopt.c gnu-md5.c \
      hash.c headers.c host.c html-par.c html-url.c http.c     \
      init.c log.c main.c netrc.c progress.c rbuf.c recur.c    \
      res.c retr.c safe-cty.c snprintf.c url.c utils.c version.c

COMMON_DEFS = -I. -DHAVE_CONFIG_H
WCC386_DEFS = -wcd=124 -wcd=202

POWERPAK = 0

BORLAND_EXE = wget.exe
PHARLAP_EXP = wget.exp
WATCOM_EXE  = wget4.exe
DIGMARS_EXE = wget2.exe
QUICKC_EXE  = wget1.exe

!include "..\common.mak"

