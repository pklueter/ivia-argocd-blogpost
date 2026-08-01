#!/usr/bin/env bash
# -------------------------------------------------------
# 02-create-secrets.sh
# Creates all Kubernetes Secrets in the target namespace.
# Requires certificates to exist (run 01-generate-certs.sh first).
#
# Run from the repository root:
#   bash scripts/02-create-secrets.sh
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

NS="${NAMESPACE}"

# -------------------------------------------------------
# Namespace
# -------------------------------------------------------
echo "==> Creating namespace '${NS}' (if not exists)..."
kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# IVIA Admin password (LMI)
# -------------------------------------------------------
echo "==> Creating secret: iviaadmin..."
kubectl create secret generic iviaadmin \
  --from-literal=adminpw="${IVIA_ADMIN_PWD}" \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# IVIA Config Service password
# -------------------------------------------------------
echo "==> Creating secret: configreader..."
kubectl create secret generic configreader \
  --from-literal=cfgsvcpw="${CFGSVC_PWD}" \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# PostgreSQL — password + TLS certificate
# -------------------------------------------------------
echo "==> Creating secret: postgresql-keys..."
kubectl create secret generic postgresql-keys \
  --from-literal=password="${PSQL_PWD}" \
  --from-file=server.crt=./postgresql/keys/server.crt \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# OIDC Provider — keystores
# -------------------------------------------------------
echo "==> Creating secret: op-keystores..."
kubectl create secret generic op-keystores \
  --from-file=jwtsigningkey.pem=./iviaop/secrets/jwtsigningkey.pem \
  --from-file=https.zip=./iviaop/secrets/https.zip \
  --from-file=server.pem=./iviaop/secrets/server.pem \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# OIDC Provider — runtime passwords
# -------------------------------------------------------
echo "==> Creating secret: op..."
kubectl create secret generic op \
  --from-literal=db_password="${OP_DB_PASSWORD}" \
  --from-literal=ldap_password="${OP_LDAP_PASSWORD}" \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# IVD — admin password
# -------------------------------------------------------
echo "==> Creating secret: ivd-passwords..."
kubectl create secret generic ivd-passwords \
  --from-literal=admin="${IVD_ADMIN_PWD}" \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# IVD — server TLS certificate
# -------------------------------------------------------
echo "==> Creating secret: ivd-server-keys..."
kubectl create secret generic ivd-server-keys \
  --from-file=server.pem=./ivd/server.pem \
  -n "${NS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------------
# IVD — license file
# -------------------------------------------------------
if [[ ! -f "${IVD_LICENSE_FILE}" ]]; then
  echo "WARNING: IVD license file not found at '${IVD_LICENSE_FILE}'."
  echo "         Download it from IBM Passport Advantage and set IVD_LICENSE_FILE in .env."
  echo "         Skipping ivd-license-key secret."
else
  echo "==> Creating secret: ivd-license-key..."
  kubectl create secret generic ivd-license-key \
    --from-file=ivd-10.0.0_license_key_limited.txt="${IVD_LICENSE_FILE}" \
    -n "${NS}" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

echo ""
echo "All secrets created in namespace '${NS}'."
echo "Run scripts/03-generate-configmaps.sh next."
