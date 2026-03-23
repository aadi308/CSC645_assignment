#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Edit this to your trigger + test SQL path (relative to project root).
# Or override when running: TRIGGER_SQL_FILE=YourFile.sql ./scripts/run_trigger_submission.sh
TRIGGER_SQL_FILE="${TRIGGER_SQL_FILE:-CHANGE_ME.sql}"

if [[ "${TRIGGER_SQL_FILE}" == "CHANGE_ME.sql" ]]; then
  echo "Edit scripts/run_trigger_submission.sh and set TRIGGER_SQL_FILE default,"
  echo "or run:  TRIGGER_SQL_FILE=YourFile.sql ./scripts/run_trigger_submission.sh"
  exit 1
fi

"${ROOT_DIR}/scripts/docker_sql.sh" all "${TRIGGER_SQL_FILE}"
