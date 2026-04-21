# Preserved Client Contract Validation

This repository freezes client-facing vector tile contracts in a machine-checkable manifest:

- `contracts/preserved-client-contracts.json` (baseline contract)
- `contracts/fixtures/preserved-client-contracts.mismatch.json` (deliberate mismatch fixture)

The contract covers preserved interfaces observed in existing clients and config:

- tile URL templates (`/riverlines/{z}/{x}/{y}.pbf`, `/tiles/{z}/{x}/{y}.pbf`)
- source IDs (`riverlines`, `lines`)
- source-layer IDs (`riverlines`, `lines`)
- required field keys/types by usage (`streamorder`, `relativevalues95thpercentile`, `rchid`, `id`, `class`)
- zoom bounds used by current clients/configs

## Run validation

Baseline (must pass):

```bash
bash scripts/validate-contracts.sh
```

Negative fixture (must fail / non-zero):

```bash
bash scripts/validate-contracts.sh contracts/fixtures/preserved-client-contracts.mismatch.json
```

If either result changes unexpectedly, investigate for contract drift in:

- `app/trex-config.template.toml`
- `app/static/index.html`
- `app/demo-index.html`
- `viewer.html`
- `aws/viewer.html`
- `QUICKSTART.md`
