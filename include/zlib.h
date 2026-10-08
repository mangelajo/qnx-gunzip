#ifndef _ZLIB_H
#define _ZLIB_H
/* Minimal zlib.h (matches libz.so.2 = zlib 1.2.x). */
#include <sys/types.h>

typedef unsigned char  Byte;
typedef unsigned int   uInt;
typedef unsigned long  uLong;
typedef void         (*alloc_func)(void *opaque, void *ptr, uInt items, uInt size);
typedef void         (*free_func)(void *opaque, void *ptr, uInt size);

typedef struct z_stream_s {
    Byte    *next_in;
    uInt     avail_in;
    uLong    total_in;
    Byte    *next_out;
    uInt     avail_out;
    uLong    total_out;
    char    *msg;
    void    *state;
    alloc_func zalloc;
    free_func  zfree;
    void    *opaque;
    int     data_type;
    uLong   adler;
    uLong   reserved;
} z_stream;

#define Z_NULL       0
#define Z_OK         0
#define Z_STREAM_END 1
#define Z_NO_FLUSH   0
#define Z_BUF_ERROR  (-5)
#define ZLIB_VERSION "1.2.13"

int  inflateInit2_(z_stream *strm, int windowBits, const char *version, int stream_size);
int  inflate(z_stream *strm, int flush);
int  inflateEnd(z_stream *strm);
const char *zError(int err);

/* These are macros in real zlib; the exported symbols carry a trailing '_'. */
#define inflateInit2(strm, windowBits) \
        inflateInit2_((strm), (windowBits), ZLIB_VERSION, (int)sizeof(z_stream))
#endif
