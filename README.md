

# Projet MIAGE-Bank - Session 2026

**Étudiant :** RAJAOBELISON Hanja , ALPTEKIN Eylul
**Formation :** Master MIAGE M2 ITN
**Cours :** Cloud & Kubernetes

## 🎯 Objectif du Projet
Ce dépôt contient l'ensemble des travaux réalisés pour la mise en œuvre de l'infrastructure Cloud de la MIAGE-Bank. L'objectif est de conteneuriser les microservices, d'assurer leur sécurité et de les déployer sur un cluster Kubernetes.

## 📑 Travaux Pratiques

| # | Section | Concepts Clés | Lien |
| :--- | :--- | :--- | :--- |
| **A.1** | **Analyse Comparative** | Architecture Daemonless, Sécurité OCI, Rootless | [README](./Partie%20A/01-image-build/README.md#1-analyse-comparative--docker-vs-buildah) |
| **A.2** | **Build MIAGE-Bank** | Buildah, Containerfile, Layer-by-layer, Maven | [README](./Partie%20A/01-image-build/README.md#2-build-de-miage-bank) |
| **A.3** | **Scan de Sécurité** | Trivy, CVE HIGH/CRITICAL, Plan de remédiation | [README](./Partie%20A/02-security-scan/README.md) |
| **A.4** | **Audit d'image** | Dive, Optimisation de layers, Efficacité CI | [Bientôt dispo] |
| **A.5** | **Pipeline CI** | GitHub Actions, Automatisation, Build Reports | [Bientôt dispo] |
| **B.1** | **Helm & K8s** | Charts, Pods, Services, Deployments | [Bientôt dispo] |

---

## 🛠️ Stack Technique
* **Build tool** : Buildah (Podman-ready)
* **Scanner** : Trivy
* **Audit** : Dive
* **CI** : GitHub Actions

*Projet réalisé dans un environnement WSL (Ubuntu) avec Buildah et Maven.*
