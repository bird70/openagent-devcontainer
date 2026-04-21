## 2026-04-20T22:56:00Z Task: bootstrap
- Pending implementation across 12 tasks + final verification wave.

## 2026-04-20T23:02:15Z Task: freeze-and-codify-preserved-client-contracts
- Environment hygiene follow-up: install configured LSP servers (biome, bash-language-server, basedpyright) in CI/dev images to enforce the zero-diagnostic gate for contract artifacts and scripts.

### [2026-04-20] Service Coordination
- ALB routing needs to be synchronized with CloudFront cache behavior to ensure correct PBF serving during the hybrid transition.
- Need to verify that DuckDB-Tile-Server can handle the current client's tile URL pattern (/z/x/y.pbf) exactly.

### [2026-04-20] PMTiles-t-rex Parity
- Need to ensure that the PMTiles-based serving for /tiles/* maintains field-level parity with the original t-rex/PostGIS outputs as defined in contracts.
