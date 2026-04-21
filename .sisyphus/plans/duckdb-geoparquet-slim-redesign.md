# DuckDB + GeoParquet Slim Redesign for trex-tiles

## TL;DR
> **Summary**: Replace the PostGIS-first serving path with a slimmer hybrid: PMTiles for stable/base vector layers and DuckDB-backed on-demand MVT for high-churn river-flow layers, while preserving existing tile URL and style/source contracts.
> **Deliverables**:
> - Hybrid serving architecture and migration implementation plan (app + IaC + ingestion + CI)
> - Contract-preserving cutover with accelerated rollout gates and rollback path
> - Automated CI smoke, contract, freshness, and latency verification before cutover
> **Effort**: Large
> **Parallel**: YES - 3 waves
> **Critical Path**: 1 → 2 → 5 → 7 → 10 → 11

## Context
### Original Request
Redesign this ECS/PostGIS/t-rex codebase and infrastructure for a slimmer DuckDB + GeoParquet approach suitable for dynamic vector tiles, raster layers, basemaps, and frequent/high-volume river-flow updates.

### Interview Summary
- Primary objective: ops simplicity + lower infrastructure footprint.
- Compatibility: partial preservation; preserve critical contracts.
- Critical contracts selected: tile URL schema + current MapLibre/Mapbox style/source contracts.
- Migration posture selected: accelerated cutover.
- Serving model selected: hybrid PMTiles + DuckDB.
- Validation policy selected: add CI smoke checks before cutover.

### Metis Review (gaps addressed)
- Added contract-freeze gates (URL/style/source/layer/property checks).
- Added explicit freshness SLO and rollback trigger tasks.
- Added snapshot-swap publish model for high-frequency updates.
- Added CloudFront cache strategy per layer class (stable vs high-churn).
- Kept full raster re-architecture out of phase-1 scope.

## Work Objectives
### Core Objective
Deliver a decision-complete migration from PostGIS-first tile serving to a slimmer hybrid stack where:
1) Stable vector layers are pre-generated into PMTiles, and
2) River-flow high-churn layers are served via DuckDB + GeoParquet on-demand MVT,
without breaking the preserved client contracts.

### Deliverables
- New serving runtime and routing design (hybrid PMTiles + DuckDB MVT).
- Updated ingestion pipeline to GeoParquet snapshot publication.
- Updated Terraform ECS/CloudFront/IAM configuration for new runtime and data access.
- CI workflows with automated smoke + contract + freshness + latency checks.
- Cutover runbook with rollback gates and evidence capture.

### Definition of Done (verifiable conditions with commands)
- `terraform -chdir=infra/terraform validate` succeeds.
- `docker compose up -d --build` starts serving stack successfully.
- Base-layer tile endpoint returns non-empty tile payloads for fixture z/x/y.
- Flow-layer endpoint serves latest published snapshot within freshness target.
- Contract check script confirms source IDs/layer IDs/tile URL templates unchanged for preserved contracts.
- Cutover canary + rollback scripts execute successfully in staging.

### Must Have
- Preserve tile URL schema and style/source contracts.
- Accelerated but gated cutover (automated gates, deterministic rollback).
- Snapshot-based flow data publishing (no in-place serving-file mutation).
- Agent-executable QA scenarios for each task.
- Dual-endpoint compatibility in phase-1 (`/tiles/*` and `/riverlines/*`) with internal canonical routing and no client-visible redirects.

### Must NOT Have (guardrails, AI slop patterns, scope boundaries)
- No manual-only acceptance criteria.
- No breaking changes to preserved contracts.
- No full raster stack replacement in phase-1.
- No direct production cutover without CI gate pass.
- No in-place mutation of active river-flow serving snapshot.

## Verification Strategy
> ZERO HUMAN INTERVENTION - all verification is agent-executed.
- Test decision: tests-after + CI smoke/integration gates (bash + HTTP checks; optional Playwright for viewer contract probes).
- QA policy: Every task includes happy-path and failure/edge scenarios with evidence.
- Evidence: `.sisyphus/evidence/task-{N}-{slug}.{ext}`

## Execution Strategy
### Parallel Execution Waves
> Target: 5-8 tasks per wave.

Wave 1: contract freeze + architecture foundation + data model + CI baseline
- Tasks: 1, 2, 3, 4

Wave 2: runtime and IaC migration implementation
- Tasks: 5, 6, 7, 8

Wave 3: validation hardening + cutover/rollback execution artifacts
- Tasks: 9, 10, 11, 12

### Dependency Matrix (full, all tasks)
- 1 blocks 5, 9, 10
- 2 blocks 5, 6, 7, 11
- 3 blocks 5, 6
- 4 blocks 9, 10
- 5 blocks 8, 9, 10
- 6 blocks 8, 10
- 7 blocks 10, 11
- 8 blocks 11
- 9 blocks 11
- 10 blocks 11
- 11 blocks 12
- 12 blocks Final Verification Wave

### Agent Dispatch Summary (wave → task count → categories)
- Wave 1 → 4 tasks → deep(1), unspecified-high(2), writing(1)
- Wave 2 → 4 tasks → unspecified-high(3), deep(1)
- Wave 3 → 4 tasks → unspecified-high(3), writing(1)

## TODOs
> Implementation + Test = ONE task. Never separate.

- [x] 1. Freeze and codify preserved client contracts

  **What to do**: Define and codify the contract manifest for preserved interfaces: tile URL schema and style/source-layer expectations. Create machine-checkable contract artifacts (JSON/YAML + validation script) covering URL templates, source IDs, layer IDs, required attribute keys/types, and min/max zoom behavior for preserved layers.
  **Must NOT do**: Do not add new public contract fields or rename existing preserved source/layer identifiers.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: Requires careful contract boundary definition and failure-proof compatibility framing.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - UI redesign is out of scope.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: [5, 9, 10] | Blocked By: []

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `app/trex-config.template.toml` - current URL/path conventions and layer naming assumptions.
  - Pattern: `app/static/index.html` - current MapLibre source/layer contract consumed by client.
  - Pattern: `app/demo-index.html` - production-like viewer contract expectation.
  - Pattern: `viewer.html` and `aws/viewer.html` - additional style/source contract surfaces.
  - Pattern: `QUICKSTART.md` - published endpoint patterns.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Contract manifest file exists and includes URL template, source IDs, layer IDs, property keys/types, zoom bounds.
  - [ ] Contract validation script runs and passes against current baseline artifacts.
  - [ ] Script exits non-zero on a deliberate contract mismatch fixture.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Contract baseline validation passes
    Tool: Bash
    Steps: Run contract validation script against baseline viewer/config artifacts.
    Expected: Exit code 0 and report lists all required contracts as preserved.
    Evidence: .sisyphus/evidence/task-1-contract-freeze.txt

  Scenario: Contract mismatch is detected
    Tool: Bash
    Steps: Run validator against a fixture with one renamed source ID.
    Expected: Exit code non-zero with explicit mismatch message for renamed source ID.
    Evidence: .sisyphus/evidence/task-1-contract-freeze-error.txt
  ```

  **Commit**: YES | Message: `feat(contract): freeze tile and style-source compatibility` | Files: `[contracts/**, scripts/**, docs/**]`

- [x] 2. Define target hybrid architecture and runtime interfaces

  **What to do**: Produce implementation-ready architecture spec for hybrid serving: PMTiles for stable/base vector layers and DuckDB on-demand MVT for high-churn river-flow. Define internal interfaces: request routing rules, data source bindings, cache policy by layer class, runtime env vars, and canonical internal route mapping for external `/tiles/*` + `/riverlines/*` compatibility.
  **Must NOT do**: Do not include full raster pipeline re-architecture in phase-1 scope.

  **Recommended Agent Profile**:
  - Category: `writing` - Reason: Architecture and interface spec authoring task.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/playwright']` - Browser automation not needed for architecture spec.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: [5, 6, 7, 11] | Blocked By: []

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `README.md` - current deployment architecture and data-path options.
  - Pattern: `DEPLOYMENT_OPTIONS.md` - existing environment options to preserve/replace.
  - Pattern: `infra/terraform/ecs.tf` - current runtime/task wiring.
  - External: `https://duckdb.org/docs/current/core_extensions/spatial/functions` - MVT function behavior.
  - External: `https://geoparquet.org` - GeoParquet metadata expectations.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Architecture spec file contains component diagram section, routing matrix, cache policy, failure modes, fallback behavior, and explicit route precedence (`/riverlines/*` before generic `/tiles/*`).
  - [ ] Spec includes explicit mapping from current components to target components.
  - [ ] Scope section explicitly excludes full raster redesign for phase-1.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Architecture spec completeness check
    Tool: Bash
    Steps: Run markdown lint/check script that asserts required section headers exist.
    Expected: Exit code 0 and all required headers found.
    Evidence: .sisyphus/evidence/task-2-architecture-spec.txt

  Scenario: Missing section detection
    Tool: Bash
    Steps: Run completeness check against a fixture missing failure-mode section.
    Expected: Exit code non-zero identifying missing failure-mode section.
    Evidence: .sisyphus/evidence/task-2-architecture-spec-error.txt
  ```

  **Commit**: YES | Message: `docs(architecture): define hybrid pmtiles-duckdb runtime interfaces` | Files: `[docs/**, architecture/**]`

- [x] 3. Redesign ingestion to GeoParquet snapshot publication

  **What to do**: Design and implement ingestion pipeline changes from gpkg/PostGIS load flow to GeoParquet snapshot publish flow for river updates. Include partitioning strategy, snapshot naming/versioning, atomic publish mechanism, retention policy, and metadata manifest consumed by serving runtime.
  **Must NOT do**: Do not mutate active serving snapshot files in place.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: Multi-part pipeline and reliability-critical data publishing design.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - Not UI related.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: [5, 6] | Blocked By: []

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `scripts/gpkg_to_postgis.sh` - current ingest orchestration baseline.
  - Pattern: `load-data.sh` - local ingest + verification baseline.
  - Pattern: `scripts/create_postgis_indexes.sql` - current post-load optimization assumptions to replace.
  - Pattern: `infra/terraform/variables.tf` - current data location/runtime variable pattern.
  - External: `https://duckdb.org/docs/current/data/parquet/overview` - parquet IO patterns.
  - External: `https://duckdb.org/docs/current/core_extensions/spatial/overview` - spatial extension behavior.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Ingestion pipeline produces versioned GeoParquet snapshot artifacts and a latest-pointer manifest.
  - [ ] Atomic swap semantics are implemented (new snapshot published before pointer update).
  - [ ] Retention cleanup keeps configured number of previous snapshots.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Successful snapshot publication
    Tool: Bash
    Steps: Execute ingest pipeline with fixture data; inspect output location for versioned snapshot + manifest pointer.
    Expected: New snapshot exists, manifest points to new snapshot, previous snapshot remains until retention job.
    Evidence: .sisyphus/evidence/task-3-ingest-snapshot.txt

  Scenario: Publish failure does not corrupt active pointer
    Tool: Bash
    Steps: Simulate failure before pointer update stage.
    Expected: Active manifest remains unchanged and serving pointer still references previous valid snapshot.
    Evidence: .sisyphus/evidence/task-3-ingest-snapshot-error.txt
  ```

  **Commit**: YES | Message: `feat(ingest): add geoparquet snapshot publication flow` | Files: `[scripts/**, pipeline/**, docs/**]`

- [x] 4. Add CI verification baseline for contract, smoke, freshness, latency

  **What to do**: Add CI workflow(s) that execute automated checks: tile smoke responses, contract validation, flow-data freshness threshold check, and basic latency gate. Integrate into existing GH Actions with fail-fast behavior before deployment/cutover steps.
  **Must NOT do**: Do not rely on manual viewer checks as release gate.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: CI orchestration across runtime and validation artifacts.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/dev-browser']` - Headed browser flow not required for baseline API-level gates.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: [9, 10] | Blocked By: []

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `.github/workflows/build-and-push.yml` - image pipeline integration point.
  - Pattern: `.github/workflows/terraform.yml` - existing validation pattern.
  - Pattern: `docker-compose.yml` - local stack orchestration for smoke checks.
  - Pattern: `app/trex-config.template.toml` - expected tile path pattern.

  **Acceptance Criteria** (agent-executable only):
  - [ ] CI job runs smoke checks against started stack and fails on non-200/non-empty tile payload.
  - [ ] CI job runs contract validator and fails on mismatch.
  - [ ] CI job reports freshness lag metric and fails if lag threshold exceeded.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: CI gates pass with healthy fixtures
    Tool: Bash
    Steps: Run workflow locally or via act-equivalent with healthy fixture data.
    Expected: All gates pass; artifacts uploaded.
    Evidence: .sisyphus/evidence/task-4-ci-gates.txt

  Scenario: Freshness threshold breach fails CI
    Tool: Bash
    Steps: Run gate with stale manifest timestamp fixture.
    Expected: Workflow fails with explicit freshness breach message.
    Evidence: .sisyphus/evidence/task-4-ci-gates-error.txt
  ```

  **Commit**: YES | Message: `ci(verification): add smoke contract freshness latency gates` | Files: `[.github/workflows/**, scripts/**]`

- [ ] 5. Implement DuckDB MVT service for river-flow dynamic tiles

  **What to do**: Build/replace serving component to generate MVT for high-churn river-flow layers from GeoParquet via DuckDB spatial SQL. Implement request path compatibility, z/x/y tile envelope handling, attribute projection parity, and runtime safeguards (memory cap, spill dir, geometry axis config).
  **Must NOT do**: Do not change preserved public tile URL schema or source/layer identifiers.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: Core runtime implementation with compatibility and performance constraints.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - No UI work in this task.

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: [8, 9, 10] | Blocked By: [1, 2, 3]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `app/trex-config.template.toml` - current SQL semantics by zoom and bbox filter behavior.
  - Pattern: `app/entrypoint.sh` - runtime env injection pattern to preserve/port.
  - Pattern: `app/Dockerfile` - current runtime packaging baseline.
  - External: `https://duckdb.org/docs/current/core_extensions/spatial/functions` - `ST_AsMVT`, `ST_AsMVTGeom`, tile envelope functions.
  - External: `https://duckdb.org/2026/03/09/announcing-duckdb-150.html` - geometry guardrails and settings.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Endpoint returns HTTP 200 + non-empty MVT for known fixture tiles.
  - [ ] Returned layer name/properties for preserved contracts match manifest.
  - [ ] Runtime config includes memory and spill safeguards; service starts with valid settings.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Dynamic flow tile served successfully
    Tool: Bash
    Steps: Request known z/x/y flow tile endpoint against local stack and save response payload.
    Expected: HTTP 200, valid content-type, payload size > 0.
    Evidence: .sisyphus/evidence/task-5-duckdb-mvt.txt

  Scenario: Missing snapshot returns graceful failure
    Tool: Bash
    Steps: Point service to non-existent active snapshot and request tile.
    Expected: Deterministic 5xx/4xx with explicit error body and no process crash.
    Evidence: .sisyphus/evidence/task-5-duckdb-mvt-error.txt
  ```

  **Commit**: YES | Message: `feat(runtime): add duckdb-backed dynamic mvt flow service` | Files: `[app/**, service/**, config/**]`

- [ ] 6. Build PMTiles generation and serving path for stable layers

  **What to do**: Create stable-layer tile build pipeline to PMTiles and integrate serving path (same public contract where preserved). Define generation cadence, artifact publishing location, and serving mount/access strategy.
  **Must NOT do**: Do not route high-churn flow layer through PMTiles-only path.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: Data build + serving integration with contract and caching implications.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/playwright']` - Browser automation not required.

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: [8, 10] | Blocked By: [2, 3]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `README.md` - current stable serving assumptions and deployment context.
  - Pattern: `infra/terraform/variables.tf` - data path/runtime configuration model.
  - External: `https://github.com/geoparquet-io/gpq-tiles` - GeoParquet → PMTiles generation pattern.
  - External: `https://protomaps.com/docs/pmtiles/` - PMTiles serving behavior.

  **Acceptance Criteria** (agent-executable only):
  - [ ] PMTiles artifact generated for stable layer fixtures and published to configured location.
  - [ ] Stable layer endpoint responds with expected content and contract-compatible layer identifiers.
  - [ ] Serving path fallback behavior documented and tested for missing PMTiles artifact.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Stable layer PMTiles serving works
    Tool: Bash
    Steps: Build PMTiles artifact from fixture data; query representative tiles from serving endpoint.
    Expected: HTTP 200 responses and non-empty tile payloads for selected z/x/y.
    Evidence: .sisyphus/evidence/task-6-pmtiles.txt

  Scenario: Missing PMTiles artifact triggers controlled failure
    Tool: Bash
    Steps: Remove/rename PMTiles artifact and request stable tile.
    Expected: Explicit fallback/error behavior per design, non-zero health signal.
    Evidence: .sisyphus/evidence/task-6-pmtiles-error.txt
  ```

  **Commit**: YES | Message: `feat(data): add pmtiles build and stable-layer serving path` | Files: `[pipeline/**, app/**, docs/**]`

- [ ] 7. Update Terraform and runtime deployment for hybrid stack

  **What to do**: Update ECS task definitions, environment variables, IAM permissions, and any data mounts/bindings for hybrid runtime (DuckDB service + PMTiles access). Preserve CloudFront/ALB routing contract and adjust cache behavior where needed by layer class.
  **Must NOT do**: Do not remove rollback capability to legacy path during migration window.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: IaC changes are broad and deployment-critical.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - Infra-only scope.

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: [10, 11] | Blocked By: [2]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `infra/terraform/ecs.tf` - current task/service definition and env vars.
  - Pattern: `infra/terraform/cloudfront.tf` - edge cache and origin behavior.
  - Pattern: `infra/terraform/iam.tf` - runtime data access permissions.
  - Pattern: `infra/terraform/networking.tf` - mount/network dependencies.
  - Pattern: `infra/terraform/variables.tf` - parameter contract.

  **Acceptance Criteria** (agent-executable only):
  - [ ] `terraform validate` passes after IaC updates.
  - [ ] Plan output shows expected resource deltas with no unintended destructive changes.
  - [ ] Runtime has required permissions to read PMTiles/GeoParquet artifacts.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Terraform validation and plan pass
    Tool: Bash
    Steps: Execute terraform fmt -check, init, validate, and plan in infra/terraform.
    Expected: Validate succeeds and plan contains only expected migration changes.
    Evidence: .sisyphus/evidence/task-7-terraform.txt

  Scenario: IAM denial path is surfaced
    Tool: Bash
    Steps: Run service with intentionally reduced data-read policy in a non-prod test and request tiles.
    Expected: Access failure is explicit in logs/metrics and gate fails deterministically.
    Evidence: .sisyphus/evidence/task-7-terraform-error.txt
  ```

  **Commit**: YES | Message: `infra(ecs): wire hybrid duckdb-pmtiles runtime` | Files: `[infra/terraform/**]`

- [ ] 8. Integrate and adapt client/viewer compatibility layer

  **What to do**: Ensure existing viewer/source/layer contracts remain valid under hybrid backend. Apply only minimal compatibility adjustments required to preserve contract behavior across local and aws viewer artifacts.
  **Must NOT do**: Do not introduce UI redesign or new interaction behavior.

  **Recommended Agent Profile**:
  - Category: `unspecified-low` - Reason: Primarily contract adaptation and verification across a few static files.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - Design overhaul out of scope.

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: [11] | Blocked By: [5, 6]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `app/static/index.html` - baseline style/source/layer contract.
  - Pattern: `app/demo-index.html` - production demo source expectations.
  - Pattern: `viewer.html` and `aws/viewer.html` - additional contract surfaces.
  - Pattern: `contracts/**` - contract manifest produced in task 1.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Contract validator passes against all viewer artifacts.
  - [ ] Tile source URL template remains unchanged for preserved contracts.
  - [ ] No additional public source/layer identifiers are required by viewers.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Viewer contract files validate
    Tool: Bash
    Steps: Run contract validator against app/static/index.html, app/demo-index.html, viewer.html, aws/viewer.html.
    Expected: All preserved contract assertions pass.
    Evidence: .sisyphus/evidence/task-8-viewer-contract.txt

  Scenario: Contract drift is caught
    Tool: Bash
    Steps: Validate a fixture with modified tile URL template.
    Expected: Non-zero exit and explicit template mismatch report.
    Evidence: .sisyphus/evidence/task-8-viewer-contract-error.txt
  ```

  **Commit**: YES | Message: `chore(compat): preserve viewer style-source contracts` | Files: `[app/*.html, aws/*.html, viewer.html, contracts/**]`

- [ ] 9. Implement contract and parity regression suite

  **What to do**: Implement automated parity checks comparing legacy vs hybrid outputs for selected golden tiles and metadata contracts. Include schema checks (fields/types), layer identity checks, and deterministic tolerance rules for geometry simplification differences.
  **Must NOT do**: Do not enforce byte-for-byte tile equality where algorithmic simplification differences are expected.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: Regression harness with nuanced geospatial parity assertions.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/dev-browser']` - API/data-level checks are sufficient.

  **Parallelization**: Can Parallel: YES | Wave 3 | Blocks: [11] | Blocked By: [1, 4, 5]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `contracts/**` - preserved contract assertions.
  - Pattern: `app/trex-config.template.toml` - legacy semantics for expected attributes.
  - Pattern: `app/static/index.html` - consumed layer/property expectations.
  - Pattern: `.github/workflows/*` - CI execution integration point.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Golden tile set parity checks execute in CI and produce pass/fail report.
  - [ ] Layer ID and required property key/type checks pass for preserved contracts.
  - [ ] Tolerance policy documented and applied consistently in parity suite (`0` breaking contract diffs; semantic feature-count variance tolerance `<=1%` only where clipping/generalization differences are expected).

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Golden parity suite passes on compliant output
    Tool: Bash
    Steps: Run parity suite against known-good hybrid outputs and golden baseline set.
    Expected: Pass report with zero contract violations.
    Evidence: .sisyphus/evidence/task-9-parity.txt

  Scenario: Property type drift fails parity suite
    Tool: Bash
    Steps: Run suite against fixture where one preserved property type is changed.
    Expected: Non-zero exit with explicit property/type mismatch report.
    Evidence: .sisyphus/evidence/task-9-parity-error.txt
  ```

  **Commit**: YES | Message: `test(parity): add legacy-vs-hybrid contract regression suite` | Files: `[tests/**, contracts/**, scripts/**]`

- [ ] 10. Add operational SLO gates and observability hooks

  **What to do**: Implement measurable SLO gates and telemetry hooks for cutover readiness: p95 latency, error rate, freshness lag, cache behavior. Expose metrics/log probes used by CI/canary checks and rollback automation.
  **Must NOT do**: Do not define gates without machine-verifiable thresholds.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: Cross-cutting operational instrumentation and gate enforcement.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - No design task.

  **Parallelization**: Can Parallel: YES | Wave 3 | Blocks: [11] | Blocked By: [1, 4, 5, 6, 7]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `.github/workflows/terraform.yml` - existing validation pipeline style.
  - Pattern: `.github/workflows/build-and-push.yml` - deployment pipeline context.
  - Pattern: `infra/terraform/cloudfront.tf` - cache behavior integration point.
  - Pattern: `infra/terraform/ecs.tf` - runtime env/health integration points.

  **Acceptance Criteria** (agent-executable only):
  - [ ] SLO thresholds are codified and checked automatically in CI/canary stage using defaults: PMTiles stable `p95<=60ms`, `p99<=120ms`; DuckDB flow `p95<=180ms`, `p99<=350ms`; `5xx<0.3%`; freshness `p95<=10m`, `p99<=20m`, hard fail `>30m`.
  - [ ] Metrics endpoint/log extraction provides latency, error rate, and freshness lag values.
  - [ ] Gate fails automatically when any threshold is exceeded.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: SLO gates pass under nominal load
    Tool: Bash
    Steps: Execute canary load script with nominal fixture traffic and evaluate thresholds.
    Expected: p95 latency, error rate, freshness all within thresholds; gate passes.
    Evidence: .sisyphus/evidence/task-10-slo-gates.txt

  Scenario: Latency breach triggers gate failure
    Tool: Bash
    Steps: Run canary gate against throttled/degraded runtime profile.
    Expected: Gate exits non-zero and reports breached latency threshold.
    Evidence: .sisyphus/evidence/task-10-slo-gates-error.txt
  ```

  **Commit**: YES | Message: `ops(gates): enforce latency error freshness cutover thresholds` | Files: `[scripts/**, ci/**, infra/**, docs/**]`

- [ ] 11. Execute accelerated cutover playbook with rollback automation

  **What to do**: Implement and document accelerated cutover playbook: preflight checks, staged traffic shift, verification checkpoints, automatic rollback triggers, and rollback execution scripts. Include explicit "go/no-go" criteria from contract/parity/SLO gates with default cadence: shadow 24h → 10% for 2h → 50% for 6h → 100%, rollback on any gate breach sustained >10m.
  **Must NOT do**: Do not perform irreversible decommissioning of legacy path in this task.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: High-risk operational choreography and deterministic rollback design.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/playwright']` - Not required for operational playbook.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: [12] | Blocked By: [2, 7, 8, 9, 10]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `infra/terraform/cloudfront.tf` - traffic/cache controls.
  - Pattern: `infra/terraform/ecs.tf` - runtime deployment controls.
  - Pattern: `.github/workflows/deploy-viewer.yml` - deployment orchestration style.
  - Pattern: `.github/workflows/terraform.yml` - gated IaC execution baseline.
  - Pattern: `contracts/**`, `tests/**`, `scripts/**` - gate inputs.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Cutover playbook includes machine-runnable preflight and rollback commands.
  - [ ] Canary stage can be executed and evaluated automatically against gate thresholds.
  - [ ] Rollback script restores legacy route and passes post-rollback smoke checks.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Accelerated cutover canary succeeds
    Tool: Bash
    Steps: Run playbook in staging with canary traffic shift and execute all preflight + gate checks.
    Expected: All checks pass, canary promoted according to playbook criteria.
    Evidence: .sisyphus/evidence/task-11-cutover.txt

  Scenario: Gate failure triggers automated rollback
    Tool: Bash
    Steps: Inject a gate breach during canary and run rollback automation.
    Expected: Rollback completes, legacy endpoint passes smoke checks, incident log artifact produced.
    Evidence: .sisyphus/evidence/task-11-cutover-error.txt
  ```

  **Commit**: YES | Message: `ops(cutover): add accelerated rollout and rollback automation` | Files: `[runbooks/**, scripts/**, infra/**, .github/workflows/**]`

- [ ] 12. Legacy-path deprecation readiness and handoff package

  **What to do**: Produce deprecation readiness package for legacy PostGIS-first path: retained fallback duration, retirement criteria, operational ownership handoff, and final post-cutover checklist. Keep legacy path operational until explicit approval criteria met.
  **Must NOT do**: Do not remove legacy resources before retention criteria and explicit approval.

  **Recommended Agent Profile**:
  - Category: `writing` - Reason: Structured operational handoff and deprecation governance documentation.
  - Skills: `[]` - No special skill required.
  - Omitted: `['/frontend-ui-ux']` - Not UI.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: [] | Blocked By: [11]

  **References** (executor has NO interview context - be exhaustive):
  - Pattern: `aws/README.md` - current operational deployment guidance.
  - Pattern: `SUMMARY.md` - architecture summary baseline.
  - Pattern: `infra/terraform/*` - legacy resource inventory and dependencies.
  - Pattern: `runbooks/**` - cutover/rollback artifacts from task 11.

  **Acceptance Criteria** (agent-executable only):
  - [ ] Deprecation checklist includes explicit retention window and measurable retirement criteria.
  - [ ] Legacy inventory and dependency list is complete and machine-verifiable against infra files.
  - [ ] Handoff package references cutover evidence artifacts and ownership matrix.

  **QA Scenarios** (MANDATORY - task incomplete without these):
  ```
  Scenario: Deprecation readiness package passes completeness checks
    Tool: Bash
    Steps: Run checklist validator over handoff package sections and required references.
    Expected: Exit code 0 with all required sections and references present.
    Evidence: .sisyphus/evidence/task-12-deprecation.txt

  Scenario: Missing retirement criterion fails validation
    Tool: Bash
    Steps: Run validator against fixture lacking retirement criteria.
    Expected: Non-zero exit with missing-criterion message.
    Evidence: .sisyphus/evidence/task-12-deprecation-error.txt
  ```

  **Commit**: YES | Message: `docs(ops): finalize legacy deprecation readiness package` | Files: `[runbooks/**, docs/**]`

## Final Verification Wave (MANDATORY — after ALL implementation tasks)
> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**
> **Never mark F1-F4 as checked before getting user's okay.** Rejection or user feedback -> fix -> re-run -> present again -> wait for okay.
- [ ] F1. Plan Compliance Audit — oracle
- [ ] F2. Code Quality Review — unspecified-high
- [ ] F3. Real Manual QA — unspecified-high (+ playwright if UI)
- [ ] F4. Scope Fidelity Check — deep

## Commit Strategy
- Use atomic commits per task group:
  - `feat(contract): freeze tile/style compatibility checks`
  - `feat(data): add geoparquet snapshot publication pipeline`
  - `feat(runtime): add duckdb mvt service and pmtiles serving`
  - `infra(ecs): update task definitions and permissions for parquet/duckdb`
  - `ci(verification): add smoke contract freshness latency gates`
  - `ops(cutover): add canary rollout and rollback automation`

## Success Criteria
- Preserved contract checks pass with zero diffs for locked URL/style/source items.
- Base vector layer p95 tile latency meets target (documented gate) under canary load.
- River-flow freshness SLO met for staged snapshots.
- Rollback can restore legacy serving path within defined operational window.
- Infrastructure and pipeline complexity reduced versus current PostGIS-first topology.
