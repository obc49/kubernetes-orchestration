# TP02 — Image privée GHCR et authentification Kubernetes

**Objectif :** identifier une version d’image reproductible et autoriser Kubernetes à la télécharger depuis un registre privé, sans intégrer de credentials dans l’image ou dans Git.

## Prérequis

- Docker, `kubectl` et accès au dépôt/package GitHub.
- Identifiant GitHub et token autorisé à lire le package (`read:packages`).
- Ne jamais utiliser un token de production ni commiter les valeurs.

## Partie A — image et registre

1. Ouvrir l’onglet Actions et repérer le workflow de publication GHCR.
2. Identifier le package `ghcr.io/oboyo-training/kubernetes-orchestration` et vérifier sa visibilité.
3. Relever le tag SHA disponible et celui communiqué par le formateur.
4. Expliquer pourquoi un tag SHA est plus reproductible que `latest`.
5. Si le formateur l’autorise, construire et publier une image depuis un poste autorisé.

La visibilité privée doit être vérifiée dans GitHub Packages ; le workflow ne la définit pas automatiquement.

## Partie B — Secret de pull

Créer le namespace puis le Secret `ghcr-pull`. Saisir le token de façon masquée :

```bash
kubectl apply -f manifests/00-namespace.yaml

read -p "Identifiant GitHub : " GHCR_USER
read -s -p "Token avec read:packages : " GHCR_TOKEN
echo

kubectl -n kube-training create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USER" \
  --docker-password="$GHCR_TOKEN" \
  --docker-email="training@example.invalid" \
  --dry-run=client -o yaml | kubectl apply -f -

unset GHCR_TOKEN
unset GHCR_USER

kubectl -n kube-training get secret ghcr-pull
kubectl -n kube-training describe secret ghcr-pull
```

Ne pas exécuter `kubectl get secret ghcr-pull -o yaml` pendant la séance. Vérifier dans le Deployment le champ `imagePullSecrets` et expliquer pourquoi le Secret doit être dans le même namespace que le Pod.

## Vérifications

- Package disponible avec un tag précis.
- Secret `ghcr-pull` présent dans `kube-training`, sans afficher sa valeur.
- Aucun token ou fichier de credentials dans Git.
- Le tag configuré dans `manifests/20-deployment.yaml` correspond à une image réellement disponible.

## En cas d’échec

- `ImagePullBackOff` : vérifier le nom du tag, la visibilité du package, les permissions du token et le Secret dans le bon namespace.
- Ne pas basculer vers un package public ou une image locale sans l’accord du formateur ; cela masquerait le problème d’authentification.

## Débrief

- À quoi sert un registre d’images ?
- Quelle différence entre tag mutable et tag SHA ?
- Quelle différence entre `read:packages` et `write:packages` ?
- Pourquoi ne faut-il jamais publier un token dans Git ou dans les logs ?
