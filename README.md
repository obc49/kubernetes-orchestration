# Kubernetes Orchestration — projet fil rouge

Projet pédagogique autonome pour la formation **Kubernetes – Orchestration des conteneurs**.

Le projet fait évoluer une petite application Flask à travers les concepts Kubernetes : image de conteneur, Pod, Deployment, Service, configuration, ressources, probes, diagnostic et sécurité.

> FluxCD et Vault + External Secrets Operator sont des **bonus**, hors du socle obligatoire de 14 heures.

## Prérequis

- Git, Docker Engine, `kubectl`, Kind
- Python 3.11+ (facultatif, pour les tests hors conteneur)

Les commandes sont compatibles avec un terminal Linux/WSL Ubuntu.

## Démarrage rapide

### Tester l'application

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt
pip install pytest
pytest -q
python app/app.py
```

Ouvrir `http://localhost:5000`, puis vérifier `/health` et `/ready`.

### Construire et tester l'image

```bash
docker build -t kubernetes-orchestration:training .
docker run --rm -d --name kube-training-test -p 5000:5000 \
  -e APP_ENV=formation \
  -e APP_MESSAGE="Bonjour depuis Docker" \
  kubernetes-orchestration:training
curl -i http://localhost:5000/
curl -i http://localhost:5000/health
curl -i http://localhost:5000/ready
docker rm -f kube-training-test
```

### Créer le cluster Kind

```bash
kind create cluster --name kube-training --config kind/cluster.yaml
kubectl cluster-info
kubectl get nodes -o wide
```

### Déployer l'application

```bash
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/10-configmap.yaml
kubectl apply -f manifests/20-deployment.yaml
kubectl apply -f manifests/30-service.yaml
kubectl -n kube-training get all
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Ouvrir `http://localhost:8080`.

Le Deployment référence un Secret de façon optionnelle pour permettre un premier déploiement sans valeur secrète. Pour le TP consacré aux Secrets, créez une valeur de démonstration localement :

```bash
kubectl -n kube-training create secret generic flask-app-secret \
  --from-literal=API_KEY='demo-not-a-real-secret'
```

Ne stockez jamais une vraie clé dans Git, les slides ou les captures d'écran.

## Structure

```text
.
├── app/                    # application Flask et dépendances
├── tests/                  # tests automatisés
├── kind/                   # configuration du cluster local
├── manifests/              # manifests Kubernetes du socle
├── docs/                   # parcours et notes pédagogiques
├── tp/                     # énoncés apprenants
├── bonus/
│   ├── fluxcd/              # bonus GitOps
│   └── vault-eso/           # bonus Vault → ESO → Secret Kubernetes
├── .github/workflows/       # tests et build de l'image
├── Dockerfile
├── Makefile
└── LICENSE
```

## Parcours pédagogique

| TP | Sujet | Résultat attendu |
|---|---|---|
| TP01 | Application et conteneur | L'application tourne localement |
| TP02 | Pod, Deployment et réconciliation | L'application est répliquée et auto-réconciliée |
| TP03 | Service et réseau | Accès via un point d'accès stable |
| TP04 | ConfigMap, Secret et stockage | Configuration externalisée |
| TP05 | Requests/limits, probes et diagnostic | Les comportements sont observables |
| TP06 | Synthèse et sécurité | Déploiement justifié et vérifié |

Les TPs sont un socle technique de départ, pas une substitution aux supports et corrections formateur.

## Limites du laboratoire

- Kind est un cluster local, pas un cluster de production.
- Un Secret Kubernetes encodé en base64 n'est pas, à lui seul, un chiffrement.
- Les NetworkPolicies ne sont appliquées que si le CNI les prend en charge et est configuré pour cela. Kind par défaut ne garantit pas ce comportement.
- Le Secret de l'application est optionnel au démarrage : l'application ne renvoie jamais sa valeur, seulement un indicateur indiquant si une clé est configurée.
- Pour utiliser l'image locale avec Kind :

```bash
kind load docker-image kubernetes-orchestration:training --name kube-training
```

## Nettoyage

```bash
kind delete cluster --name kube-training
```

Voir [LICENSE](LICENSE).
