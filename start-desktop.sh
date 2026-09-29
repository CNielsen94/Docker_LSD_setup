#!/bin/bash
# Runs inside the container: starts the virtual screen, the browser bridge and LMM.

export DISPLAY=:1
LSDROOT="$HOME/LSD"

# The Work folder is shared with the Mac. Fill it with LSD's defaults the first time.
if [ ! -f "$LSDROOT/Work/group.cfg" ]; then
    cp -rn "$HOME/Work.default/." "$LSDROOT/Work/"
fi

# Remove leftovers from a previous run, then start the virtual screen.
# No VNC password: the port is only published to this Mac (127.0.0.1), see run.sh.
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
Xtigervnc :1 -geometry "${GEOMETRY:-1600x900}" -depth 24 \
    -SecurityTypes None -localhost yes -AlwaysShared &
sleep 2

openbox &
websockify --web /usr/share/novnc 6080 localhost:5901 &

# Keep LMM open: if it is closed, it comes back after a moment.
cd "$LSDROOT"
while true; do
    ./LMM
    sleep 2
done
