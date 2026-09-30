# LSD (Laboratory for Simulation Development) with a desktop you open in a browser.
# Build and start with ./run.sh

FROM ubuntu:24.04

ARG LSD_TAG=8.1-stable-5
ENV DEBIAN_FRONTEND=noninteractive

# Line 1-2: packages the LSD readme lists for Debian/Ubuntu (section 4.2).
# Line 3-4: the browser desktop (virtual screen, window manager, noVNC).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential gdb gnuplot-qt multitail zlib1g-dev tcl-dev tk-dev \
        xterm python3-dev cython3 \
        tigervnc-standalone-server novnc websockify openbox \
        curl ca-certificates fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash lsd
USER lsd
WORKDIR /home/lsd

# Download LSD from the official release tag. The Windows compiler (gnu/), the
# Windows and macOS programs, and the web interface are left out: not used here.
RUN mkdir LSD \
    && curl -fsSL "https://github.com/marcov64/Lsd/archive/refs/tags/${LSD_TAG}.tar.gz" \
       | tar -xz --strip-components=1 -C LSD \
             --exclude="Lsd-${LSD_TAG}/gnu" \
             --exclude="Lsd-${LSD_TAG}/installer" \
             --exclude="Lsd-${LSD_TAG}/lwi" \
             --exclude="Lsd-${LSD_TAG}/Rpkg" \
             --exclude="Lsd-${LSD_TAG}/LMM.app" \
             --exclude="Lsd-${LSD_TAG}/LSD.app" \
             --exclude="*.exe" --exclude="*.exe.config" --exclude="*.bat"

# LSD ships Intel binaries. Rebuild them for the processor this image runs on.
# LSD 9 has src/makefile; "-march=corei7-avx" in it is an Intel-only compiler
# flag, so it is removed elsewhere. LSD 8 only needs LMM built, from makefile.LMM.
RUN cd LSD \
    && if [ -f src/makefile ]; then \
           if [ "$(uname -m)" != "x86_64" ]; then sed -i 's/ -march=corei7-avx//' src/makefile; fi \
           && make -C src clean \
           && make -C src -j"$(nproc)"; \
       else \
           rm -f LMM src/*.o \
           && make -C src -f makefile.LMM; \
       fi \
    && cp -r Work ../Work.default

# LSD shifts its windows 67 pixels up on Linux, to allow for a desktop top bar.
# This desktop has none, so the shift would hide the title bar and menu.
RUN sed -i 's/^set corrYlinux\([[:space:]]*\)-67/set corrYlinux\10/' LSD/src/defaults.tcl

# Web browser for LSD's Help menu. LSD opens help pages with "x-www-browser".
USER root
RUN apt-get update && apt-get install -y --no-install-recommends netsurf-gtk \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/netsurf-gtk 50

# Start page: http://localhost:6080 forwards to the LSD desktop.
RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=1&resize=remote">' \
    > /usr/share/novnc/index.html
USER lsd

COPY --chown=lsd:lsd --chmod=755 start-desktop.sh /home/lsd/start-desktop.sh

EXPOSE 6080
CMD ["/home/lsd/start-desktop.sh"]
