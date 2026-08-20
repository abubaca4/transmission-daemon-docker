#!/bin/sh
set -e

ARGS="--config-dir /config --foreground"

if [ -n "$TRANSMISSION_WATCH_DIR" ]; then
    ARGS="$ARGS --watch-dir $TRANSMISSION_WATCH_DIR"
fi

if [ -n "$TRANSMISSION_DOWNLOAD_DIR" ]; then
    ARGS="$ARGS --download-dir $TRANSMISSION_DOWNLOAD_DIR"
fi

if [ -n "$USER" ] && [ -n "$PASS" ]; then
    ARGS="$ARGS --auth --username $USER --password $PASS"
fi

if [ -n "$WHITELIST" ]; then
    ARGS="$ARGS --allowed $WHITELIST"
fi

if [ -n "$PEERPORT" ]; then
    ARGS="$ARGS --peerport $PEERPORT"
fi

if [ -n "$HOST_WHITELIST" ] || [ -n "$UMASK" ]; then

    if [ ! -f /config/settings.json ]; then
        transmission-daemon --config-dir /config --dump-settings > /config/settings.json
    fi

    TMP_SETTINGS=$(mktemp)
    cp /config/settings.json "$TMP_SETTINGS"

    if [ -n "$HOST_WHITELIST" ]; then
        jq --arg hw "$HOST_WHITELIST" \
           '.["rpc-host-whitelist-enabled"] = true | .["rpc-host-whitelist"] = $hw' \
           "$TMP_SETTINGS" > "${TMP_SETTINGS}.tmp" && mv "${TMP_SETTINGS}.tmp" "$TMP_SETTINGS"
    fi

    if [ -n "$UMASK" ]; then
        jq --arg umask "$UMASK" \
           '.["umask"] = ($umask | tonumber)' \
           "$TMP_SETTINGS" > "${TMP_SETTINGS}.tmp" && mv "${TMP_SETTINGS}.tmp" "$TMP_SETTINGS"
    fi

    mv "$TMP_SETTINGS" /config/settings.json
fi

exec transmission-daemon $ARGS "$@"
