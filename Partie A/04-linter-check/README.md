# 04 - Analyse statique avec Hadolint (Question 5)

Ce module présente les résultats du "Linting" du fichier `Containerfile`. L'objectif est de vérifier la conformité aux bonnes pratiques de sécurité et d'optimisation des images Docker/OCI.

## 1. Audit du Containerfile
L'analyse a été effectuée via l'outil **Hadolint**. 

**Résultat de l'audit :**
> `SUCCESS : No issues found.`

Le fichier `Containerfile` respecte l'intégralité des règles (absence d'utilisation de l'utilisateur `root`, versions d'images de base précises, nettoyage du cache, etc.).

## 2. Intégration dans la chaîne de build
Cette vérification est la première étape de notre script automatisé `build.sh`. Si Hadolint détecte une erreur de syntaxe ou une mauvaise pratique majeure, le build est interrompu avant même la phase de construction.

---
*Note : Le rapport complet est disponible dans le fichier `build-reports/hadolint-report.txt`.*