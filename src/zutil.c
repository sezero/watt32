/* zutil.c -- target dependent utility functions for the compression library
 * Copyright (C) 1995-2003 Jean-loup Gailly.
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

/* @(#) $Id$ */

#include "wattcp.h"
#include "zutil.h"

#if defined(USE_GZIP)

#ifndef NO_DUMMY_DECL
struct internal_state   { int dummy; }; /* for buggy compilers */
#endif

const char * const z_errmsg[10] = {
"need dictionary",     /* Z_NEED_DICT       2  */
"stream end",          /* Z_STREAM_END      1  */
"",                    /* Z_OK              0  */
"file error",          /* Z_ERRNO         (-1) */
"stream error",        /* Z_STREAM_ERROR  (-2) */
"data error",          /* Z_DATA_ERROR    (-3) */
"insufficient memory", /* Z_MEM_ERROR     (-4) */
"buffer error",        /* Z_BUF_ERROR     (-5) */
"incompatible version",/* Z_VERSION_ERROR (-6) */
""};


const char * ZEXPORT zlibVersion (void)
{
    return ZLIB_VERSION;
}

uLong ZEXPORT zlibCompileFlags (void)
{
    uLong flags;

    flags = 0;
    switch (sizeof(uInt)) {
    case 2:     break;
    case 4:     flags += 1;     break;
    case 8:     flags += 2;     break;
    default:    flags += 3;
    }
    switch (sizeof(uLong)) {
    case 2:     break;
    case 4:     flags += 1 << 2;        break;
    case 8:     flags += 2 << 2;        break;
    default:    flags += 3 << 2;
    }
    switch (sizeof(voidpf)) {
    case 2:     break;
    case 4:     flags += 1 << 4;        break;
    case 8:     flags += 2 << 4;        break;
    default:    flags += 3 << 4;
    }
    switch (sizeof(z_off_t)) {
    case 2:     break;
    case 4:     flags += 1 << 6;        break;
    case 8:     flags += 2 << 6;        break;
    default:    flags += 3 << 6;
    }
#ifdef DEBUG
    flags += 1 << 8;
#endif
#if defined(ASMV) || defined(ASMINF)
    flags += 1 << 9;
#endif
#ifdef ZLIB_WINAPI
    flags += 1 << 10;
#endif
#ifdef BUILDFIXED
    flags += 1 << 12;
#endif
#ifdef DYNAMIC_CRC_TABLE
    flags += 1 << 13;
#endif
#ifdef NO_GZCOMPRESS
    flags += 1 << 16;
#endif
#ifdef NO_GZIP
    flags += 1 << 17;
#endif
#ifdef PKZIP_BUG_WORKAROUND
    flags += 1 << 20;
#endif
#ifdef FASTEST
    flags += 1 << 21;
#endif

#ifdef NO_vsnprintf
      flags += 1 << 25;
#  ifdef HAS_vsprintf_void
      flags += 1 << 26;
#  endif
#else
#  ifdef HAS_vsnprintf_void
      flags += 1 << 26;
#  endif
#endif

    return flags;
}

#ifdef DEBUG

#  ifndef verbose
#    define verbose 0
#  endif
int z_verbose = verbose;

void z_error (char *m)
{
    fprintf(stderr, "%s\n", m);
    exit(1);
}
#endif

/* exported to allow conversion of error code to string for compress() and
 * uncompress()
 */
const char * ZEXPORT zError (int err)
{
    return ERR_MSG (err);
}

#if defined(_WIN32_WCE)
    /* does not exist on WCE */
    int errno = 0;
#endif

#ifndef HAVE_MEMCPY

void zmemcpy (Bytef* dest, const Bytef* source, uInt len)
{
    if (len == 0)
       return;
    do {
        *dest++ = *source++; /* ??? to be unrolled */
    } while (--len != 0);
}

int zmemcmp (const Bytef* s1, const Bytef* s2, uInt len)
{
    uInt j;

    for (j = 0; j < len; j++) {
      if (s1[j] != s2[j])
        return (2 * (s1[j] > s2[j]) - 1);
    }
    return 0;
}

void zmemzero (Bytef* dest, uInt len)
{
    if (len == 0)
       return;
    do {
        *dest++ = 0;  /* ??? to be unrolled */
    } while (--len != 0);
}
#endif


#ifdef SYS16BIT

#ifdef M_I86
/* Microsoft C in 16-bit mode */

#  define MY_ZCALLOC

#if (!defined(_MSC_VER) || (_MSC_VER <= 600))
#  define _halloc  halloc
#  define _hfree   hfree
#endif

voidpf zcalloc (voidpf opaque, unsigned items, unsigned size)
{
    if (opaque) opaque = 0; /* to make compiler happy */
    return _halloc((long)items, size);
}

void  zcfree (voidpf opaque, voidpf ptr)
{
    if (opaque) opaque = 0; /* to make compiler happy */
    _hfree(ptr);
}

#endif /* M_I86 */

#endif /* SYS16BIT */


#ifndef MY_ZCALLOC /* Any system without a special alloc function */

voidpf zcalloc (voidpf opaque, unsigned items, unsigned size)
{
    if (opaque)
       items += size - size; /* make compiler happy */
    return sizeof(uInt) > 2 ? (voidpf)malloc(items * size) :
                              (voidpf)calloc(items, size);
}

void  zcfree (voidpf opaque, voidpf ptr)
{
    free(ptr);
    if (opaque)
       return;   /* make compiler happy */
}
#endif /* MY_ZCALLOC */
#endif /* USE_GZIP */

