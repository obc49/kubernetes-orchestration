# Kubernetes — Orchestration des conteneurs

Ce dépôt contient l’application fil rouge, les manifestes et les six TP de la formation. Suivez les TP dans l’ordre : chaque TP réutilise ce qui a été vu précédemment.

## Parcours

| TP | Sujet | À la fin du TP |
|---|---|---|
| [TP01](tp/TP01-application-conteneur.md) | Application, Docker et GHCR | Vous avez construit et publié l’image de l’application. |
| [TP02](tp/TP02-ghcr-image-privee.md) | Premiers pas dans Kubernetes | Vous savez créer un Pod, un namespace et un Service, puis tester avec `port-forward`. |
| [TP03](tp/TP03-pod-deployment-service.md) | Déployer l’application | Vous avez déployé l’application et corrigé le problème d’accès à une image privée. |
| [TP04](tp/TP04-configuration-ressources-noeuds.md) | Configuration, ressources et stockage | Vous avez modifié un ConfigMap, observé requests/limits et monté un volume `emptyDir`. |
| [TP05](tp/TP05-administration-diagnostic-securite.md) | Diagnostic et sécurité | Vous avez diagnostiqué un Service sans endpoints et vérifié des droits RBAC. |
| [TP06](tp/TP06-gateway-api.md) | Gateway API | Vous avez exposé l’application en HTTP depuis votre poste. |

## Prérequis

L’environnement recommandé pour la formation est **Ubuntu sous WSL2 avec Docker Desktop et l’intégration WSL activée**.

Installez et vérifiez les outils suivants avant de commencer :

- Git
- Docker
- kubectl
- Kind
- Helm 3 (utilisé au TP06)
- curl
- Python 3.11 ou plus récent (TP01)

Vérifiez que les commandes suivantes fonctionnent :

```bash
git --version
docker version
kubectl version --client
kind version
helm version
curl --version
python3 --version
```

Docker doit pouvoir démarrer des conteneurs. Si `docker version` affiche une erreur de connexion au daemon, corrigez Docker avant de commencer.

## Démarrer le cluster

Le TP02 vous guide dans la création du cluster. Depuis la racine du dépôt, la commande est :

```bash
kind create cluster --config kind/cluster.yaml --wait 120s
kubectl get nodes -o wide
```

Les trois nœuds doivent être `Ready`.

## Organisation du dépôt

```text
app/                         application Flask
tests/                       tests de l’application
kind/cluster.yaml            configuration du cluster Kind
manifests/                   manifestes utilisés pendant les TP
tp/                          énoncés des six TP
docs/installation-gateway.md guide d’installation pour le TP06
.github/workflows/            tests et publication de l’image GHCR
bonus/                        exercices complémentaires
```

## Sécurité

- Ne mettez jamais de token GitHub ou de secret réel dans un fichier du dépôt.
- Au TP01, utilisez un token GHCR autorisé à publier une image.
- Au TP03, utilisez un token autorisé à lire le package privé (`read:packages`).
- Un Secret Kubernetes standard n’est pas automatiquement chiffré.
- Kind est un environnement de laboratoire, pas un cluster de production.

## Nettoyer le cluster

À la fin de la formation, supprimez le cluster si vous n’en avez plus besoin :

```bash
kind delete cluster --name kube-training
```
