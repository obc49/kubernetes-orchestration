# Kubernetes Orchestration — projet fil rouge

Projet pédagogique pour la formation **Kubernetes – Orchestration des conteneurs** (14 heures, deux jours). Le dépôt conserve **six TP apprenants, TP01 à TP06**.

## Parcours des six TP

| TP | Sujet | Résultat attendu |
|---|---|---|
| [TP01](tp/TP01-application-conteneur.md) | Application et conteneur Docker | Application testée localement et image construite |
| [TP02](tp/TP02-ghcr-image-privee.md) | Image privée sur GHCR | Image publiée et tag de formation identifié |
| [TP03](tp/TP03-authentification-ghcr.md) | Authentification au registre | Secret `ghcr-pull` créé dans le bon namespace |
| [TP04](tp/TP04-objets-kubernetes-port-forward.md) | Objets Kubernetes et port-forward | Application déployée, Service testé |
| [TP05](tp/TP05-gateway-api.md) | Gateway API et NGINX Gateway Fabric | Route HTTP acceptée et fonctionnelle |
| [TP06](tp/TP06-loadbalancer-metallb.md) | LoadBalancer local avec MetalLB | Accès externe au laboratoire et vérifications finales |

FluxCD et Vault + External Secrets Operator sont des **bonus hors socle**.

## Prérequis

- Git, Docker Engine (Docker Desktop sous Windows/macOS ou Docker Engine sous Linux), `kubectl`, Kind, Helm 3 et `curl`.
- Bash recommandé. Sous Windows, utiliser Ubuntu/WSL2 avec Docker Desktop ou un moteur Docker fonctionnel.
- Python 3.11+ uniquement pour tester l’application hors conteneur.
- Accès Internet pour récupérer les images et les charts.

Les commandes du dépôt sont des commandes Bash. Les comportements d’accès réseau peuvent différer selon l’OS ; le guide d’installation détaille les points de contrôle.

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

Le workflow [publish-ghcr.yml](.github/workflows/publish-ghcr.yml) publie l’image lors d’un push sur `main`, avec un tag SHA et `latest`. La visibilité privée du package doit être vérifiée dans les paramètres GitHub Packages ; le workflow ne définit pas cette visibilité à lui seul.

Pour le cours, utiliser le tag de formation documenté dans TP02 et ne pas supposer que `latest` est immuable. Créer le Secret `ghcr-pull` dans le namespace `kube-training` avant de déployer le Deployment. Ne jamais versionner de token.

## Déploiement Kubernetes

Créer le cluster avec la configuration du dépôt :

```bash
kind create cluster --config kind/cluster.yaml --wait 120s
kubectl get nodes -o wide
```

Suivre les TP dans l’ordre. TP03 crée le Secret de pull ; TP04 déploie ensuite Namespace, ConfigMap, Deployment et Service. Attendre le rollout avant les tests :

```bash
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get pods,svc,endpoints
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Tester dans un autre terminal : `curl -i http://localhost:8080/health`.

TP05 installe les CRD Gateway API et NGINX Gateway Fabric. TP06 configure MetalLB pour attribuer une adresse LoadBalancer dans le réseau du laboratoire Kind. Les étapes et les versions sont détaillées dans [le guide Gateway API et MetalLB](docs/installation-gateway-metallb.md).

## Structure

```text
app/                         application Flask
tests/                       tests automatisés
kind/cluster.yaml            cluster Kind et port mapping
manifests/                   Namespace, ConfigMap, Deployment, Service,
                             Gateway, HTTPRoute et configuration MetalLB
docs/parcours-pedagogique.md parcours formateur sur 14 h
docs/installation-gateway-metallb.md installation et dépannage réseau
tp/                          six énoncés apprenants
bonus/fluxcd/                 bonus GitOps
bonus/vault-eso/              bonus Vault + External Secrets Operator
.github/workflows/            CI et publication GHCR
```

## Limites et sécurité

- Kind est un environnement de laboratoire, pas un cluster de production.
- Un Secret Kubernetes standard est encodé en base64 ; ce n’est pas automatiquement du chiffrement.
- Le token GHCR ne doit jamais être commité, inclus dans les slides ou montré dans une capture.
- Le secret applicatif de démonstration ne doit contenir aucune donnée réelle.
- L’application affiche seulement si `API_KEY` est configurée, jamais sa valeur.
- MetalLB utilise une plage d’adresses adaptée au réseau Docker/Kind local ; vérifier l’absence de conflit avant le TP06.
- Ne pas utiliser l’ancien contrôleur `ingress-nginx` : le parcours Gateway utilise NGINX Gateway Fabric et l’API Gateway API.

## Nettoyage

```bash
kind delete cluster --name kube-training
```
