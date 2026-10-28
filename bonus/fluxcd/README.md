# Bonus — Déployer notre application avec Flux

Ce TP est facultatif. Il vous fait découvrir GitOps : vous décrivez l’état souhaité dans Git, et Flux applique les changements au cluster. Personne ne lance plus `kubectl apply`.

C’est la même application que depuis le TP01, la même image publiée dans votre registre. Seule la façon de la déployer change.

## Objectif

Installer Flux sur votre cluster Kind, lui faire suivre un dépôt Git, et y déployer l’application du cours. Puis modifier le nombre de répliques **par un commit**, et le constater sur le cluster.

## Prérequis

- Les TP01 à TP06 sont terminés.
- Le cluster Kind fonctionne, et le namespace `kube-training` contient le Secret `ghcr-pull` créé au TP03.
- Vous avez Git, `kubectl` et la CLI Flux.
- Un token GitHub autorisé à créer un dépôt sur votre compte. Ne le placez jamais dans un fichier.
- L’adresse de votre image, publiée au TP01, par exemple `ghcr.io/VOTRE-IDENTIFIANT/kubernetes-orchestration:tp01-1`.

Vérifiez le cluster et le Secret dont l’application aura besoin :

```bash
kubectl get nodes
kubectl -n kube-training get secret ghcr-pull
```

## 1. Installer la CLI Flux

Suivez la méthode officielle correspondant à votre système : [Installer la CLI Flux](https://fluxcd.io/flux/installation/).

```bash
flux --version
flux check --pre
```

`flux check --pre` vérifie que le cluster répond et que les prérequis sont réunis.

## 2. Installer Flux et créer le dépôt

Flux crée lui-même le dépôt, en privé, et y dépose sa propre configuration. Vous n’avez rien à préparer sur GitHub.

Saisissez vos identifiants. Le token n’est pas affiché :

```bash
read -p "Identifiant GitHub : " GITHUB_USER
read -s -p "Token GitHub : " GITHUB_TOKEN
echo
export GITHUB_USER GITHUB_TOKEN
```

```bash
flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository=kubernetes-flux-lab \
  --branch=main \
  --path=clusters/kube-training \
  --personal
```

La commande installe les contrôleurs Flux, crée le dépôt `kubernetes-flux-lab` s’il n’existe pas, et y écrit le répertoire `clusters/kube-training/flux-system`. Suivez les messages jusqu’à la fin.

Vérifiez ce que Flux surveille déjà :

```bash
flux get sources git -A
flux get kustomizations -A
```

Une source nommée `flux-system` apparaît : c’est le dépôt que Flux vient de créer. Nous la réutiliserons telle quelle, sans en déclarer une seconde.

## 3. Récupérer le dépôt en local

Le dépôt créé par le bootstrap est **privé** : Git va donc demander une authentification. À l’invite, saisissez votre identifiant GitHub, puis **votre token en guise de mot de passe** — c’est celui que vous venez d’utiliser. Si vous avez déjà configuré un gestionnaire d’identifiants Git ou la commande `gh auth login`, rien ne vous sera demandé.

La première ligne redonne votre identifiant, perdu si vous avez changé de
terminal pendant le `bootstrap`.

```bash
read -p "Identifiant GitHub : " GITHUB_USER
git clone "https://github.com/$GITHUB_USER/kubernetes-flux-lab.git" ~/kubernetes-flux-lab
cd ~/kubernetes-flux-lab
ls clusters/kube-training
```

Vous devez voir le répertoire `flux-system`. Ne le modifiez pas : il appartient à Flux.

Le token n’a plus à rester dans votre environnement :

```bash
unset GITHUB_TOKEN
```

Les `git push` des étapes suivantes redemanderont cette authentification, sauf si un gestionnaire d’identifiants la mémorise.

## 4. Décrire l’application dans le dépôt

Créez le répertoire :

```bash
mkdir -p apps/flask
```

Créez `apps/flask/deployment.yaml`. **Remplacez l’image par la vôtre**, celle publiée au TP01 :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-gitops
  namespace: kube-training
  labels:
    app.kubernetes.io/name: flask-gitops
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: flask-gitops
  template:
    metadata:
      labels:
        app.kubernetes.io/name: flask-gitops
    spec:
      imagePullSecrets:
        - name: ghcr-pull
      containers:
        - name: flask-app
          image: ghcr.io/VOTRE-IDENTIFIANT/kubernetes-orchestration:tp01-1
          ports:
            - name: http
              containerPort: 5000
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            periodSeconds: 5
```

Créez `apps/flask/service.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-gitops
  namespace: kube-training
  labels:
    app.kubernetes.io/name: flask-gitops
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: flask-gitops
  ports:
    - name: http
      port: 80
      targetPort: http
```

Créez `apps/flask/kustomization.yaml` :

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

Ce Deployment porte un autre nom et d’autres labels que celui du TP03 : les deux cohabitent sans se gêner dans le même namespace.

## 5. Demander à Flux de déployer ce répertoire

Créez `clusters/kube-training/flask.yaml` :

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flask
  namespace: flux-system
spec:
  interval: 1m
  path: ./apps/flask
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

Trois champs méritent un arrêt. `path` désigne le répertoire à appliquer. `sourceRef` réutilise la source créée par le bootstrap, ce qui évite d’en déclarer une seconde et permet au dépôt de rester privé. `prune: true` autorise Flux à supprimer du cluster ce que vous retirez de Git — c’est ce qui rend le dépôt réellement maître de l’état.

Poussez le tout :

```bash
git add apps/flask clusters/kube-training/flask.yaml
git commit -m "Déployer l'application du cours avec Flux"
git push
```

## 6. Vérifier le déploiement

Flux relit le dépôt toutes les minutes. Pour ne pas attendre :

```bash
flux reconcile kustomization flux-system --with-source
```

Puis observez :

```bash
flux get kustomizations -A
kubectl -n kube-training get deployment,pods,svc -l app.kubernetes.io/name=flask-gitops
kubectl -n kube-training rollout status deployment/flask-gitops
```

Testez l’application déployée par Git :

```bash
kubectl -n kube-training port-forward svc/flask-gitops 8081:80
```

Dans un second terminal :

```bash
curl -i http://localhost:8081/health
```

Arrêtez le `port-forward` avec `Ctrl+C`.

Si quelque chose coince, la méthode du TP05 s’applique, avec les ressources de Flux :

```bash
kubectl -n flux-system get kustomizations
kubectl -n flux-system describe kustomization flask
kubectl -n kube-training describe pod -l app.kubernetes.io/name=flask-gitops
```

Une erreur fréquente est une image incorrecte ou inaccessible : le Pod reste alors en `ImagePullBackOff`, exactement comme au TP03. Corrigez le fichier **dans Git**, poussez, et Flux réconciliera.

## 7. Changer l’état par un commit

Dans `apps/flask/deployment.yaml`, passez `replicas: 1` à `replicas: 2`.

```bash
git add apps/flask/deployment.yaml
git commit -m "Passer à deux répliques"
git push
flux reconcile kustomization flux-system --with-source
kubectl -n kube-training get pods -l app.kubernetes.io/name=flask-gitops
```

Deux Pods apparaissent. Vous n’avez lancé aucun `kubectl apply` : c’est le commit qui a changé le cluster.

Essayez maintenant l’inverse, pour voir la réconciliation à l’œuvre :

```bash
kubectl -n kube-training scale deployment/flask-gitops --replicas=5
kubectl -n kube-training get pods -l app.kubernetes.io/name=flask-gitops
```

Attendez une minute, puis regardez de nouveau :

```bash
kubectl -n kube-training get pods -l app.kubernetes.io/name=flask-gitops
```

Flux est revenu à deux répliques. **Votre modification manuelle a été annulée**, parce que Git reste la référence. C’est le cœur de GitOps, et c’est aussi ce qui surprend le plus en arrivant dessus.

## 8. Nettoyer

Le nettoyage se fait par Git, pas par `kubectl`. Supprimer l’objet à la main ne servirait à rien : Flux le recréerait à la réconciliation suivante.

```bash
git rm -r apps/flask clusters/kube-training/flask.yaml
git commit -m "Retirer l'application"
git push
flux reconcile kustomization flux-system --with-source
```

Grâce à `prune: true`, Flux supprime du cluster ce qui a disparu de Git :

```bash
kubectl -n kube-training get deployment,svc -l app.kubernetes.io/name=flask-gitops
```

La commande ne doit plus rien renvoyer.

Pour retirer Flux lui-même du cluster :

```bash
flux uninstall --namespace=flux-system
```

Le dépôt `kubernetes-flux-lab` reste sur votre compte GitHub ; supprimez-le depuis l’interface si vous n’en voulez plus. Ne supprimez pas le cluster Kind si vous souhaitez conserver les TP principaux.

## À retenir

- Git contient l’état souhaité ; le cluster le reflète.
- Un changement passe par un commit, jamais par un `kubectl apply`.
- Flux corrige la dérive : une modification manuelle est annulée à la réconciliation suivante.
- `prune: true` fait du dépôt le maître de l’état : retirer un fichier supprime la ressource.
- En mode pull, c’est l’agent dans le cluster qui va chercher le dépôt. Aucun système extérieur ne détient d’accès au cluster — c’est l’argument de sécurité vu en cours.
- Un token ne doit jamais être commité.

## Documentation officielle

- [Flux — Get started](https://fluxcd.io/flux/get-started/)
- [Flux — Installation](https://fluxcd.io/flux/installation/)
- [Flux — Bootstrap GitHub](https://fluxcd.io/flux/installation/bootstrap/github/)

---

**Retour :** [README principal](../../README.md) · [Index des TP](../../tp/README.md)
