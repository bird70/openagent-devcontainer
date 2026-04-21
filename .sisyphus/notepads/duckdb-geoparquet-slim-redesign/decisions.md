## 2026-04-20T22:56:00Z Task: bootstrap
- Risk posture: accelerated cutover.
- Compatibility approach: partial, preserving URL + style/source contracts.
- Validation policy: mandatory CI smoke/contract/freshness/latency gates.

## 2026-04-20T23:02:15Z Task: freeze-and-codify-preserved-client-contracts
- Chose manifest-driven checks over inline code assertions so contract policy is explicit, reviewable, and easy to extend without changing validator logic.
- Chose portable shell+jq validator as primary executable path to align with existing repo shell tooling and avoid introducing new dependencies.
- Kept checks literal and deterministic (substring/all_substrings) for stable CI behavior and transparent failure messages.

### [2026-04-20] Hybrid Serving Architecture
- **Decision**: Introduce a secondary service (DuckDB-Tile-Server) while keeping t-rex for PostGIS layers.
- **Rationale**: High-churn PostGIS layers can't easily move to GeoParquet yet; splitting paths allows for gradual migration.
- **Mapping**: `/riverlines/*` maps to DuckDB; `/tiles/*` stays with t-rex.

### [2026-04-20] Revised Serving Strategy
- **Decision**: Redirect base/stable vector tiles to PMTiles serving path.
- **Decision**: Use DuckDB exclusively for high-churn, on-demand MVT generation from GeoParquet (e.g., river-flow).
- **Rationale**: Aligns with existing plan to optimize for both high-churn performance (DuckDB) and static scale (PMTiles).
