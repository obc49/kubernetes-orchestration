# TP03 — Authentifier Kubernetes auprès de GHCR

**Objectif :** permettre à un Pod de télécharger une image privée sans intégrer de credentials dans l’image ou les manifests versionnés.

## Prérequis

- Package GHCR privé et tag d’image communiqué par le formateur.
- Namespace `kube-training` créé.
- Token autorisé à lire le package (`read:packages`) et nom d’utilisateur GitHub.
- Ne jamais utiliser un token de production ni commiter les valeurs.

## Travail demandé

1. Créer le namespace s’il n’existe pas.
2. Créer le Secret de type `docker-registry` nommé `ghcr-pull`.
3. Vérifier le nom et le type du Secret sans afficher son contenu.
4. Expliquer pourquoi le Secret doit être dans le même namespace que le Pod.
5. Repérer dans le Deployment le champ `imagePullSecrets`.

## Commandes Bash

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

Ne pas exécuter `kubectl get secret ghcr-pull -o yaml` pendant la séance : cela expose des données encodées qui peuvent être copiées par erreur.

## Débrief

- Pourquoi Kubernetes a-t-il besoin d’un Secret de pull ?
- Pourquoi le Secret ne doit-il pas être commité ?
- Quelle différence entre `read:packages` et `write:packages` ?
- Que rechercher en cas de `ImagePullBackOff` ?
