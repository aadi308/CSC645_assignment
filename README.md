# Scripts — Docker + SQL Server (`sqlcmd`)

Helper scripts to run **Microsoft SQL Server** in Docker and execute assignment SQL with **`sqlcmd`**.

## Prerequisites

- **Docker Desktop** (or Docker Engine) running
- **Bash** (macOS/Linux or Git Bash on Windows)
- **ripgrep** (`rg`) — used by `docker_sql.sh` to detect the container name. Install with Homebrew: `brew install ripgrep`, or adjust the script to use `grep` instead.

## Configuration

1. In the **project root** (the parent of `scripts/`, i.e. `CSC645_assignment_Aaditya/`), create a `.env` file:

   ```env
   MSSQL_SA_PASSWORD=YourStrongPassword123!
   ```

   Use a password that meets SQL Server’s complexity rules (length, upper/lower, digit, symbol).

2. **Required SQL files** must live in that same project root so they appear under `/workspace/...` inside the container:

   | File | Purpose |
   |------|--------|
   | `IceCreamFactory_Setup.sql` | Creates `FrostyDelightsDB` and seed data (run **before** trigger tests). |
   | Your trigger / submission script | e.g. `FrostyDelights_Trigger_Submission.sql` or `FrostyDelights_Trigger.sql` |

   If this folder only contains `FrostyDelights_Trigger.sql`, copy `IceCreamFactory_Setup.sql` (and any submission file you use) from your main assignment directory into `CSC645_assignment_Aaditya/` **or** change the paths in the commands below.

## Scripts

### `docker_sql.sh`

Runs SQL Server in a container named `frosty-sqlserver`, mounts the project directory at **`/workspace`**, and runs `sqlcmd` against `localhost` as `sa`.

From the project root (`CSC645_assignment_Aaditya/`):

```bash
chmod +x scripts/docker_sql.sh
```

**Commands:**

| Command | What it does |
|--------|----------------|
| `./scripts/docker_sql.sh pull` | Pulls the SQL Server image. |
| `./scripts/docker_sql.sh start` | Starts existing container or creates a new one. |
| `./scripts/docker_sql.sh setup` | Pull + start + wait + run `IceCreamFactory_Setup.sql`. |
| `./scripts/docker_sql.sh run <file.sql>` | Run a SQL file **relative to project root** (DB must already exist). |
| `./scripts/docker_sql.sh all <file.sql>` | Pull + start + `IceCreamFactory_Setup.sql` + run `<file.sql>`. |
| `./scripts/docker_sql.sh down` | Removes the `frosty-sqlserver` container. |

**Examples:**

```bash
# Full flow: setup DB, then run your submission (adjust filename if yours is FrostyDelights_Trigger.sql)
./scripts/docker_sql.sh all FrostyDelights_Trigger_Submission.sql
```

```bash
# Or step by step
./scripts/docker_sql.sh setup
./scripts/docker_sql.sh run FrostyDelights_Trigger.sql
```

Paths are **relative to the project root**, not the `scripts/` folder:

```bash
./scripts/docker_sql.sh run FrostyDelights_Trigger.sql
```

### `run_trigger_submission.sh`

One-liner that calls:

```bash
./scripts/docker_sql.sh all FrostyDelights_Trigger_Submission.sql
```

If your file is named `FrostyDelights_Trigger.sql`, either rename/copy it to match or edit this script to the correct filename.

```bash
chmod +x scripts/run_trigger_submission.sh
./scripts/run_trigger_submission.sh
```

## Troubleshooting

### `Invalid filename` for `/workspace/...sql`

The container mounts the **project root** to `/workspace`. The file must exist **next to** `scripts/`, not only inside `scripts/`. If you use a manually created container **without** that volume mount, either:

- Recreate the container with `-v /path/to/CSC645_assignment_Aaditya:/workspace`, or  
- `docker cp` your `.sql` files into the container and use `-i /tmp/yourfile.sql`.

### `Database 'FrostyDelightsDB' does not exist`

Run **`setup`** or **`all`** so `IceCreamFactory_Setup.sql` runs **before** the trigger script. Do not run only `run` on an empty server.

### Apple Silicon (`arm64`) vs SQL Server image (`amd64`)

Docker may warn that the image platform is `linux/amd64`. That is normal; SQL Server runs via emulation. You can add `--platform linux/amd64` to `docker run` / `docker pull` if you manage the container manually.

### Manual `sqlcmd` (no scripts)

Replace `YOUR_CONTAINER` and the password:

```bash
docker exec -it YOUR_CONTAINER /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'YOUR_PASSWORD' -i /workspace/IceCreamFactory_Setup.sql
docker exec -it YOUR_CONTAINER /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'YOUR_PASSWORD' -i /workspace/FrostyDelights_Trigger.sql
```

## File layout (expected)

```text
CSC645_assignment_Aaditya/
  .env                          # MSSQL_SA_PASSWORD=...
  IceCreamFactory_Setup.sql     # copy from course materials if missing
  FrostyDelights_Trigger.sql    # your trigger + tests (or submission filename)
  scripts/
    README.md                   # this file
    docker_sql.sh
    run_trigger_submission.sh
```
