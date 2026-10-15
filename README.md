# Kubernetes Orchestration

Projet fil rouge pour la formation **Kubernetes – Orchestration des conteneurs**. Le dépôt conserve exactement **six TP apprenants, TP01 à TP06**.

## Parcours des six TP

| TP | Sujet | Résultat attendu |
|---|---|---|
| [TP01](tp/TP01-application-conteneur.md) | Application et conteneur Docker | Application testée localement et image construite |
| [TP02](tp/TP02-ghcr-image-privee.md) | Image privée GHCR et authentification | Image identifiée et Secret `ghcr-pull` créé dans le bon namespace |
| [TP03](tp/TP03-pod-deployment-service.md) | Pod, Deployment, Service et port-forward | Application déployée et accessible en local |
| [TP04](tp/TP04-configuration-ressources-noeuds.md) | Configuration, ressources, placement et stockage | ConfigMap/Secret compris, requests/limits et placement analysés |
| [TP05](tp/TP05-administration-diagnostic-securite.md) | Administration, diagnostic et sécurité | Incident diagnostiqué avec kubectl et contrôles de sécurité expliqués |
| [TP06](tp/TP06-gateway-api.md) | Gateway API et NGINX Gateway Fabric | Route HTTP fonctionnelle depuis l’hôte |


## Prérequis et outillage

- Git, Docker Engine (Docker Desktop sous Windows/macOS ou Docker Engine sous Linux), `kubectl`, Kind, Helm 3 et `curl`.
- Bash recommandé. Sous Windows, utiliser Ubuntu/WSL2 avec un moteur Docker fonctionnel.
- Python 3.11+ uniquement pour tester l’application hors conteneur.
- Accès Internet pour récupérer les images et les charts.


## Tester l’application et construire l’image

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt pytest
pytest -q

docker build -t kubernetes-orchestration:training .
docker run --rm -d --name kube-training-test -p 5000:5000 \
  -e APP_ENV=formation \
  -e APP_MESSAGE="Bonjour depuis Docker" \
  kubernetes-orchestration:training
curl -i http://localhost:5000/
curl -i http://localhost:5000/health
curl -i http://localhost:5000/ready
docker logs kube-training-test
docker rm -f kube-training-test
```

## Image GHCR privée

Le workflow [publish-ghcr.yml](.github/workflows/publish-ghcr.yml) publie l’image lors d’un push sur `main`, avec un tag SHA et `latest`. La visibilité privée du package doit être vérifiée dans GitHub Packages ; le workflow ne définit pas cette visibilité à lui seul.

Pour le cours, utiliser le tag d’image SHA. Créer le Secret `ghcr-pull` dans le namespace `kube-training` avant de déployer le Deployment. Ne jamais versionner de token.

## Déploiement local

```bash
kind create cluster --config kind/cluster.yaml --wait 120s
kubectl get nodes -o wide
```

Suivre les TP dans l’ordre. Le TP03 déploie Namespace, ConfigMap, Deployment et Service, puis teste le Service avec :

```bash
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get pods,svc,endpoints
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Dans un autre terminal : `curl -i http://localhost:8080/health`.

Le TP06 expose ensuite l’application via Gateway API et NGINX Gateway Fabric. Le guide est dans [docs/installation-gateway.md](docs/installation-gateway.md).

## Structure

```text
app/                         application Flask
tests/                       tests automatisés
kind/cluster.yaml            cluster Kind et port mapping hôte 80 → NodePort 30080
manifests/                   Namespace, ConfigMap, Deployment, Service, Gateway, HTTPRoute
tp/                          six énoncés apprenants
bonus/fluxcd/                 bonus GitOps
bonus/vault-eso/              bonus Vault + External Secrets Operator
.github/workflows/            CI et publication GHCR
```

## Limites et sécurité

- Kind est un lab, pas un cluster de production.
- Un Secret Kubernetes standard est encodé en base64 ; ce n’est pas automatiquement du chiffrement.
- Le token GHCR ne doit jamais être commité, inclus dans les slides ou montré dans une capture.
- Le secret applicatif de démonstration ne doit contenir aucune donnée réelle.
- L’application affiche seulement si `API_KEY` est configurée, jamais sa valeur.
- Les NetworkPolicies dépendent du CNI et ne sont pas appliquées dans ce lab par défaut.
- Le parcours utilise Gateway API et NGINX Gateway Fabric, pas l’ancien contrôleur `ingress-nginx`.

## Nettoyage

```bash
kind delete cluster --name kube-training
```
