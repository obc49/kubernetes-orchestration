# TP03 — Déployer notre application sur Kubernetes

## Objectif

Déployer l’application Flask du TP01 dans le cluster, comprendre le rôle du Namespace, du Deployment et du Service, puis résoudre un problème de téléchargement d’image depuis GHCR.

## Prérequis

- TP01 terminé : votre image est publiée dans GHCR. Gardez son adresse complète sous la main, par exemple `ghcr.io/mon-compte/kubernetes-orchestration:tp01-1`.
- TP02 terminé : vous savez utiliser `kubectl`, un namespace, un Pod, un Service et `port-forward`.
- Le cluster Kind est démarré.

## 1. Préparer le namespace et la configuration

Depuis la racine du dépôt :

```bash
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/10-configmap.yaml
kubectl get namespaces
kubectl get configmap -n kube-training
```

Un ConfigMap contient ici la configuration non sensible de l’application.

## 2. Configurer l’image que vous avez publiée

Ouvrez `manifests/20-deployment.yaml`. Remplacez la valeur du champ `image:` par l’adresse exacte de l’image publiée au TP01.

Exemple :

```yaml
image: ghcr.io/mon-compte/kubernetes-orchestration:tp01-1
```

Enregistrez le fichier. Ne mettez aucun token dans le manifeste.

## 3. Déployer l’application et observer le problème

Appliquez le Deployment et le Service :

```bash
kubectl apply -f manifests/20-deployment.yaml
kubectl apply -f manifests/30-service.yaml
kubectl -n kube-training get deployment,pods,svc
```

Attendez quelques instants, puis inspectez les Pods :

```bash
kubectl -n kube-training get pods
kubectl -n kube-training describe pod <nom-du-pod>
kubectl -n kube-training get events --sort-by=.lastTimestamp
```

Remplacez `<nom-du-pod>` par le nom réel du Pod. Repérez le message lié au téléchargement de l’image. Si le package GHCR est privé, Kubernetes ne peut pas le télécharger sans identifiants.

## 4. Créer le secret qui autorise le téléchargement

GHCR est un registre d’images. Le Secret Kubernetes va permettre au nœud de télécharger votre image privée.

Saisissez votre identifiant GitHub et un token autorisé à lire le package (`read:packages`). Le token ne doit jamais être enregistré dans Git.

```bash
read -p "Identifiant GitHub : " GHCR_USER
read -s -p "Token GHCR avec read:packages : " GHCR_TOKEN
echo

kubectl -n kube-training create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USER" \
  --docker-password="$GHCR_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

unset GHCR_TOKEN
unset GHCR_USER
```

Vérifiez que le Secret existe :

```bash
kubectl -n kube-training get secret ghcr-pull
```

## 5. Mettre à jour le Deployment

Ouvrez de nouveau `manifests/20-deployment.yaml`. Dans la section `spec.template.spec`, ajoutez ces lignes avant `containers:` :

```yaml
imagePullSecrets:
  - name: ghcr-pull
```

Enregistrez le fichier puis réappliquez-le :

```bash
kubectl apply -f manifests/20-deployment.yaml
kubectl -n kube-training rollout status deployment/flask-app --timeout=180s
kubectl -n kube-training get pods
```

Les Pods doivent maintenant passer à l’état `Running` et être `Ready`.

Si le téléchargement échoue encore, vérifiez le tag de l’image, l’accès au package, le droit `read:packages` et la présence du Secret dans le namespace `kube-training`.

## 6. Vérifier le Deployment et le Service

```bash
kubectl -n kube-training get deployment,replicaset,pods,svc,endpoints
kubectl -n kube-training get pods --show-labels
kubectl -n kube-training describe deployment flask-app
```

Le Deployment demande deux réplicas. Le Service `flask-app` sélectionne les Pods qui portent le label attendu.

## 7. Tester l’application

Dans un terminal :

```bash
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Dans un second terminal :

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/health
curl -i http://localhost:8080/ready
```

Arrêtez le `port-forward` avec `Ctrl+C`.

## 8. Observer la recréation d’un Pod

Affichez les Pods, supprimez l’un d’eux, puis observez le résultat :

```bash
kubectl -n kube-training get pods
kubectl -n kube-training delete pod <nom-du-pod>
kubectl -n kube-training get pods -w
```

Arrêtez le suivi avec `Ctrl+C`. Le Deployment maintient le nombre de réplicas demandé en s’appuyant sur un ReplicaSet.

## À retenir

- Le Deployment décrit l’état souhaité de l’application.
- Le ReplicaSet maintient le nombre de Pods demandé.
- Le Service fournit un point d’accès stable vers les Pods sélectionnés.
- `imagePullSecrets` permet de télécharger une image depuis un registre privé.
- Le Secret doit se trouver dans le même namespace que les Pods qui l’utilisent.

## Questions

1. Pourquoi les Pods ne démarraient-ils pas au début ?
2. À quoi sert `imagePullSecrets` ?
3. Pourquoi le Secret doit-il être dans `kube-training` ?
4. Quelle différence entre Deployment, ReplicaSet et Pod ?
5. Pourquoi le Service continue-t-il à fonctionner après la recréation d’un Pod ?
