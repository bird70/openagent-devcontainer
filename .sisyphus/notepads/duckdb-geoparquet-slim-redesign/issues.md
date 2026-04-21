## 2026-04-20T22:56:00Z Task: bootstrap
- No automated app-level tile/ingestion smoke tests currently in CI; must add.
- Compatibility risk concentrated in source/layer/property schema drift.

## 2026-04-20T23:02:15Z Task: freeze-and-codify-preserved-client-contracts
- Initial validator approach using python3 failed because no executable interpreter is available on PATH and venv python symlink targets a host-specific absolute path not present in this container.
- LSP diagnostics could not be fully executed for changed JSON/shell/Python files because configured language servers (biome, bash-language-server, basedpyright) are not installed in the runtime.

### [2026-04-20] Correction Task
- Corrected architectural mismatch where DuckDB was erroneously assigned to stable layers instead of PMTiles.
- Updated spec and notepad to reflect the official layer-to-runtime mapping.

## 2026-04-21T00:42:06Z Task: redesign-ingestion-geoparquet-snapshot-publication
- Initial publish script had a shell quoting bug in printf error paths that caused parse failure; corrected and re-verified.
- LSP diagnostics gate could not run for shell scripts because bash-language-server is not installed in this environment.

## 2026-04-21T00:52:21Z Task: add-ci-verification-baseline-contract-smoke-freshness-latency
- Initial CI fixture endpoint plan using python3 http.server failed because python3 is unavailable in this environment; switched to Perl IO::Socket::INET fixture server for deterministic local and workflow execution.
- LSP diagnostics remain unavailable for changed shell/yaml/json files due to missing bash-language-server, yaml-language-server, and biome binaries.
