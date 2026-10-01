#!/usr/bin/env bash
set -euo pipefail

RUNNER_HOME="${RUNNER_HOME:-/opt/actions-runner}"
RUNNER_DIST="${RUNNER_DIST:-/opt/actions-runner.dist}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/opt/data/config/github-actions-runner/work}"
RUNNER_NAME="${RUNNER_NAME:-github-actions-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-docker,linux,x64}"
SECRETS_FILE="${GITHUB_RUNNER_SECRETS_FILE:-/run/github-runner-secrets/registration.env}"
DELETE_TOKEN_FILE="${GITHUB_RUNNER_DELETE_TOKEN_FILE_AFTER_CONFIG:-true}"

mkdir -p "$RUNNER_HOME" "$RUNNER_WORKDIR" "$(dirname "$SECRETS_FILE")"

if [[ ! -x "$RUNNER_HOME/config.sh" ]]; then
  echo "Initializing persistent runner directory at $RUNNER_HOME"
  cp -a "$RUNNER_DIST"/. "$RUNNER_HOME"/
fi

cd "$RUNNER_HOME"

read_secret_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
    [[ -z "${key:-}" || "${key:0:1}" == "#" ]] && continue
    value="${value%$'\r'}"
    value="${value%\"}"; value="${value#\"}"
    value="${value%\'}"; value="${value#\'}"
    case "$key" in
      GITHUB_RUNNER_URL) GITHUB_RUNNER_URL="$value" ;;
      GITHUB_RUNNER_TOKEN) GITHUB_RUNNER_TOKEN="$value" ;;
      GITHUB_RUNNER_EPHEMERAL) GITHUB_RUNNER_EPHEMERAL="$value" ;;
      RUNNER_NAME) RUNNER_NAME="$value" ;;
      RUNNER_LABELS) RUNNER_LABELS="$value" ;;
    esac
  done < "$file"
}

configure_runner_if_needed() {
  if [[ -f .runner && -f .credentials ]]; then
    echo "Runner already configured; starting ${RUNNER_NAME}."
    return 0
  fi

  read_secret_file "$SECRETS_FILE"

  local url="${GITHUB_RUNNER_URL:-}"
  local token="${GITHUB_RUNNER_TOKEN:-}"
  if [[ -z "$url" || -z "$token" ]]; then
    return 1
  fi

  echo "Configuring GitHub Actions runner '${RUNNER_NAME}' for ${url} with labels '${RUNNER_LABELS}'."
  args=(
    --unattended
    --url "$url"
    --token "$token"
    --name "$RUNNER_NAME"
    --work "$RUNNER_WORKDIR"
    --labels "$RUNNER_LABELS"
  )

  if [[ "${RUNNER_REPLACE_EXISTING:-true}" == "true" ]]; then
    args+=(--replace)
  fi

  if [[ "${GITHUB_RUNNER_EPHEMERAL:-false}" == "true" ]]; then
    args+=(--ephemeral)
  fi

  ./config.sh "${args[@]}"

  if [[ "$DELETE_TOKEN_FILE" == "true" && -f "$SECRETS_FILE" ]]; then
    rm -f "$SECRETS_FILE" || true
  fi
}

while ! configure_runner_if_needed; do
  echo "GitHub runner is installed but not registered yet. Waiting for $SECRETS_FILE containing GITHUB_RUNNER_URL and GITHUB_RUNNER_TOKEN."
  sleep 60
done

exec ./run.sh
