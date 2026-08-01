#!/usr/bin/env bash
# -------------------------------------------------------
# 01-generate-certs.sh
# Generates all self-signed TLS certificates and keys
# required before running 02-create-secrets.sh.
#
# Run from the repository root:
#   bash scripts/01-generate-certs.sh
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
# PostgreSQL TLS certificate
# -------------------------------------------------------
echo "==> Generating PostgreSQL TLS certificate..."
mkdir -p ./postgresql/keys
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout ./postgresql/keys/server.key \
  -out ./postgresql/keys/server.crt \
  -days 365 \
  -subj "/CN=db.${NAMESPACE}.svc.cluster.local/O=${NAMESPACE}"

cat ./postgresql/keys/server.key ./postgresql/keys/server.crt > ./postgresql/keys/server.pem
echo "    -> ./postgresql/keys/server.pem (combined key + cert)"

# -------------------------------------------------------
# OIDC Provider (iviaop) — JWT signing key + HTTPS keystore
# -------------------------------------------------------
echo "==> Generating iviaop JWT signing key..."
mkdir -p ./iviaop/secrets/https/personal ./iviaop/secrets/https/signer
openssl genrsa -out ./iviaop/secrets/jwtsigningkey.pem 2048
echo "    -> ./iviaop/secrets/jwtsigningkey.pem"

echo "==> Generating iviaop HTTPS TLS certificate..."
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout ./iviaop/secrets/https/personal/server_key.pem \
  -out ./iviaop/secrets/https/signer/server_cert.pem \
  -days 365 \
  -subj "/CN=iviaop/O=${NAMESPACE}"
echo "    -> ./iviaop/secrets/https/personal/server_key.pem"
echo "    -> ./iviaop/secrets/https/signer/server_cert.pem"

echo "==> Packaging iviaop HTTPS keystore as ZIP..."
(cd ./iviaop/secrets && zip -q https.zip https/personal/server_key.pem https/signer/server_cert.pem)
echo "    -> ./iviaop/secrets/https.zip"

echo "==> Copying PostgreSQL certificate for iviaop DB connection..."
cp ./postgresql/keys/server.crt ./iviaop/secrets/server.pem
echo "    -> ./iviaop/secrets/server.pem"

# -------------------------------------------------------
# IVD (LDAP) TLS certificate
# -------------------------------------------------------
echo "==> Generating IVD LDAPS TLS certificate..."
mkdir -p ./ivd
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout ./ivd/server_key.pem \
  -out ./ivd/server_cert.pem \
  -days 365 \
  -subj "/CN=isvd.${NAMESPACE}.svc.cluster.local/O=${NAMESPACE}"
cat ./ivd/server_key.pem ./ivd/server_cert.pem > ./ivd/server.pem
echo "    -> ./ivd/server.pem"

echo ""
echo "All certificates generated successfully."
echo "Run scripts/02-create-secrets.sh next."
