# Scripts — Docker + SQL Server (`sqlcmd`)

This folder contains helpers to run **Microsoft SQL Server** in Docker and execute assignment SQL with **`sqlcmd`**.

> **Note:** The main documentation lives in the project root: `../README.md`. This file is a short mirror of the same instructions.

## Quick reference

- **Config:** `.env` in project root with `MSSQL_SA_PASSWORD=...`
- **Setup script (fixed name):** `IceCreamFactory_Setup.sql` in project root  
- **Your trigger / submission SQL:** **any filename you choose** — pass it to `docker_sql.sh`:

```bash
./scripts/docker_sql.sh all <YOUR_TRIGGER_SQL>
./scripts/docker_sql.sh run <YOUR_TRIGGER_SQL>
```

Replace `<YOUR_TRIGGER_SQL>` with your real file name (and path if not in the project root).

- **`run_trigger_submission.sh`:** set `TRIGGER_SQL_FILE` at the top of the script (or run `TRIGGER_SQL_FILE=YourFile.sql ./scripts/run_trigger_submission.sh`); then run `./scripts/run_trigger_submission.sh`.

See **`../README.md`** for prerequisites, troubleshooting, and manual `docker exec` examples using placeholders instead of hardcoded names.
