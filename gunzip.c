#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <zlib.h>

/* gunzip filter: reads gzip from fd 0 (stdin), writes decompressed data to fd 1 (stdout).
   Usage: ./gunzip < file.gz > file.out
   Uses inflate() with 15+32 so zlib auto-skips the gzip header and trailer.
   Uses read()/write() on fds directly (portable; some libc variants do not export stdin/stdout/stderr). */

static void err(const char *s) { write(2, s, strlen(s)); }

int main(void) {
    z_stream strm;
    unsigned char in[1 << 16];
    unsigned char out[1 << 16];
    int rc, status = 0, eof = 0;
    ssize_t n;

    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.next_in = Z_NULL;
    strm.avail_in = 0;
    strm.next_out = Z_NULL;
    strm.avail_out = 0;

    if (inflateInit2(&strm, 15 + 32) != Z_OK) {
        err("inflateInit2 failed\n");
        return 1;
    }

    for (;;) {
        if (!eof) {
            strm.next_in = in;
            n = read(0, in, sizeof in);
            if (n <= 0) { eof = 1; strm.avail_in = 0; }
            else strm.avail_in = (uInt)n;
        }

        do {
            strm.next_out = out;
            strm.avail_out = sizeof out;
            rc = inflate(&strm, Z_NO_FLUSH);
            if (rc != Z_OK && rc != Z_STREAM_END && rc != Z_BUF_ERROR) {
                char msg[128];
                int mlen = snprintf(msg, sizeof msg, "inflate: %s\n", zError(rc));
                write(2, msg, mlen);
                status = 1;
                break;
            }
            write(1, out, sizeof out - strm.avail_out);
        } while (strm.avail_in > 0 && rc == Z_OK);

        if (status) break;
        if (rc == Z_STREAM_END) break;          /* gzip complete */
        if (eof && strm.avail_in == 0) break;  /* EOF, stream not ended */
    }

    inflateEnd(&strm);
    return status;
}
