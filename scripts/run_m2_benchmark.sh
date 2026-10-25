#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULT_FILE="${ROOT_DIR}/results/m2_benchmark_results.csv"

if ! command -v adb >/dev/null 2>&1; then
  echo "error: adb is required but was not found in PATH" >&2
  exit 1
fi

mapfile -t DEVICES < <(adb devices | awk 'NR > 1 && $2 == "device" {print $1}')
if [[ "${#DEVICES[@]}" -eq 0 ]]; then
  echo "error: no connected Android device is ready (adb devices)" >&2
  exit 1
fi
if [[ "${#DEVICES[@]}" -gt 1 ]]; then
  echo "error: more than one Android device is connected; select one with ANDROID_SERIAL" >&2
  exit 1
fi

export ANDROID_SERIAL="${ANDROID_SERIAL:-${DEVICES[0]}}"
PACKAGE_NAME="com.example.auraf_benchmark_harness"
cd "${ROOT_DIR}/benchmark_harness"
flutter pub get

LOG_OUTPUT="$(mktemp)"
flutter test integration_test/m2_benchmark_test.dart 2>&1 | tee "${LOG_OUTPUT}"

cd "${ROOT_DIR}"
mkdir -p "$(dirname "${RESULT_FILE}")"

# 1. Primary: Extract tagged CSV directly from test stdout (reliable across all Android OEMs)
if grep -q "AURAF_CSV_START" "${LOG_OUTPUT}"; then
  sed -n '/AURAF_CSV_START/,/AURAF_CSV_END/{ /AURAF_CSV_START/d; /AURAF_CSV_END/d; p; }' "${LOG_OUTPUT}" > "${RESULT_FILE}"
# 2. Secondary fallback: Pull from device storage
elif adb pull /sdcard/Download/m2_benchmark_results.csv "${RESULT_FILE}" >/dev/null 2>&1; then
  :
# 3. Tertiary fallback: run-as app data
elif adb exec-out run-as "${PACKAGE_NAME}" cat "app_flutter/m2_benchmark_results.csv" > "${RESULT_FILE}" 2>/dev/null; then
  :
else
  echo "error: could not retrieve benchmark CSV from device or test stream" >&2
  rm -f "${LOG_OUTPUT}"
  exit 1
fi
rm -f "${LOG_OUTPUT}"
if [[ ! -f "${RESULT_FILE}" ]]; then
  echo "error: benchmark did not create ${RESULT_FILE}" >&2
  exit 1
fi

EXPECTED_HEADER='run_id,timestamp,device_model,network_condition,context_budget,placement,ttft_ms,total_latency_ms,tokens_per_sec,energy_mah,peak_memory_mb,temp_celsius,cost_usd,quality_score,constraint_violated'
actual_header="$(head -n 1 "${RESULT_FILE}")"
if [[ "${actual_header}" != "${EXPECTED_HEADER}" ]]; then
  echo "error: CSV header does not match the shared data contract" >&2
  exit 1
fi

row_count="$(tail -n +2 "${RESULT_FILE}" | sed '/^[[:space:]]*$/d' | wc -l)"
if [[ "${row_count}" -ne 24 ]]; then
  echo "error: expected 24 benchmark rows, found ${row_count}" >&2
  exit 1
fi

echo "M2 benchmark complete: ${RESULT_FILE} (24 records)"
