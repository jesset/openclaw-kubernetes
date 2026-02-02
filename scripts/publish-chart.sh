#!/usr/bin/env bash
set -euo pipefail

chart_dir="${CHART_DIR:-.}"

if [ -z "${CHART_OCI_REPO:-}" ]; then
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then
    CHART_OCI_REPO="ghcr.io/${GITHUB_REPOSITORY}"
  else
    echo "CHART_OCI_REPO is required when GITHUB_REPOSITORY is not set" >&2
    exit 1
  fi
fi

out_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${out_dir}"
}
trap cleanup EXIT

echo "==> Packaging chart from ${chart_dir}"
pkg_path="$(helm package "${chart_dir}" --destination "${out_dir}" | awk -F': ' 'END{print $2}')"

if [ -z "${pkg_path}" ] || [ ! -f "${pkg_path}" ]; then
  echo "Failed to locate packaged chart" >&2
  exit 1
fi

echo "==> Pushing ${pkg_path} to oci://${CHART_OCI_REPO}"
helm push "${pkg_path}" "oci://${CHART_OCI_REPO}"
