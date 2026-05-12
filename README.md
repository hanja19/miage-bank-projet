

# Projet MIAGE-Bank - Session 2026

**Étudiantes :** RAJAOBELISON Hanja , ALPTEKIN Eylul
**Formation :** Master MIAGE M2 ITN
**Cours :** Cloud & Kubernetes

## Objectif du Projet
Ce dépôt contient l'ensemble des travaux réalisés pour la mise en œuvre de l'infrastructure Cloud de la MIAGE-Bank. L'objectif est de conteneuriser les microservices, d'assurer leur sécurité et de les déployer sur un cluster Kubernetes.

## Travaux Pratiques

| # | Section | Concepts Clés | Lien Direct |
| :--- | :--- | :--- | :--- |
| **A.1/2** | **Analyse & Build** | Architecture Daemonless, Rootless, Buildah | [Voir l'analyse](./Partie%20A/01-image-build/README.md) |
| **A.3** | **Scan de Sécurité** | Trivy, CVE HIGH/CRITICAL, Remédiation | [Voir le rapport](./Partie%20A/02-security-scan/README.md) |
| **A.4** | **Audit d'image** | Dive, Optimisation de layers, Efficacité | [Voir l'audit](./Partie%20A/03-audit-dive/README.md) |
| **A.5** | **Analyse Statique** | Hadolint, Best Practices Containerfile | [Voir le lint](./Partie%20A/04-static-analysis/README.md) |
| **Bonus** | **Pipeline CI** | GitHub Actions, Automatisation, Check vert | [.github/workflows/ci-pipeline.yml](.github/workflows/ci-pipeline.yml) |
---

## Stack Technique
* **Build tool** : Buildah (Podman-ready)
* **Scanner** : Trivy
* **Audit** : Dive
* **CI** : GitHub Actions

*Projet réalisé dans un environnement WSL (Ubuntu) avec Buildah et Maven.*
EOF
