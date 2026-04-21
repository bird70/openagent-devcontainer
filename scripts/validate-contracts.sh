#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MANIFEST_PATH="${1:-contracts/preserved-client-contracts.json}"
if [[ "${MANIFEST_PATH}" = /* ]]; then
  MANIFEST_FILE="${MANIFEST_PATH}"
else
  MANIFEST_FILE="${REPO_ROOT}/${MANIFEST_PATH}"
fi

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  printf 'ERROR: manifest not found: %s\n' "${MANIFEST_FILE}" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'ERROR: jq is required but not found in PATH\n' >&2
  exit 127
fi

CONTRACT_NAME="$(jq -r '.contract_name // "<unnamed-contract>"' "${MANIFEST_FILE}")"
CHECK_COUNT="$(jq -r '(.checks // []) | length' "${MANIFEST_FILE}")"

declare -a ERRORS=()

while IFS= read -r relpath; do
  [[ -z "${relpath}" ]] && continue
  if [[ ! -f "${REPO_ROOT}/${relpath}" ]]; then
    ERRORS+=("required file missing: ${relpath}")
  fi
done < <(jq -r '.required_files[]? // empty' "${MANIFEST_FILE}")

while IFS= read -r check_b64; do
  [[ -z "${check_b64}" ]] && continue
  check_json="$(printf '%s' "${check_b64}" | base64 --decode)"
  name="$(jq -r '.name // "<unnamed>"' <<<"${check_json}")"
  type="$(jq -r '.type // ""' <<<"${check_json}")"

  mapfile -t files < <(jq -r '.files[]? // empty' <<<"${check_json}")
  if [[ "${#files[@]}" -eq 0 ]]; then
    ERRORS+=("check '${name}' has no files")
    continue
  fi

  for rel in "${files[@]}"; do
    file_path="${REPO_ROOT}/${rel}"
    if [[ ! -f "${file_path}" ]]; then
      ERRORS+=("check '${name}': missing file ${rel}")
      continue
    fi

    content="$(<"${file_path}")"
    case "${type}" in
      substring)
        pattern="$(jq -r '.pattern // ""' <<<"${check_json}")"
        if [[ -z "${pattern}" ]]; then
          ERRORS+=("check '${name}': substring check missing string pattern")
        elif [[ "${content}" != *"${pattern}"* ]]; then
          ERRORS+=("check '${name}' failed in ${rel}: missing substring '${pattern}'")
        fi
        ;;
      all_substrings)
        mapfile -t patterns < <(jq -r '.patterns[]? // empty' <<<"${check_json}")
        if [[ "${#patterns[@]}" -eq 0 ]]; then
          ERRORS+=("check '${name}': all_substrings check missing string list 'patterns'")
        else
          for pattern in "${patterns[@]}"; do
            if [[ "${content}" != *"${pattern}"* ]]; then
              ERRORS+=("check '${name}' failed in ${rel}: missing substring '${pattern}'")
            fi
          done
        fi
        ;;
      regex)
        pattern="$(jq -r '.pattern // ""' <<<"${check_json}")"
        if [[ -z "${pattern}" ]]; then
          ERRORS+=("check '${name}': regex check missing string pattern")
        elif ! [[ "${content}" =~ ${pattern} ]]; then
          ERRORS+=("check '${name}' failed in ${rel}: regex did not match '${pattern}'")
        fi
        ;;
      *)
        ERRORS+=("check '${name}': unsupported type '${type}'")
        ;;
    esac
  done
done < <(jq -r '.checks[]? | @base64' "${MANIFEST_FILE}")

if [[ "${CHECK_COUNT}" -eq 0 ]]; then
  ERRORS+=("manifest must include non-empty 'checks' list")
fi

if [[ "${#ERRORS[@]}" -gt 0 ]]; then
  printf 'CONTRACT VALIDATION FAILED: %s\n' "${CONTRACT_NAME}"
  for err in "${ERRORS[@]}"; do
    printf ' - %s\n' "${err}"
  done
  exit 1
else
  printf 'CONTRACT VALIDATION PASSED: %s\n' "${CONTRACT_NAME}"
  printf 'checks: %s\n' "${CHECK_COUNT}"
fi
