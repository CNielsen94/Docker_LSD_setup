# Hand-off notes

For whoever maintains or debugs this setup next, human or coding agent. The README explains how to use it. This file explains how it is built, what was verified, and where it is likely to break.

Last updated 2026-09-29.

## Purpose

Run LSD (Laboratory for Simulation Development, <https://github.com/marcov64/Lsd>) on a Mac by building the Linux version in a container and showing its desktop in a browser tab.

## Background

Findings from the machine this was built on: Apple Silicon, macOS 26.6.2, Docker 29.2.1.

| Attempt | Result |
|---|---|
| Mac installer 8.1-stable-5 | Intel binary with bundled Tk 8.6.10. The process started under Rosetta and no window appeared |
| Mac installer 9.0-beta-3 | Intel binary with bundled Tk 8.6.18. Its readme titles the section "macOS installation (UNSUPPORTED)", reports success up to macOS 15.7, and recommends a virtual machine. The install was not completed |
| Linux build in Docker, native ARM64 | Works |

Do not spend time on the native Mac install unless upstream changes its position.

## Architecture

```
Browser tab  ->  localhost:6080  ->  websockify + noVNC  ->  Xtigervnc display :1  ->  Openbox  ->  LMM
```

| File | Runs on | Role |
|---|---|---|
| `run.sh` | Host | Checks Docker, builds the image, creates or starts the container, opens the browser |
| `Dockerfile` | Build | Ubuntu 24.04, LSD source from the release tag, compile, NetSurf |
| `start-desktop.sh` | Container | Seeds `Work`, starts the display, the window manager, the web bridge, and LMM in a restart loop |

Paths inside the container:

| Path | Content |
|---|---|
| `/home/lsd/LSD` | LSD root |
| `/home/lsd/LSD/Work` | Bind mount of `./Work` on the host |
| `/home/lsd/Work.default` | Copy of LSD's original `Work` folder, used to seed an empty mount |

The image is tagged `lsd-desktop:<LSD_TAG>`. The container is named `lsd` unless `LSD_NAME` is set.

## Decisions and the reasons for them

| Decision | Reason |
|---|---|
| Source tarball of the release tag, not the Linux installer package | The installer is a Tk program that needs a display and user input, so it cannot run during `docker build` |
| `gnu/`, `installer/`, `lwi/`, `Rpkg/`, `*.app`, `*.exe` excluded when unpacking | The tarball is about 300 MB and 1 GB unpacked. `gnu/` alone is 876 MB of Windows compiler |
| `make -C src`, not `make` in the LSD root | The root makefile also builds the web interface in `lwi/`, which is excluded |
| `-march=corei7-avx` removed from `src/makefile` on processors other than x86_64 | The flag exists only for Intel and AMD processors, and GCC on ARM rejects it |
| `Work.default` stored outside the LSD root | LMM lists every folder in the LSD root that contains a `group.cfg` as a model group. A copy inside the root appeared as a second "Work in Progress" |
| noVNC, not X11 forwarding | Nothing to install on the Mac, and XQuartz would be one more component that can fail |
| NetSurf as browser | In Ubuntu 24.04 the `firefox` package is a stub for the snap, which does not run in a container, and `chromium` has no package |
| `update-alternatives` call for `x-www-browser` | LSD opens help with `x-www-browser` (`browserLinux` in `src/defaults.tcl`). The NetSurf package does not register that name |
| Port bound to `127.0.0.1` and VNC without password | The desktop is reachable from the host only. Anything wider needs authentication first |
| `--cap-add=SYS_PTRACE` | Needed for gdb to attach to a process inside a container |
| NetSurf installed in a late layer | Keeps the download and compile layers cached when the browser step changes |
| Container kept between runs, no `--rm` | Compiled example models and LMM settings survive `stop` and start |

## Verified

All on the machine described above, with LSD 9.0-beta-3.

| Check | Method |
|---|---|
| Image builds | `docker build`, about 4.5 minutes on the first run |
| LMM and LSD are ARM64 binaries | LSD's own log window reports `Platform: Unix (aarch64)` |
| LMM window shows | Viewed through noVNC |
| A model compiles and runs | Random Walk example, Model, Compile and Run. `libLSD.so` was produced and the LSD Browser opened |
| `g++ -march=native` works in the container | Compiled a test file. LSD's `system_options-linux.txt` uses this flag for models |
| Manual renders in NetSurf | Opened `Manual/LSD_documentation.html` through `x-www-browser` |
| New `run.sh` | Started a second container with `LSD_NAME=lsd-test LSD_PORT=6081 LSD_NO_OPEN=1` |

## Not verified

| Item | Note |
|---|---|
| Build without cache | Every build after the first reused cached layers |
| Intel Mac or any x86_64 host | The patch step is skipped there. `-march=corei7-avx` needs AVX, which should be present on Intel Macs from 2011 onwards |
| LSD 8.1-stable-5 or other tags | `LSD_TAG` is passed through, but folder names, makefiles and the patch may differ between versions |
| Help menu clicked inside LMM | Only the command behind it was tested |
| gdb, Gnuplot, multitail, parallel runs, Python interface | Packages are installed, nothing was run |
| Linux hosts | `run.sh` falls back to `xdg-open`. Bind mount ownership may need attention, since the container user has uid 1001 and Docker on Linux does not translate ownership the way Docker Desktop does |

## Known behaviour

- **The desktop has one size for all viewers.** The URL uses `resize=remote`, so the display resizes to the browser window. A second viewer with a smaller window shrinks it for everyone. This includes automated browsers used by agents for testing. Close extra viewers and resize the window to recover.
- **Viewers share mouse and keyboard.** Do not drive the GUI for tests while a person is working in it. Start a second container on another port.
- **LMM restarts when closed.** `start-desktop.sh` runs it in a loop. Stop the container to end the session.
- **Example models are not persistent.** Only `Work` is mounted from the host.
- **LSD 9.0 stores model options in `model.cfg`.** There is no `model_options.txt` in the example folders, so older instructions for building a model makefile by hand do not apply. Compile through LMM.

## Testing without disturbing a running session

```bash
LSD_NAME=lsd-test LSD_PORT=6081 LSD_NO_OPEN=1 ./run.sh
docker exec lsd-test bash -c 'pgrep -l LMM; readlink -f /usr/bin/x-www-browser'
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:6081/vnc.html
docker rm -f lsd-test
```

Expected: a line with `LMM`, the path `/usr/bin/netsurf-gtk`, and `200`.

A full test also opens the desktop on port 6081, picks Example Models, Other Models, Random Walk, and runs Model, Compile and Run. Success is an LSD Browser window titled `Sim1`.

Useful commands:

```bash
docker logs lsd                      # output of the display, window manager and web bridge
docker exec -it lsd bash             # shell as the lsd user
docker exec -u root -it lsd bash     # shell as root
```

The xkbcomp warnings about unresolved keysyms in `docker logs` are harmless.

## Open tasks

1. Build from zero with `docker build --no-cache` and confirm a first run works for a new user.
2. Build `LSD_TAG=8.1-stable-5` on ARM64 and adjust the patch step if it fails.
3. Test on an Intel Mac.
4. Click through Help in LMM and confirm NetSurf opens from the menu.
5. Test gdb and Gnuplot from inside LSD.
6. Choose a licence for the scripts in this repository.
7. Consider publishing a prebuilt image so users skip the build. LSD is under the GPL, so a published image has to meet its terms for distributing binaries.

## Rules for changes

- Keep the scripts small. The users are researchers, not Docker specialists.
- Keep the README free of claims that were not tested. Move a line from "Not verified" to "Verified" only after running the check.
- Do not bundle LSD source or binaries in this repository. The build downloads them from upstream.
- Do not widen the port binding or add remote access without authentication.
