# LSD in Docker

Run [LSD](https://github.com/marcov64/Lsd) (Laboratory for Simulation Development) on a Mac without installing it. LSD runs in a Linux container and you use it in a browser tab.

## Why

LSD 9.0 lists macOS as unsupported, and its readme recommends a virtual machine for Mac users. The Mac installers are Intel programs that macOS blocks by default. On an Apple Silicon Mac with macOS 26, the installer started without ever showing a window.

This setup uses the Linux version of LSD, which is supported, and compiles it for your processor.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/), installed and running
- About 2 GB of free disk space
- An internet connection for the first start

## Start

Open Terminal in this folder and run:

```bash
./run.sh
```

The first start builds the image and takes 5 to 10 minutes. After that it starts in a few seconds. LSD opens in your browser at <http://localhost:6080/vnc.html?autoconnect=1&resize=remote>.

| Command | What it does |
|---|---|
| `./run.sh` | Start LSD and open it in the browser |
| `./run.sh stop` | Stop LSD |
| `./run.sh rebuild` | Build the image again and start fresh |
| `./run.sh uninstall` | Remove the container and the image |

## Where your models are stored

Save your models in the group **Work in Progress**. That group is the `Work` folder next to this file, so it is stored on your own computer and survives everything, including `uninstall`.

Everything else lives inside the container. Changes to the example models survive `stop` and start, but `rebuild` and `uninstall` delete them. To keep a changed example, copy it into Work in Progress with the copy and paste buttons in the LSD Model Browser.

## Another LSD version

The default is `9.0-beta-3`. To use another release, give its tag from the [LSD releases page](https://github.com/marcov64/Lsd/releases):

```bash
LSD_TAG=8.1-stable-5 ./run.sh rebuild
```

`9.0-beta-3` and `8.1-stable-5` build and start. Use one `Work` folder per version, since the two versions store model groups differently.

## Good to know

- **Copy and paste** between your computer and LSD goes through the clipboard button in the panel on the left edge of the browser tab.
- **One viewer at a time.** The desktop resizes to the browser window that views it. A second tab or window on the same address makes it jump between sizes.
- **No password.** The desktop is only reachable from your own computer. Do not change the `127.0.0.1` in `run.sh` on a shared network.
- **The Help menu** opens in NetSurf, a small browser inside the container.

## Troubleshooting

| Problem | What to do |
|---|---|
| "Docker is installed but not running" | Start Docker Desktop and wait until it reports that it is running |
| The browser tab shows "Failed to connect" | Wait a few seconds and reload. If it persists, run `./run.sh stop` and then `./run.sh` |
| Port 6080 is in use | Start with another port: `LSD_PORT=6081 ./run.sh` |
| A gray area surrounds the desktop | Close other tabs that show LSD, then resize the browser window slightly |
| A model fails to compile with an error about `-march` | In LMM, open Model, System Options, and remove the `-march=native` entry |

## What is tested

Tested on an Apple Silicon Mac (macOS 26.6, Docker 29.2). With LSD 9.0-beta-3: a build from zero, LMM starts, the Random Walk example compiles and runs, and the manual opens from the container's browser. With LSD 8.1-stable-5: LMM starts, and the Logistic Chaos example compiles and starts.

Not tested: Intel Macs, the debugger, Gnuplot plots, parallel runs, and LSD versions other than these two.

## How it works

| File | Purpose |
|---|---|
| `Dockerfile` | Ubuntu 24.04 with the packages from the LSD readme, the LSD source from the official release, and a browser desktop (TigerVNC, Openbox, noVNC) |
| `start-desktop.sh` | Runs inside the container: starts the desktop and LMM |
| `run.sh` | Runs on your computer: builds, starts and stops the container |

One change is made to LSD during the build. On processors other than Intel and AMD, the compiler flag `-march=corei7-avx` is removed from `src/makefile`, since it only exists for Intel processors.

## Credits

LSD is written by Marco Valente and Marcelo Pereira and is distributed under the GNU General Public License. This folder contains no LSD code. The build downloads LSD from its official repository.
