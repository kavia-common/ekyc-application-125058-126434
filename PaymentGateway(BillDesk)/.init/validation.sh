#!/usr/bin/env bash
set -euo pipefail

# Validation: build, start static server in its own session, probe HTTP endpoint, stop cleanly
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126434/PaymentGateway(BillDesk)"
cd "$WORKSPACE"
export NODE_ENV=${NODE_ENV:-development}
export PORT=${PORT:-3000}

# Build (vite build via npm script)
npm run build --silent

# Ensure serve helper exists
[ -f ./scripts/serve.js ] || { echo "serve helper missing" >&2; exit 6; }

LOGFILE=$(mktemp -t pg_srv_log.XXXX)
# Start server in its own session so we can signal the whole PGID
setsid node ./scripts/serve.js >"$LOGFILE" 2>&1 &
PID=$!
# Get PGID for the started process
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
if [ -z "$PGID" ]; then
  kill "$PID" >/dev/null 2>&1 || true
  echo "unable to determine PGID" >&2
  exit 7
fi

# Probe HTTP with retries
MAX=30; SLEEP=1; OK=1
for i in $(seq 1 $MAX); do
  sleep $SLEEP
  HTTP_STATUS=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" http://127.0.0.1:${PORT} || true)
  if [ "$HTTP_STATUS" = "200" ]; then
    OK=0; break
  fi
done

if [ $OK -ne 0 ]; then
  echo "validation failed, status=${HTTP_STATUS:-none}" >&2
  echo "--- server log (last 200 lines) ---" >&2
  tail -n 200 "$LOGFILE" >&2 || true
  kill -TERM -"$PGID" >/dev/null 2>&1 || kill "$PID" >/dev/null 2>&1 || true
  rm -f "$LOGFILE"
  exit 8
fi

# Success: report succinct evidence
echo "validation ok: http_status=$HTTP_STATUS pid=$PID pgid=$PGID"

# Stop cleanly by terminating the process group
kill -TERM -"$PGID" >/dev/null 2>&1 || kill "$PID" >/dev/null 2>&1 || true
wait $PID 2>/dev/null || true
rm -f "$LOGFILE"
