#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-240}"
XCODE_SCHEME="${XCODE_SCHEME:-FirebaseAPI-Package}"
XCODE_DESTINATION="${XCODE_DESTINATION:-platform=macOS}"

well_known_adc_path() {
  if [[ -n "${CLOUDSDK_CONFIG:-}" ]]; then
    printf '%s/application_default_credentials.json' "$CLOUDSDK_CONFIG"
    return
  fi

  if [[ -n "${HOME:-}" ]]; then
    printf '%s/.config/gcloud/application_default_credentials.json' "$HOME"
  fi
}

print_live_smoke_diagnostics() {
  printf 'Live Firestore smoke diagnostics:\n'

  local has_project_candidate=0
  if [[ -n "${FIRESTORE_LIVE_PROJECT_ID:-}" ]]; then
    printf '  FIRESTORE_LIVE_PROJECT_ID: set\n'
    has_project_candidate=1
  else
    printf '  FIRESTORE_LIVE_PROJECT_ID: not set\n'
  fi

  for project_var in GOOGLE_CLOUD_PROJECT GCLOUD_PROJECT GCP_PROJECT; do
    if [[ -n "${!project_var:-}" ]]; then
      printf '  %s: set\n' "$project_var"
      has_project_candidate=1
    else
      printf '  %s: not set\n' "$project_var"
    fi
  done

  local has_local_adc=0
  local has_missing_env_adc=0
  if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    if [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
      printf '  GOOGLE_APPLICATION_CREDENTIALS: set and file exists\n'
      has_local_adc=1
    else
      printf '  GOOGLE_APPLICATION_CREDENTIALS: set but file is missing\n'
      has_missing_env_adc=1
    fi
  else
    printf '  GOOGLE_APPLICATION_CREDENTIALS: not set\n'
  fi

  local adc_path
  adc_path="$(well_known_adc_path)"
  if [[ -n "$adc_path" && -f "$adc_path" ]]; then
    printf '  gcloud well-known ADC file: found\n'
    has_local_adc=1
  else
    printf '  gcloud well-known ADC file: not found\n'
  fi

  printf '  metadata server ADC: allowed fallback when running on Google Cloud\n'

  if [[ "$has_missing_env_adc" -eq 1 ]]; then
    printf '  warning: GOOGLE_APPLICATION_CREDENTIALS takes precedence, so the missing file is expected to fail before ADC fallback.\n'
  fi

  if [[ "$has_local_adc" -eq 0 && "$has_project_candidate" -eq 0 && "$has_missing_env_adc" -eq 0 ]]; then
    printf '  warning: no local credential or project candidate was detected; this run relies on Google Cloud metadata server availability.\n'
  fi
}

if [[ "${FIRESTORE_LIVE_SMOKE:-}" != "1" ]]; then
  printf 'Skipping live Firestore smoke: set FIRESTORE_LIVE_SMOKE=1 to run production Firestore RPCs.\n'
  exit 0
fi

print_live_smoke_diagnostics

if [[ "${FIRESTORE_LIVE_DIAGNOSTICS_ONLY:-}" == "1" ]]; then
  printf 'Skipping live Firestore smoke RPCs: FIRESTORE_LIVE_DIAGNOSTICS_ONLY=1.\n'
  exit 0
fi

printf 'Running live Firestore smoke against production Firestore RPCs...\n'
perl -e 'alarm shift; exec @ARGV' "$TEST_TIMEOUT_SECONDS" \
  xcodebuild -quiet -scheme "$XCODE_SCHEME" -destination "$XCODE_DESTINATION" \
  test -only-testing:FirebaseAPITests/FirestoreLiveIntegrationTests

printf 'Live Firestore smoke passed.\n'
