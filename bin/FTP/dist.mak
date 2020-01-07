#
# Make distribution .zip for dos-ftp
#

ZIPFILE = dosftp12.zip

pack_em:
	- wstrip ftp4.exe
	upx -9 ftp4.exe
	upx -9 ftp32.exe

all:
	pkzip $(ZIPFILE) *.c *.h *.l makefile.* fortify.doc eplf.txt -xshell?.c
	pkzip $(ZIPFILE) ftp32.exe ftp4.exe ftp.lng ftp.man ftp.ini readme.dos
