# Hand-off

For a coding agent asked to get LSD running from this repository.

## What this is

A Docker image that runs LSD (Linux build) and shows its desktop in a browser tab. Default version: `8.1-stable-5`.

## Install Docker first

Assume the user has never used Docker. Check:

```bash
docker info
```

If the command is missing, Docker Desktop has to be installed. It is free for personal use and education.

1. Find the processor type: `uname -m` prints `arm64` for Apple Silicon and `x86_64` for Intel.
2. Have the user download the matching installer from <https://docs.docker.com/desktop/setup/install/mac-install/>. With Homebrew present, `brew install --cask docker-desktop` does the same.
3. The user opens `Docker.dmg` and drags Docker to the Applications folder.
4. The user starts Docker from Applications, accepts the agreement, and picks the recommended settings. Signing in to a Docker account can be skipped.
5. Wait until the whale icon in the menu bar stops moving, then run `docker info` again.

Steps 3 and 4 need the user: the agreement and the password prompt cannot be answered from a script.

If `docker info` says it cannot connect, Docker is installed but not started. Have the user open Docker from Applications.

## Boot it

From the repository folder:

```bash
./run.sh
```

The first run builds the image, which takes a few minutes. Then LSD is at:

<http://localhost:6080/vnc.html?autoconnect=1&resize=remote>

## Check that it works

```bash
docker ps --filter name=lsd
docker exec lsd pgrep -l LMM
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:6080/vnc.html
```

Expected: the container is up, a line with `LMM`, and `200`.

## Commands

| Command | Effect |
|---|---|
| `./run.sh` | Start |
| `./run.sh stop` | Stop |
| `./run.sh rebuild` | Rebuild the image and recreate the container |
| `./run.sh uninstall` | Remove container and image |
| `LSD_PORT=6081 ./run.sh` | Use another port |
| `LSD_TAG=9.0-beta-3 ./run.sh rebuild` | Use another LSD release |

## Things to know

- The user's models are in `Work/` on the host. Never delete that folder. Everything else in the container is lost on `rebuild` and `uninstall`.
- The desktop is shared. Opening it in a second browser, including an automated one, resizes the screen and shares the mouse with the user. Ask before doing that.
- The port is bound to `127.0.0.1` and has no password. Leave it that way.

## If it fails

| Symptom | Fix |
|---|---|
| `Docker is installed but not running` | Start Docker Desktop |
| Port 6080 in use | `LSD_PORT=6081 ./run.sh` |
| Browser shows "Failed to connect" | `docker logs lsd`, then `./run.sh stop` and `./run.sh` |
| Build fails at the download step | Check the tag exists at <https://github.com/marcov64/Lsd/releases> |
