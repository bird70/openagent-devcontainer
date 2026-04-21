#!/usr/bin/env bash
set -euo pipefail

MANIFEST_FILE="${1:-}"
MAX_LAG_SECONDS="${2:-1800}"
TIMESTAMP_FIELD="${TIMESTAMP_FIELD:-updated_at_utc}"
NOW_EPOCH_SECONDS="${NOW_EPOCH_SECONDS:-}"

if [[ -z "${MANIFEST_FILE}" ]]; then
  printf 'Usage: %s <manifest-json-path> [max-lag-seconds]\n' "$(basename "$0")" >&2
  exit 2
fi

if ! [[ "${MAX_LAG_SECONDS}" =~ ^[0-9]+$ ]]; then
  printf 'FRESHNESS CHECK FAILED: max-lag-seconds must be a non-negative integer, got %s\n' "${MAX_LAG_SECONDS}" >&2
  exit 2
fi

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  printf 'FRESHNESS CHECK FAILED: manifest file not found: %s\n' "${MANIFEST_FILE}" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'FRESHNESS CHECK FAILED: jq is required but not found in PATH\n' >&2
  exit 127
fi

timestamp_value="$(jq -r --arg field "${TIMESTAMP_FIELD}" '.[$field] // empty' "${MANIFEST_FILE}")"
if [[ -z "${timestamp_value}" ]]; then
  printf "FRESHNESS CHECK FAILED: manifest field '%s' missing or empty in %s\n" "${TIMESTAMP_FIELD}" "${MANIFEST_FILE}" >&2
  exit 1
fi

if [[ "${timestamp_value}" =~ ^([0-9]{8})T([0-9]{6})Z$ ]]; then
  ts_date="${BASH_REMATCH[1]}"
  ts_time="${BASH_REMATCH[2]}"
  normalized_timestamp="${ts_date:0:4}-${ts_date:4:2}-${ts_date:6:2} ${ts_time:0:2}:${ts_time:2:2}:${ts_time:4:2} UTC"
elif [[ "${timestamp_value}" =~ [Tt] ]]; then
  normalized_timestamp="${timestamp_value}"
else
  printf "FRESHNESS CHECK FAILED: unsupported timestamp format in '%s': %s\n" "${TIMESTAMP_FIELD}" "${timestamp_value}" >&2
  exit 1
fi

snapshot_epoch="$(date -u -d "${normalized_timestamp}" +%s 2>/dev/null || true)"
if [[ -z "${snapshot_epoch}" ]] || ! [[ "${snapshot_epoch}" =~ ^[0-9]+$ ]]; then
  printf "FRESHNESS CHECK FAILED: could not parse timestamp in '%s': %s\n" "${TIMESTAMP_FIELD}" "${timestamp_value}" >&2
  exit 1
fi

if [[ -n "${NOW_EPOCH_SECONDS}" ]]; then
  if ! [[ "${NOW_EPOCH_SECONDS}" =~ ^[0-9]+$ ]]; then
    printf 'FRESHNESS CHECK FAILED: NOW_EPOCH_SECONDS must be a non-negative integer, got %s\n' "${NOW_EPOCH_SECONDS}" >&2
    exit 2
  fi
  now_epoch="${NOW_EPOCH_SECONDS}"
else
  now_epoch="$(date -u +%s)"
fi

lag_seconds="$((now_epoch - snapshot_epoch))"
if (( lag_seconds < 0 )); then
  lag_seconds=0
fi

if (( lag_seconds > MAX_LAG_SECONDS )); then
  printf "FRESHNESS CHECK FAILED: lag_seconds=%s exceeds max_lag_seconds=%s (field=%s, timestamp=%s)\n" \
    "${lag_seconds}" "${MAX_LAG_SECONDS}" "${TIMESTAMP_FIELD}" "${timestamp_value}" >&2
  exit 1
fi

printf "FRESHNESS CHECK PASSED: lag_seconds=%s <= max_lag_seconds=%s (field=%s, timestamp=%s)\n" \
  "${lag_seconds}" "${MAX_LAG_SECONDS}" "${TIMESTAMP_FIELD}" "${timestamp_value}"
