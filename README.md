# IBM Verify Identity Access — ArgoCD Deployment

Beispielrepository zum Blog Post: [IBM Verify Identity Access mit ArgoCD auf Kubernetes deployen](https://blog.klueter.dev/blog/en/ivia-argocd-deployment/)

## Struktur

```
├── scripts/
│   ├── env.example                        # Vorlage für .env (Passwörter, Domains)
│   ├── 01-generate-certs.sh               # TLS-Zertifikate und Schlüssel generieren
│   ├── 02-create-secrets.sh               # Kubernetes Secrets anlegen
│   └── 03-generate-configmaps.sh          # OIDC Provider ConfigMaps generieren
├── kubernetes/
│   ├── apps.yaml                          # Root ArgoCD Application (App-of-Apps)
│   ├── ks/
│   │   └── ingress.yaml                   # ArgoCD Ingress (Traefik)
│   ├── apps/
│   │   ├── verify.yml                     # IBM Verify Identity Access Application
│   │   ├── ldap.yml                       # LDAP Application
│   │   └── database.yml                   # Database Application
│   └── verify-deployment/
│       ├── verify/                        # IVIA Komponenten (Config, WRP, Runtime, DSC, OIDC Provider)
│       │   ├── base/
│       │   └── overlays/dev/
│       ├── ldap/                          # IBM Security Verify Directory
│       │   ├── base/
│       │   └── overlays/dev/
│       └── database/                      # PostgreSQL
│           ├── base/
│           └── overlays/dev/
└── iviaop/
    ├── config/                            # Generische OIDC Provider Konfiguration
    └── stage_config/dev/                  # Umgebungsspezifische Konfiguration
```

## Voraussetzungen

- Kubernetes Cluster (K3s, OpenShift, etc.)
- ArgoCD installiert
- cert-manager für TLS-Zertifikate
- Domain mit konfiguriertem DNS

## Quickstart

```bash
# 1. Domains in den Konfigurationsdateien anpassen (kubernetes/**/*.yaml, apps/*.yml)

# 2. .env anlegen und Werte eintragen
cp scripts/env.example .env

# 3. TLS-Zertifikate und Schlüssel generieren
bash scripts/01-generate-certs.sh

# 4. Kubernetes Secrets anlegen
bash scripts/02-create-secrets.sh

# 5. OIDC Provider ConfigMaps generieren und committen
bash scripts/03-generate-configmaps.sh
git add kubernetes/ && git commit -m "Generate configmaps" && git push

# 6. Repository URL in apps.yaml und apps/*.yml anpassen, dann deployen
kubectl apply -f kubernetes/apps.yaml
```

## ConfigMaps generieren

Die OIDC Provider Konfiguration wird aus den Quelldateien in `iviaop/` als Kubernetes ConfigMaps generiert:

```bash
base_output_dir="kubernetes/verify-deployment/verify/base/config"

kubectl create configmap op-config \
  --from-file=./iviaop/config/*.yml \
  --dry-run=client -o yaml > ${base_output_dir}/op-config.yaml

kubectl create configmap op-mapping-rules \
  --from-file=./iviaop/config/mappingRules \
  --dry-run=client -o yaml > ${base_output_dir}/op-mr.yaml

kubectl create configmap op-access-policies \
  --from-file=./iviaop/config/accessPolicies \
  --dry-run=client -o yaml > ${base_output_dir}/op-ap.yaml

kubectl create configmap op-templates \
  --from-file=./iviaop/config/templates.zip \
  --dry-run=client -o yaml > ${base_output_dir}/op-templates.yaml
```

Umgebungsspezifische ConfigMaps:

```bash
STAGE=dev
stage_output_dir="kubernetes/verify-deployment/verify/overlays/${STAGE}/config"

cp "./iviaop/stage_config/${STAGE}/op.yml" "${stage_output_dir}/op.yaml"
cp "./iviaop/stage_config/${STAGE}/clients.yml" "${stage_output_dir}/clients.yaml"

kubectl create configmap op-clients \
  --from-file="./iviaop/stage_config/${STAGE}/clients" \
  --dry-run=client -o yaml > "${stage_output_dir}/op-clients.yaml"

kubectl create configmap mr-stage-config \
  --from-file="./iviaop/stage_config/${STAGE}/mapping_rules" \
  --dry-run=client -o yaml > "${stage_output_dir}/op-mr-stage-config.yaml"

kubectl create configmap ap-stage-config \
  --from-file="./iviaop/stage_config/${STAGE}/access_policies" \
  --dry-run=client -o yaml > "${stage_output_dir}/op-ap-stage-config.yaml"
```
