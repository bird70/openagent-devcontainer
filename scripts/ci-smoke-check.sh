#!/usr/bin/env bash
set -euo pipefail

TILE_URL="${1:-}"
MIN_BYTES="${2:-1}"
REQUEST_TIMEOUT_SECONDS="${REQUEST_TIMEOUT_SECONDS:-15}"

if [[ -z "${TILE_URL}" ]]; then
  printf 'Usage: %s <tile-url> [min-bytes]\n' "$(basename "$0")" >&2
  exit 2
fi

if ! [[ "${MIN_BYTES}" =~ ^[0-9]+$ ]]; then
  printf 'SMOKE CHECK FAILED: min-bytes must be a non-negative integer, got %s\n' "${MIN_BYTES}" >&2
  exit 2
fi

tmp_body="$(mktemp)"
cleanup() {
  rm -f "${tmp_body}"
}
trap cleanup EXIT

http_code="$(curl -sS --max-time "${REQUEST_TIMEOUT_SECONDS}" -o "${tmp_body}" -w '%{http_code}' "${TILE_URL}" || true)"

if [[ -z "${http_code}" || "${http_code}" = "000" ]]; then
  printf 'SMOKE CHECK FAILED: no HTTP response from %s within %ss\n' "${TILE_URL}" "${REQUEST_TIMEOUT_SECONDS}" >&2
  exit 1
fi

if [[ "${http_code}" != "200" ]]; then
  printf 'SMOKE CHECK FAILED: expected HTTP 200 from %s, got %s\n' "${TILE_URL}" "${http_code}" >&2
  exit 1
fi

payload_bytes="$(wc -c < "${tmp_body}" | tr -d '[:space:]')"
if ! [[ "${payload_bytes}" =~ ^[0-9]+$ ]]; then
  printf 'SMOKE CHECK FAILED: unable to determine payload size for %s\n' "${TILE_URL}" >&2
  exit 1
fi

if (( payload_bytes < MIN_BYTES )); then
  printf 'SMOKE CHECK FAILED: expected payload >= %s bytes from %s, got %s bytes\n' "${MIN_BYTES}" "${TILE_URL}" "${payload_bytes}" >&2
  exit 1
fi

printf 'SMOKE CHECK PASSED: %s (http=%s, bytes=%s)\n' "${TILE_URL}" "${http_code}" "${payload_bytes}"
