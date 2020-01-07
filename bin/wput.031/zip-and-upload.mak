ZIP_FILE = wput-031.zip
FILES    = INSTALL     \
           TODO        \
           ftp.[ch]    \
           getopt.[ch] \
           utils.[ch]  \
           wput.[ch]   \
           Makefile.dj \
           Makefile.MW \
           wput-nt.exe \
           wput32.exe

all:
	zip $(ZIP_FILE) $(FILES)
	wput-homepage -D -o -i $(ZIP_FILE) -d misc
