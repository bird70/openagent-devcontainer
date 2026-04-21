#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT_ROOT="${1:-${SNAPSHOT_ROOT:-${REPO_ROOT}/data/riverlines-snapshots}}"
KEEP_COUNT="${2:-${KEEP_COUNT:-3}}"

MANIFEST_FILE="${SNAPSHOT_ROOT}/manifests/latest.json"

if [[ ! "${KEEP_COUNT}" =~ ^[0-9]+$ ]]; then
  printf 'ERROR: keep-count must be a non-negative integer: %s\n' "${KEEP_COUNT}" >&2
  exit 2
fi

if [[ ! -d "${SNAPSHOT_ROOT}" ]]; then
  printf 'No snapshot root found, nothing to clean: %s\n' "${SNAPSHOT_ROOT}"
  exit 0
fi

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  printf 'No latest manifest found, skipping cleanup protection check: %s\n' "${MANIFEST_FILE}" >&2
  exit 3
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'ERROR: jq is required but not found in PATH\n' >&2
  exit 127
fi

ACTIVE_SNAPSHOT="$(jq -r '.active_snapshot // empty' "${MANIFEST_FILE}")"
if [[ -z "${ACTIVE_SNAPSHOT}" ]]; then
  printf 'ERROR: latest manifest missing active_snapshot: %s\n' "${MANIFEST_FILE}" >&2
  exit 4
fi

mapfile -t SNAPSHOTS < <(ls -1dt "${SNAPSHOT_ROOT}"/riverlines-* 2>/dev/null || true)

if [[ "${#SNAPSHOTS[@]}" -eq 0 ]]; then
  printf 'No versioned snapshots found under: %s\n' "${SNAPSHOT_ROOT}"
  exit 0
fi

declare -A PROTECT=()
PROTECT["${ACTIVE_SNAPSHOT}"]=1

for ((i=0; i<KEEP_COUNT && i<${#SNAPSHOTS[@]}; i++)); do
  snapshot_name="$(basename "${SNAPSHOTS[$i]}")"
  PROTECT["${snapshot_name}"]=1
done

for snapshot_path in "${SNAPSHOTS[@]}"; do
  snapshot_name="$(basename "${snapshot_path}")"
  if [[ -n "${PROTECT[${snapshot_name}]:-}" ]]; then
    continue
  fi
  rm -rf "${snapshot_path}"
  printf 'Removed old snapshot: %s\n' "${snapshot_name}"
done
