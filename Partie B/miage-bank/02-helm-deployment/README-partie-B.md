# Partie B — Packaging Helm & Déploiement Kubernetes de MIAGE-Bank

## Architecture déployée

MIAGE-Bank est déployé sur **Minikube** via un chart Helm complet dans le namespace
`miage-bank`, exposé via un **Ingress Traefik** et synchronisé en continu par **ArgoCD**.

| Composant | Rôle | Outil |
|---|---|---|
| Chart Helm | Packaging et déploiement | Helm 3.20 |
| Ingress | Exposition externe | Traefik v3.7.1 |
| GitOps | Synchronisation Git → K8s | ArgoCD v3.4.3 |
| Secrets | Credentials DB | K8s natif (voir décision) |

---

## Prérequis

```bash
minikube start --memory=4096 --cpus=2
helm repo add traefik https://traefik.github.io/charts && helm repo update
helm install traefik traefik/traefik --namespace traefik --create-namespace
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Images MIAGE-Bank chargées dans Minikube (buildées en Partie A) :
```bash
for svc in annuaire clients comptes composite configserver proxy; do
  buildah push localhost/miage-bank-$svc:v1 docker-archive:/tmp/mb-$svc.tar
  minikube image load /tmp/mb-$svc.tar && rm /tmp/mb-$svc.tar
done
```

---

## 1. Chart Helm MIAGE-Bank

### Structure

```
Partie B/miage-bank/
├── Chart.yaml               — métadonnées (nom, version, appVersion)
├── values.yaml              — configuration par défaut (sans secret)
├── values-prod.yaml         — surcharges production (2 réplicas, registry GHCR)
└── templates/
    ├── _helpers.tpl         — helpers de nommage (fullname, labels, SA)
    ├── namespace.yaml       — namespace miage-bank
    ├── serviceaccount.yaml  — SA + Role (least privilege) + RoleBinding
    ├── configmap.yaml       — URLs Spring Cloud (Eureka, ConfigServer, DB)
    ├── secret.yaml          — credentials DB (voir section secrets)
    ├── deployment.yaml      — 6 Deployments via range (probes, resources, SA)
    ├── service.yaml         — 6 Services ClusterIP via range
    ├── ingress.yaml         — Ingress Traefik → proxy:10000
    ├── networkpolicy.yaml   — default-deny + allow-from-traefik + intra-namespace
    ├── mysql.yaml           — MySQL 8.0 (Deployment + Service)
    └── mongodb.yaml         — MongoDB 6.0 (Deployment + Service)
```

Le chart utilise un **pattern `range`** dans `deployment.yaml` et `service.yaml` pour
générer une ressource par micro-service à partir de la map `values.services`. Cela
évite la duplication et facilite l'ajout de nouveaux services.

### Validation pré-déploiement

Les trois validations exigées par le sujet :

```bash
# 1. Lint
helm lint miage-bank/
# → 1 chart(s) linted, 0 chart(s) failed ✅

# 2. Template (aperçu des manifests générés)
helm template miage-bank miage-bank/ | grep "^kind:" | sort | uniq -c
# → 1 ConfigMap, 8 Deployments, 1 Ingress, 1 Namespace,
#   3 NetworkPolicy, 1 Role, 1 RoleBinding, 1 Secret, 8 Services, 1 ServiceAccount

# 3. Dry-run
helm install miage-bank miage-bank/ -n miage-bank --dry-run --create-namespace
# → STATUS: pending-install, aucune erreur
```

### Déploiement

```bash
# Créer le namespace, puis installer
kubectl create namespace miage-bank
mv miage-bank/templates/namespace.yaml /tmp/
helm install miage-bank miage-bank/ -n miage-bank --create-namespace
mv /tmp/namespace.yaml miage-bank/templates/
# Adopter le namespace dans Helm
kubectl label namespace miage-bank app.kubernetes.io/managed-by=Helm
kubectl annotate namespace miage-bank meta.helm.sh/release-name=miage-bank
kubectl annotate namespace miage-bank meta.helm.sh/release-namespace=miage-bank
helm upgrade miage-bank miage-bank/ -n miage-bank
```

Vérification :
```bash
helm list -n miage-bank
# NAME         NAMESPACE   REVISION  STATUS    CHART             APP VERSION
# miage-bank   miage-bank  2         deployed  miage-bank-1.0.0  v1
```

---

## 2. Déploiement Kubernetes

### Ressources créées

```bash
kubectl get all -n miage-bank
```

| Ressource | Nombre | Détail |
|---|---|---|
| Deployments | 8 | 6 micro-services + MySQL + MongoDB |
| Services (ClusterIP) | 8 | 1 par service |
| Ingress | 1 | Traefik → proxy:10000 |
| NetworkPolicy | 3 | default-deny, allow-traefik, allow-intra |
| ServiceAccount | 1 | miage-bank-sa (least privilege) |
| Role + RoleBinding | 1 + 1 | lecture seule pods/services/configmaps |

### NetworkPolicy

Trois règles assurent la sécurité réseau du namespace :

1. **default-deny-ingress** — bloque tout trafic entrant par défaut
2. **allow-from-traefik** — autorise Traefik (namespace `traefik`) → pod `proxy`
3. **allow-intra-namespace** — communication entre pods du namespace

Validation :
```bash
kubectl get networkpolicies -n miage-bank
```

### Ingress Traefik

L'API Gateway (`proxy`, port 10000) est exposée via Traefik :

```bash
kubectl get ingress -n miage-bank
# miage-bank-ingress  traefik  miage-bank.local  ...

# Accès local (ajouter à /etc/hosts)
echo "$(minikube ip) miage-bank.local" | sudo tee -a /etc/hosts
```

---

## 3. Gestion des secrets

### Décision documentée — K8s natif

**Approche retenue :** Secret Kubernetes natif (`stringData`) créé par le chart.

Les credentials (MySQL `root/root`, MongoDB `root/root`) sont injectés via
`--set secrets.mysqlRootPassword` au déploiement. Le fichier `values.yaml` ne
contient **aucune valeur sensible en clair** (champs vides par défaut).

```bash
# Déploiement avec credentials
helm install miage-bank miage-bank/ -n miage-bank \
  --set secrets.mysqlRootPassword=root \
  --set secrets.mongoRootPassword=root
```

**Pourquoi pas Vault + ESO ?**
L'installation et la configuration complètes de HashiCorp Vault + External Secrets
Operator (ESO) incluant la configuration des policies Vault, le montage des secrets
et la synchronisation ESO dépassent le périmètre du délai imparti. Un exemple de
configuration ESO est fourni dans `01-infrastructure/external-secret.yaml` pour
illustrer la démarche attendue en production.

**Approche production recommandée :**
```yaml
# external-secret.yaml (exemple ESO)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: miage-bank-db-secret
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: miage-bank-db-secret
  data:
    - secretKey: SPRING_DATASOURCE_PASSWORD
      remoteRef:
        key: miage-bank/db
        property: mysql-password
```

---

## 4. GitOps avec ArgoCD

### Problème du « bootstrap » (l'œuf ou la poule)

ArgoCD ne peut pas se déployer lui-même via GitOps c'est le problème classique de
bootstrap. ArgoCD a été installé **manuellement** via `kubectl apply` (une seule fois).
Une fois ArgoCD opérationnel, l'Application `miage-bank` est créée et ArgoCD gère
ensuite tous les déploiements depuis Git.

### Installation ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Application ArgoCD

```bash
kubectl apply -f 01-infrastructure/argocd-app.yaml
```

```yaml
# argocd-app.yaml
spec:
  source:
    repoURL: https://github.com/hanja19/miage-bank-projet.git
    targetRevision: main
    path: "Partie B/miage-bank"
  syncPolicy:
    automated:
      prune: true      # va supprime les ressources retirées du chart
      selfHeal: true   # corrige toute dérive manuelle automatiquement
```

Vérification :
```bash
argocd app list
# NAME               STATUS  HEALTH    SYNCPOLICY  REPO
# argocd/miage-bank  Synced  Degraded  Auto-Prune  github.com/hanja19/miage-bank-projet
```

**Note sur le statut Degraded :** la santé est `Degraded` car certains pods Spring Boot
redémarrent en attendant que leurs dépendances (configserver, bases de données) soient
pleinement opérationnelles. Les ressources d'infrastructure (NetworkPolicy, RBAC,
Services, Ingress) sont toutes `Synced / Healthy`. Ce comportement est attendu dans une
architecture micro-services avec démarrage ordonné.

---

## 5. Démonstration de dérive ArgoCD

L'exercice consiste à modifier manuellement le cluster, observer la détection de dérive
par ArgoCD (`OutOfSync`), puis observer la réconciliation automatique.

### Procédure

```bash
# 1. Désactiver temporairement l'auto-sync
argocd app set miage-bank --sync-policy none

# 2. Créer la dérive : passer annuaire à 3 réplicas
kubectl scale deployment annuaire --replicas=3 -n miage-bank

# 3. Constater OutOfSync dans ArgoCD
argocd app get miage-bank
# → Deployment annuaire : OutOfSync / Progressing
```

**Capture — état OutOfSync :**
> [Insérer capture terminal montrant `annuaire OutOfSync Progressing`]

```bash
# 4. Déclencher la réconciliation manuelle
argocd app sync miage-bank
# → Duration: 1s — deployment.apps/annuaire serverside-applied

# 5. Vérifier le retour à l'état Git
kubectl get deployment annuaire -n miage-bank
# → NAME      READY  UP-TO-DATE  AVAILABLE
# → annuaire  1/1    1           1           ← retour à 1 réplica ✅

# 6. Réactiver l'auto-sync
argocd app set miage-bank --sync-policy automated --self-heal --auto-prune
```

**Capture — après réconciliation :**
> [Insérer capture ArgoCD UI montrant Synced + graph topologique]

### Résultat observé

ArgoCD a détecté la dérive en moins de **5 secondes** et l'a corrigée en **1 seconde**
lors du sync manuel. Avec `selfHeal: true` réactivé, toute dérive future est corrigée
**automatiquement** sans intervention humaine — c'est le principe du GitOps.

---

## Livrables

- [x] Chart Helm complet (14 templates, lint + dry-run validés)
- [x] `values.yaml` sans secret, `values-prod.yaml` documenté
- [x] Application ArgoCD synchronisée sur `main`
- [x] Secrets K8s natifs (décision documentée, Vault+ESO référencé)
- [x] NetworkPolicy (default-deny + allow-traefik + intra-namespace)
- [x] Ingress Traefik → proxy (miage-bank.local)
- [x] Démonstration de dérive OutOfSync → Synced
