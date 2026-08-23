#!/usr/bin/env bash
set -euo pipefail

GROUP_ID="${1:?group ID required}"
ACCOUNT="${SIGNAL_ACCOUNT:?SIGNAL_ACCOUNT not set}"
TOPIC="${NTFY_TOPIC:-unknown}"
TITLE="${NTFY_TITLE:-}"
MESSAGE="${NTFY_MESSAGE:-}"
ID="${NTFY_ID:-unknown}"

if [ -n "$TITLE" ]; then
    TEXT="[${TOPIC}] ${TITLE}: ${MESSAGE}"
else
    TEXT="[${TOPIC}] ${MESSAGE}"
fi

PAYLOAD=$(jq -n \
    --arg msg "$TEXT" \
    --arg num "$ACCOUNT" \
    --arg grp "$GROUP_ID" \
    '{"message": $msg, "number": $num, "recipients": [$grp]}')

if curl -sf -X POST \
    -H 'content-type: application/json' \
    -d "$PAYLOAD" \
    "http://signal-cli:8080/v2/send" > /dev/null; then
    echo "topic=${TOPIC} id=${ID} result=ok"
else
    echo "topic=${TOPIC} id=${ID} result=error"
    exit 1
fi
