#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="mcr.microsoft.com/mssql/server:2022-latest"
CONTAINER_NAME="frosty-sqlserver"

if [[ ! -f "${ROOT_DIR}/.env" ]]; then
  echo "Missing .env. Create it with MSSQL_SA_PASSWORD=YourStrongPassword123!"
  exit 1
fi

set -a
source "${ROOT_DIR}/.env"
set +a

if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
  echo "MSSQL_SA_PASSWORD is not set in .env"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  cat <<'EOF'
Usage:
  ./scripts/docker_sql.sh pull
  ./scripts/docker_sql.sh start
  ./scripts/docker_sql.sh setup
  ./scripts/docker_sql.sh run <sql_file>
  ./scripts/docker_sql.sh all <sql_file>
  ./scripts/docker_sql.sh down
EOF
  exit 1
fi

ACTION="$1"
shift || true

start_container() {
  if docker ps -a --format '{{.Names}}' | rg -x "${CONTAINER_NAME}" >/dev/null; then
    docker start "${CONTAINER_NAME}" >/dev/null
  else
    docker run -d \
      --name "${CONTAINER_NAME}" \
      -e ACCEPT_EULA=Y \
      -e MSSQL_PID=Developer \
      -e SA_PASSWORD="${MSSQL_SA_PASSWORD}" \
      -p 1433:1433 \
      -v "${ROOT_DIR}:/workspace" \
      "${IMAGE_NAME}" >/dev/null
  fi
}

wait_for_sql() {
  echo "Waiting for SQL Server to become ready..."
  until docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -C \
    -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SELECT 1" >/dev/null 2>&1; do
    sleep 2
  done
  echo "SQL Server is ready."
}

run_sql_file() {
  local file_path="$1"
  if [[ ! -f "${ROOT_DIR}/${file_path}" ]]; then
    echo "SQL file not found: ${file_path}"
    exit 1
  fi

  docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -C \
    -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" \
    -i "/workspace/${file_path}"
}

case "${ACTION}" in
  pull)
    docker pull "${IMAGE_NAME}"
    ;;
  start)
    start_container
    wait_for_sql
    ;;
  setup)
    docker pull "${IMAGE_NAME}"
    start_container
    wait_for_sql
    run_sql_file "IceCreamFactory_Setup.sql"
    echo "Database setup script executed."
    ;;
  run)
    if [[ $# -lt 1 ]]; then
      echo "Provide a sql file path relative to project root."
      exit 1
    fi
    run_sql_file "$1"
    ;;
  all)
    if [[ $# -lt 1 ]]; then
      echo "Provide a sql file path relative to project root."
      exit 1
    fi
    docker pull "${IMAGE_NAME}"
    start_container
    wait_for_sql
    run_sql_file "IceCreamFactory_Setup.sql"
    run_sql_file "$1"
    ;;
  down)
    if docker ps -a --format '{{.Names}}' | rg -x "${CONTAINER_NAME}" >/dev/null; then
      docker rm -f "${CONTAINER_NAME}" >/dev/null
      echo "Removed container ${CONTAINER_NAME}."
    else
      echo "Container ${CONTAINER_NAME} not found."
    fi
    ;;
  *)
    echo "Unknown action: ${ACTION}"
    exit 1
    ;;
esac
