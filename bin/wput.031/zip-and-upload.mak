ZIP_FILE = wput-031.zip

FILES = INSTALL          \
        TODO             \
        ftp.[ch]         \
        getopt.[ch]      \
        utils.[ch]       \
        wput.[ch]        \
        Makefile.dj      \
        Makefile.Windows \
        wput-w32.exe     \
        wput-w32.pdb     \
        wput-win.exe     \
        wput-win.pdb     \
        wput-dj.exe

FILES += $(addprefix msvc-missing/, \
           dirent.c                 \
           dirent.h                 \
           strings.h                \
           unistd.h)

all:
	zip $(ZIP_FILE) $(FILES)
	wput-homepage -D -o -i $(ZIP_FILE) -d misc
