#!/bin/bash
# Run LSD in Docker and open it in the browser.
#   ./run.sh            start (builds the image the first time)
#   ./run.sh stop       stop LSD
#   ./run.sh rebuild    rebuild the image and recreate the container
#   ./run.sh uninstall  remove the container and the image (the Work folder is kept)
#
# Optional settings, given in front of the command:
#   LSD_TAG=9.0-beta-3 ./run.sh rebuild    use another LSD release
#   LSD_PORT=6081 ./run.sh                  use another port
#   LSD_NAME=lsd2 ./run.sh                  use another container name
#   LSD_NO_OPEN=1 ./run.sh                  do not open the browser

set -e
cd "$(dirname "$0")"

LSD_TAG="${LSD_TAG:-8.1-stable-5}"
PORT="${LSD_PORT:-6080}"
NAME="${LSD_NAME:-lsd}"
IMAGE="lsd-desktop:$LSD_TAG"
URL="http://localhost:$PORT"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. Get Docker Desktop from https://www.docker.com/products/docker-desktop/"
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    echo "Docker is installed but not running. Start Docker Desktop and try again."
    exit 1
fi

build() {
    echo "Building LSD $LSD_TAG. The first build takes 5 to 10 minutes."
    docker build --build-arg LSD_TAG="$LSD_TAG" -t "$IMAGE" .
}

case "$1" in
    stop)
        docker stop "$NAME"
        exit 0
        ;;
    uninstall)
        docker rm -f "$NAME" 2>/dev/null || true
        docker rmi "$IMAGE" 2>/dev/null || true
        echo "Removed. Your models in the Work folder are untouched."
        exit 0
        ;;
    rebuild)
        docker rm -f "$NAME" 2>/dev/null || true
        build
        ;;
    ""|start)
        ;;
    *)
        echo "Unknown command: $1 (use start, stop, rebuild or uninstall)"
        exit 1
        ;;
esac

if docker container inspect "$NAME" >/dev/null 2>&1; then
    docker start "$NAME" >/dev/null
else
    docker image inspect "$IMAGE" >/dev/null 2>&1 || build
    mkdir -p Work
    # 127.0.0.1: the desktop is reachable from this computer only.
    # SYS_PTRACE: lets LSD's debugger (gdb) attach to a running model.
    docker run -d --name "$NAME" \
        -p "127.0.0.1:$PORT:6080" \
        -v "$PWD/Work:/home/lsd/LSD/Work" \
        --cap-add=SYS_PTRACE \
        --shm-size=512m \
        "$IMAGE" >/dev/null
fi

# Wait until the desktop answers, at most 30 seconds.
for _ in $(seq 1 30); do
    curl -s -o /dev/null "http://localhost:$PORT/vnc.html" && break
    sleep 1
done

echo "LSD is running. Open: $URL"
if [ -z "$LSD_NO_OPEN" ]; then
    if command -v open >/dev/null 2>&1; then open "$URL"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL"; fi
fi
