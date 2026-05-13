#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECTIONS_DIR="${SCRIPT_DIR}/sections"
DEFAULT_SECTIONS="base,python"
REQUESTED_SECTIONS="${PROVISION_SECTIONS:-${DEFAULT_SECTIONS}}"

declare -a sections=()
IFS=',' read -r -a raw_sections <<< "${REQUESTED_SECTIONS}"

for raw_section in "${raw_sections[@]}"; do
  section="${raw_section//[[:space:]]/}"
  section="${section,,}"

  if [ -z "${section}" ]; then
    continue
  fi

  case "${section}" in
    base|python|docker|node|k8s|gh|security|opencode)
      ;;
    *)
      echo "Unknown provision section: ${section}" >&2
      echo "Allowed values: base, python, docker, node, k8s, gh, security, opencode" >&2
      exit 1
      ;;
  esac

  already_added="false"
  for existing in "${sections[@]}"; do
    if [ "${existing}" = "${section}" ]; then
      already_added="true"
      break
    fi
  done

  if [ "${already_added}" = "false" ]; then
    sections+=("${section}")
  fi
done

if [ "${#sections[@]}" -eq 0 ]; then
  sections=(base python)
fi

shopt -s nullglob

for section in "${sections[@]}"; do
  matches=("${SECTIONS_DIR}"/*_"${section}".sh)
  if [ "${#matches[@]}" -eq 0 ]; then
    echo "Provision section script not found for: ${section}" >&2
    exit 1
  fi

  for script in "${matches[@]}"; do
    echo "==> Running provision section: ${section} (${script##*/})"
    bash "${script}"
  done
done

echo "==> Running provision section: cleanup (99_cleanup.sh)"
bash "${SECTIONS_DIR}/99_cleanup.sh"

echo "Provisioning complete."
