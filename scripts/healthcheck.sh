#!/bin/sh
PORT=9091
if [ -f "/config/settings.json" ]; then
    CFG_PORT=$(jq -r '.["rpc-port"] // empty' /config/settings.json)
    if [ -n "$CFG_PORT" ]; then PORT=$CFG_PORT; fi
fi

CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${PORT})
if [ "$CODE" != "000" ]; then
    exit 0
else
    exit 1
fi
