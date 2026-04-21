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
