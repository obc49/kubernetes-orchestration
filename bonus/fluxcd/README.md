# Bonus — Déployer une application avec Flux

Ce TP est facultatif. Il vous fait découvrir GitOps : vous décrivez l’état souhaité dans Git et Flux applique les changements au cluster.

## Objectif

Installer Flux sur votre cluster Kind, lui faire suivre un dépôt Git et déployer une application depuis ce dépôt.

## Prérequis

- Les TP01 à TP06 sont terminés.
- Le cluster Kind fonctionne.
- Vous avez Git, kubectl et la CLI Flux.
- Vous pouvez créer un dépôt GitHub dédié à ce TP.
- Vous disposez d’un token GitHub avec les droits nécessaires pour créer/configurer le dépôt. Ne mettez jamais ce token dans un fichier Git.

Vérifiez le cluster :

```bash
kubectl get nodes
kubectl get pods -A
```

## 1. Installer la CLI Flux

Suivez la méthode officielle correspondant à votre système : [Installer la CLI Flux](https://fluxcd.io/flux/installation/).

Vérifiez l’installation :

```bash
flux --version
flux check --pre
```

La commande `flux check --pre` vérifie que le cluster répond et que les prérequis sont présents.

## 2. Préparer un dépôt Git dédié

Sur GitHub, créez un dépôt **public** vide nommé `kubernetes-flux-lab`. Le dépôt doit être public pour que la ressource `GitRepository` de ce TP puisse le lire sans `secretRef`. Ne réutilisez pas le dépôt du cours : le TP sera plus simple à nettoyer.

Dans votre terminal, définissez votre identifiant GitHub et le nom du dépôt :

```bash
export GITHUB_USER="votre-identifiant-github"
export GITHUB_REPO="kubernetes-flux-lab"
```

Remplacez `votre-identifiant-github` par votre identifiant réel.

Créez un répertoire de travail et un manifeste de test :

```bash
mkdir -p ~/kubernetes-flux-lab/apps/demo
cd ~/kubernetes-flux-lab
git init
git branch -M main
```

Créez le fichier `apps/demo/deployment.yaml` avec ce contenu :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
```

Créez le fichier `apps/demo/service.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo
  namespace: default
spec:
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 80
```

Créez le fichier `apps/demo/kustomization.yaml` :

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

Ajoutez et validez les fichiers :

```bash
git add .
git commit -m "Add demo application"
git remote add origin "https://github.com/$GITHUB_USER/$GITHUB_REPO.git"
git push -u origin main
```

Si Git demande une authentification, utilisez le mécanisme sécurisé recommandé par GitHub. Ne placez pas de token dans l’URL du dépôt.

## 3. Installer Flux dans le cluster

Créez les variables d’environnement nécessaires. Le token est saisi sans être affiché :

```bash
read -p "Identifiant GitHub : " GITHUB_USER
read -s -p "Token GitHub : " GITHUB_TOKEN
echo
export GITHUB_USER GITHUB_TOKEN
```

Lancez le contrôle :

```bash
flux check --pre
```

Installez Flux et configurez la synchronisation avec le dépôt :

```bash
flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository="$GITHUB_REPO" \
  --branch=main \
  --path=clusters/kube-training \
  --personal
```

Cette commande installe les contrôleurs Flux et ajoute les fichiers de synchronisation dans le dépôt. Suivez les messages jusqu’à la fin.

Supprimez le token de l’environnement une fois l’installation terminée :

```bash
unset GITHUB_TOKEN
```

## 4. Déclarer l’application à Flux

Dans votre répertoire local `~/kubernetes-flux-lab`, créez `clusters/kube-training/demo-source.yaml` :

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: demo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/VOTRE-IDENTIFIANT/kubernetes-flux-lab
  ref:
    branch: main
```

Remplacez `VOTRE-IDENTIFIANT` par votre identifiant GitHub.

Créez `clusters/kube-training/demo-kustomization.yaml` :

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: demo
  namespace: flux-system
spec:
  interval: 1m
  path: ./apps/demo
  prune: true
  sourceRef:
    kind: GitRepository
    name: demo
  targetNamespace: default
```

Ajoutez les fichiers, validez-les et poussez-les :

```bash
git add clusters/kube-training/demo-source.yaml clusters/kube-training/demo-kustomization.yaml
git commit -m "Configure Flux to deploy demo"
git push
```

Si le répertoire local ne contient pas les fichiers créés par `flux bootstrap`, récupérez d’abord le dépôt distant avec `git pull --rebase`.

## 5. Vérifier le déploiement

Flux peut prendre une minute pour détecter le changement :

```bash
flux get sources git -A
flux get kustomizations -A
kubectl get deployment,pods,svc
kubectl rollout status deployment/demo
```

Si une commande échoue, vérifiez l’état détaillé :

```bash
kubectl -n flux-system get gitrepositories,kustomizations
kubectl -n flux-system describe gitrepository demo
kubectl -n flux-system describe kustomization demo
```

Corrigez les erreurs dans Git, puis poussez un nouveau commit. Flux réconciliera l’état du cluster avec celui du dépôt.

## 6. Modifier le nombre de réplicas

Dans `apps/demo/deployment.yaml`, passez `replicas: 1` à `replicas: 2`.

```bash
git add apps/demo/deployment.yaml
git commit -m "Scale demo to two replicas"
git push
```

Attendez la synchronisation et vérifiez :

```bash
flux get kustomizations -A
kubectl get pods -l app=demo
```

Vous devez voir deux Pods gérés par le Deployment.

## 7. Nettoyer

Supprimez d’abord la Kustomization Flux qui gère l’application :

```bash
flux delete kustomization demo -n flux-system
```

Confirmez la suppression des ressources de l’application :

```bash
kubectl get deployment,svc -l app=demo
```

Pour supprimer entièrement Flux, le cluster de laboratoire et le dépôt, suivez les procédures officielles. Ne supprimez pas le cluster si vous souhaitez conserver les TP principaux.

## À retenir

- Git contient l’état souhaité.
- Flux surveille le dépôt et applique les changements au cluster.
- Un changement passe par un commit et un push.
- Flux corrige la dérive en rapprochant l’état réel de l’état déclaré.
- Un token ne doit jamais être commité.
  
## Documentation officielle

- [Flux — Get started](https://fluxcd.io/flux/get-started/)
- [Flux — Installation](https://fluxcd.io/flux/installation/)
- [Kubernetes — Concepts](https://kubernetes.io/docs/concepts/)
