#!/bin/sh
set -e
ARGS="--config-dir /config --foreground"

if [ -n "$TRANSMISSION_WATCH_DIR" ]; then
    ARGS="$ARGS --watch-dir $TRANSMISSION_WATCH_DIR"
fi

if [ -n "$TRANSMISSION_DOWNLOAD_DIR" ]; then
    ARGS="$ARGS --download-dir $TRANSMISSION_DOWNLOAD_DIR"
fi

exec transmission-daemon $ARGS "$@"
