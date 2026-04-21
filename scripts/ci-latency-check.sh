#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-}"
THRESHOLD_MS="${2:-500}"
REQUEST_TIMEOUT_SECONDS="${REQUEST_TIMEOUT_SECONDS:-15}"

if [[ -z "${TARGET_URL}" ]]; then
  printf 'Usage: %s <url> [threshold-ms]\n' "$(basename "$0")" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'LATENCY CHECK FAILED: jq is required but not found in PATH\n' >&2
  exit 127
fi

if ! [[ "${THRESHOLD_MS}" =~ ^[0-9]+$ ]]; then
  printf 'LATENCY CHECK FAILED: threshold-ms must be a non-negative integer, got %s\n' "${THRESHOLD_MS}" >&2
  exit 2
fi

timing="$(curl -sS --max-time "${REQUEST_TIMEOUT_SECONDS}" -o /dev/null -w '%{time_total} %{http_code}' "${TARGET_URL}" || true)"
if [[ -z "${timing}" ]]; then
  printf 'LATENCY CHECK FAILED: no timing data returned for %s\n' "${TARGET_URL}" >&2
  exit 1
fi

time_total="${timing%% *}"
http_code="${timing##* }"

if [[ "${http_code}" != "200" ]]; then
  printf 'LATENCY CHECK FAILED: expected HTTP 200 from %s, got %s\n' "${TARGET_URL}" "${http_code}" >&2
  exit 1
fi

if [[ ! "${time_total}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  printf 'LATENCY CHECK FAILED: invalid time_total value from curl: %s\n' "${time_total}" >&2
  exit 1
fi

latency_ms="$(jq -nr --arg t "${time_total}" '($t | tonumber * 1000 | round)')"

if ! [[ "${latency_ms}" =~ ^[0-9]+$ ]]; then
  printf 'LATENCY CHECK FAILED: invalid latency value derived from %s\n' "${time_total}" >&2
  exit 1
fi

if (( latency_ms > THRESHOLD_MS )); then
  printf 'LATENCY CHECK FAILED: latency_ms=%s exceeds threshold_ms=%s for %s\n' "${latency_ms}" "${THRESHOLD_MS}" "${TARGET_URL}" >&2
  exit 1
fi

printf 'LATENCY CHECK PASSED: latency_ms=%s <= threshold_ms=%s for %s\n' "${latency_ms}" "${THRESHOLD_MS}" "${TARGET_URL}"
