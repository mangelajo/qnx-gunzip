# gunzip — a gzip decompression filter, built for a QNX aarch64 target.
#
# Built from:
#   - this source (gunzip.c, start.S)
#   - standard C/POSIX headers (include/)
#   - a minimal JSON symbol manifest (stubs/*.min.json)  <- source of truth
#   - open tooling: aarch64-elf-gcc (GCC) + ld.lld (LLVM) + stubs/so_stub.py
#
# The stub .so files are build artifacts (gitignored). At runtime, the
# target's dynamic linker resolves the SONAMEs (libc.so.5, libz.so.2) to
# the libraries present on the system.

CC      := aarch64-elf-gcc
LD      := ld.lld
CFLAGS  := -I include
LDFLAGS := -dynamic-linker /usr/lib/ldqnx-64.so.2
STUBDIR := stubs

.PHONY: all clean stubs
all: gunzip

# build the minimal stub .so from the minimal JSON (artifacts, gitignored)
stubs:
	python3 stubs/so_stub.py $(STUBDIR)/libc.min.json -o $(STUBDIR)/libc.min.so_stub.so
	python3 stubs/so_stub.py $(STUBDIR)/libz.min.json -o $(STUBDIR)/libz.min.so_stub.so

gunzip: gunzip.o start.o stubs
	$(LD) -o $@ gunzip.o start.o -L$(STUBDIR) -l:libc.min.so_stub.so -l:libz.min.so_stub.so $(LDFLAGS)

gunzip.o: gunzip.c
	$(CC) $(CFLAGS) -c $< -o $@

start.o: start.S
	$(CC) -c $< -o $@

clean:
	rm -f gunzip gunzip.o start.o $(STUBDIR)/*.so_stub.so*
