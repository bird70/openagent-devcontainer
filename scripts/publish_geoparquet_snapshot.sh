#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
if [[ -f "${REPO_ROOT}/.env" ]]; then
  source "${REPO_ROOT}/.env"
fi

SNAPSHOT_ROOT="${SNAPSHOT_ROOT:-${REPO_ROOT}/data/riverlines-snapshots}"
STAGING_DIR="${SNAPSHOT_ROOT}/.staging"
MANIFEST_DIR="${SNAPSHOT_ROOT}/manifests"
LATEST_POINTER="${MANIFEST_DIR}/latest.json"
KEEP_COUNT="${KEEP_COUNT:-3}"
FAIL_BEFORE_SWITCH="${FAIL_BEFORE_SWITCH:-0}"
SNAPSHOT_TS="${SNAPSHOT_TS:-$(date -u +%Y%m%dT%H%M%SZ)}"
VERSION_PREFIX="${VERSION_PREFIX:-riverlines}"

INPUT_FILE="${1:-}"
if [[ -z "${INPUT_FILE}" ]]; then
  printf 'Usage: %s <path-to-geoparquet>\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ "${INPUT_FILE}" = /* ]]; then
  SOURCE_FILE="${INPUT_FILE}"
else
  SOURCE_FILE="${REPO_ROOT}/${INPUT_FILE}"
fi

if [[ ! -f "${SOURCE_FILE}" ]]; then
  printf 'ERROR: input file not found: %s\n' "${SOURCE_FILE}" >&2
  exit 2
fi

mkdir -p "${STAGING_DIR}" "${MANIFEST_DIR}"

SNAPSHOT_VERSION="${VERSION_PREFIX}-${SNAPSHOT_TS}"
SNAPSHOT_DIR="${SNAPSHOT_ROOT}/${SNAPSHOT_VERSION}"
SNAPSHOT_FILE="${SNAPSHOT_DIR}/riverlines.parquet"
STAGE_DIR="${STAGING_DIR}/${SNAPSHOT_VERSION}"
STAGE_FILE="${STAGE_DIR}/riverlines.parquet"
METADATA_FILE="${SNAPSHOT_DIR}/snapshot.json"

if [[ -e "${SNAPSHOT_DIR}" || -e "${STAGE_DIR}" ]]; then
  printf 'ERROR: snapshot version already exists: %s\n' "${SNAPSHOT_VERSION}" >&2
  exit 3
fi

cleanup_stage() {
  rm -rf "${STAGE_DIR}" "${LATEST_POINTER}.tmp"
}
trap cleanup_stage EXIT

mkdir -p "${STAGE_DIR}"
cp "${SOURCE_FILE}" "${STAGE_FILE}"

FILE_BYTES="$(wc -c < "${STAGE_FILE}" | tr -d '[:space:]')"
SHA256="$(sha256sum "${STAGE_FILE}" | awk '{print $1}')"

mkdir -p "${SNAPSHOT_DIR}"
mv "${STAGE_FILE}" "${SNAPSHOT_FILE}"
rmdir "${STAGE_DIR}"

cat > "${METADATA_FILE}" <<EOF
{
  "snapshot_version": "${SNAPSHOT_VERSION}",
  "snapshot_file": "${SNAPSHOT_VERSION}/riverlines.parquet",
  "published_at_utc": "${SNAPSHOT_TS}",
  "file_bytes": ${FILE_BYTES},
  "sha256": "${SHA256}"
}
EOF

if [[ "${FAIL_BEFORE_SWITCH}" = "1" ]]; then
  printf 'Simulated failure requested before latest pointer switch.\n' >&2
  exit 9
fi

cat > "${LATEST_POINTER}.tmp" <<EOF
{
  "active_snapshot": "${SNAPSHOT_VERSION}",
  "active_snapshot_file": "${SNAPSHOT_VERSION}/riverlines.parquet",
  "updated_at_utc": "${SNAPSHOT_TS}"
}
EOF

mv "${LATEST_POINTER}.tmp" "${LATEST_POINTER}"

"${SCRIPT_DIR}/cleanup_geoparquet_snapshots.sh" "${SNAPSHOT_ROOT}" "${KEEP_COUNT}"

printf 'Published snapshot: %s\n' "${SNAPSHOT_VERSION}"
printf 'Latest pointer: %s\n' "${LATEST_POINTER}"
