#!/usr/bin/env bash
# -------------------------------------------------------
# 03-generate-configmaps.sh
# Generates Kubernetes ConfigMap YAML files from the
# iviaop/config and iviaop/stage_config source files.
# Output files are committed to the repository and picked
# up by ArgoCD via Kustomize.
#
# Run from the repository root:
#   bash scripts/03-generate-configmaps.sh
# -------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# Load environment variables
ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: .env file not found. Copy scripts/env.example to .env and fill in your values."
  exit 1
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

# -------------------------------------------------------
# Base ConfigMaps (shared across all environments)
# -------------------------------------------------------
base_output_dir="kubernetes/verify-deployment/verify/base/iviaop/config"
mkdir -p "${base_output_dir}"

echo "==> Generating base ConfigMaps -> ${base_output_dir}/"

echo "    op-config..."
kubectl create configmap op-config \
  --from-file=./iviaop/config/ \
  --dry-run=client -o yaml > "${base_output_dir}/op-config.yaml"

echo "    op-mapping-rules..."
kubectl create configmap op-mapping-rules \
  --from-file=./iviaop/config/mappingRules \
  --dry-run=client -o yaml > "${base_output_dir}/op-mr.yaml"

echo "    op-access-policies..."
kubectl create configmap op-access-policies \
  --from-file=./iviaop/config/accessPolicies \
  --dry-run=client -o yaml > "${base_output_dir}/op-ap.yaml"

echo "    op-templates..."
kubectl create configmap op-templates \
  --from-file=./iviaop/config/templates.zip \
  --dry-run=client -o yaml > "${base_output_dir}/op-templates.yaml"

# -------------------------------------------------------
# Stage-specific ConfigMaps (overlay for ${STAGE})
# -------------------------------------------------------
stage_output_dir="kubernetes/verify-deployment/verify/overlays/${STAGE}/iviaop/config"
stage_src="./iviaop/stage_config/${STAGE}"
mkdir -p "${stage_output_dir}"

echo "==> Generating stage ConfigMaps for '${STAGE}' -> ${stage_output_dir}/"

echo "    op (hostnames/URLs)..."
cp "${stage_src}/op.yml" "${stage_output_dir}/op.yaml"

echo "    clients (list)..."
cp "${stage_src}/clients.yml" "${stage_output_dir}/clients.yaml"

echo "    op-clients..."
kubectl create configmap op-clients \
  --from-file="${stage_src}/clients" \
  --dry-run=client -o yaml > "${stage_output_dir}/op-clients.yaml"

echo "    mr-stage-config..."
kubectl create configmap mr-stage-config \
  --from-file="${stage_src}/mapping_rules" \
  --dry-run=client -o yaml > "${stage_output_dir}/op-mr-stage-config.yaml"

echo "    ap-stage-config..."
kubectl create configmap ap-stage-config \
  --from-file="${stage_src}/access_policies" \
  --dry-run=client -o yaml > "${stage_output_dir}/op-ap-stage-config.yaml"

echo ""
echo "ConfigMaps generated successfully."
echo "Commit the changes and push to trigger ArgoCD sync, or run:"
echo "  kubectl apply -f kubernetes/apps.yaml"
