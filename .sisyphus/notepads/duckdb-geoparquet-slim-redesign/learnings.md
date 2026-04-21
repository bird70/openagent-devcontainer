## 2026-04-20T22:56:00Z Task: bootstrap
- Preserve external contracts: tile URL schema + style/source identifiers.
- Phase-1 excludes full raster stack redesign.
- Hybrid target: PMTiles for stable layers, DuckDB MVT for high-churn flow layers.

## 2026-04-20T23:02:15Z Task: freeze-and-codify-preserved-client-contracts
- Added machine-checkable contract manifest at contracts/preserved-client-contracts.json covering URL templates, source/source-layer IDs, zoom bounds, and required fields/types across current client surfaces.
- Added deliberate negative fixture at contracts/fixtures/preserved-client-contracts.mismatch.json to prove drift detection.
- Implemented deterministic shell validator (jq + bash) in scripts/validate-contracts.sh to avoid runtime dependency on unavailable global python in this environment.

### [2026-04-20] Hybrid Architecture Patterns
- Using ALB path-based routing is a lightweight way to introduce DuckDB-serving without breaking existing PostGIS-backed contracts.
- Defining "Layer Classes" (Stable vs High-Churn) allows for granular cache policies and infrastructure scaling.

### [2026-04-20] Corrected Architecture Alignment
- Learned that the project plan specifically designates PMTiles for stable base layers and DuckDB for high-churn river-flow data. This differs from initial assumptions about using DuckDB for all GeoParquet-backed static files.
- PMTiles offers better cost efficiency for truly stable base layers that can be served via range requests on S3.

## 2026-04-21T00:42:06Z Task: redesign-ingestion-geoparquet-snapshot-publication
- Added deterministic snapshot publisher script with explicit SNAPSHOT_TS override for reproducible test runs.
- Atomic pointer switch implemented with temp-file + rename for manifests/latest.json, preventing partial pointer state.
- Retention cleanup protects active_snapshot even when keep-count is lower than total available versions.

## 2026-04-21T00:52:21Z Task: add-ci-verification-baseline-contract-smoke-freshness-latency
- Added reusable CI gate scripts: scripts/ci-smoke-check.sh, scripts/ci-freshness-check.sh, and scripts/ci-latency-check.sh with explicit non-zero failure messaging.
- Freshness check is deterministic via NOW_EPOCH_SECONDS override and supports snapshot-style UTC timestamp format (YYYYMMDDTHHMMSSZ) used by manifests/latest.json.
- Added deterministic fixtures under data/fixtures for healthy and stale freshness paths plus a tile payload fixture to validate smoke/latency behavior.
