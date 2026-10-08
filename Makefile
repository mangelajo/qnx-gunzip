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
#
# Container build: `make container-build` builds the Containerfile with
# podman and runs the whole build inside it (fedora + cross toolchain).
#
# `make help` prints this file's `##`-annotated targets, grouped by
# `##@` section headers.

CC      := aarch64-elf-gcc
LD      := ld.lld
CFLAGS  := -I include
LDFLAGS := -dynamic-linker /usr/lib/ldqnx-64.so.2
STUBDIR := stubs

CONTAINER ?= podman
IMAGE     ?= gunzip-builder

.PHONY: all clean stubs container container-build help

##@ build
all: gunzip ## build gunzip (default)

gunzip: gunzip.o start.o stubs ## link the gunzip binary
	$(LD) -o $@ gunzip.o start.o -L$(STUBDIR) -l:libc.min.so_stub.so -l:libz.min.so_stub.so $(LDFLAGS)

# build the minimal stub .so from the minimal JSON (artifacts, gitignored)
stubs: ## build the stub .so files from the JSON manifests
	python3 stubs/so_stub.py $(STUBDIR)/libc.min.json -o $(STUBDIR)/libc.min.so_stub.so
	python3 stubs/so_stub.py $(STUBDIR)/libz.min.json -o $(STUBDIR)/libz.min.so_stub.so

gunzip.o: gunzip.c
	$(CC) $(CFLAGS) -c $< -o $@

start.o: start.S
	$(CC) -c $< -o $@

clean: ## remove all build artifacts
	rm -f gunzip gunzip.o start.o $(STUBDIR)/*.so_stub.so*

##@ container (podman)
container: ## build the fedora container image
	$(CONTAINER) build -t $(IMAGE) .

container-build: container ## build gunzip inside the container (GNU ld)
	$(CONTAINER) run --rm -v $(PWD):/src -w /src $(IMAGE) make \
	LD=aarch64-linux-gnu-ld STUB_LD=aarch64-linux-gnu-ld

help: ## show this help
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n\033[1;33m%s\033[0m\n", substr($$0, 5) } \
		/^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
