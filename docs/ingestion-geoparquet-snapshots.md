# GeoParquet Snapshot Publication (Task 3)

This task replaces in-place ingest assumptions with snapshot publication semantics for high-churn `riverlines` GeoParquet artifacts.

## Scripts

- `scripts/publish_geoparquet_snapshot.sh`
  - Publishes a new versioned snapshot directory (`riverlines-<timestamp>`)
  - Writes snapshot metadata (`snapshot.json`)
  - Atomically switches `manifests/latest.json` **after** snapshot publish success
  - Calls retention cleanup at the end
- `scripts/cleanup_geoparquet_snapshots.sh`
  - Removes old versioned snapshots
  - Protects the active target from `manifests/latest.json`
  - Supports configurable `KEEP_COUNT`

Default layout (under `SNAPSHOT_ROOT`, default `data/riverlines-snapshots`):

```text
riverlines-snapshots/
  manifests/latest.json
  riverlines-20260421T010101Z/
    riverlines.parquet
    snapshot.json
  riverlines-20260421T010301Z/
    riverlines.parquet
    snapshot.json
```

## Success simulation (pointer moves)

```bash
mkdir -p data/fixtures
printf 'seed' > data/fixtures/riverlines-v1.parquet
printf 'next' > data/fixtures/riverlines-v2.parquet

SNAPSHOT_ROOT="$(pwd)/data/riverlines-snapshots" KEEP_COUNT=2 SNAPSHOT_TS=20260421T010101Z \
  bash scripts/publish_geoparquet_snapshot.sh data/fixtures/riverlines-v1.parquet

SNAPSHOT_ROOT="$(pwd)/data/riverlines-snapshots" KEEP_COUNT=2 SNAPSHOT_TS=20260421T010301Z \
  bash scripts/publish_geoparquet_snapshot.sh data/fixtures/riverlines-v2.parquet

jq -r '.active_snapshot' data/riverlines-snapshots/manifests/latest.json
# Expected: riverlines-20260421T010301Z
```

## Failure simulation before switch (pointer unchanged)

```bash
SNAPSHOT_ROOT="$(pwd)/data/riverlines-snapshots" KEEP_COUNT=2 SNAPSHOT_TS=20260421T010501Z FAIL_BEFORE_SWITCH=1 \
  bash scripts/publish_geoparquet_snapshot.sh data/fixtures/riverlines-v2.parquet || true

jq -r '.active_snapshot' data/riverlines-snapshots/manifests/latest.json
# Expected unchanged: riverlines-20260421T010301Z
```

Notes:
- Scripts are deterministic when `SNAPSHOT_TS` is provided.
- No active snapshot file is mutated in-place; only pointer file replacement is atomic.
