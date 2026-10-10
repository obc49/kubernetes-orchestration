# TP04 — ConfigMap, Secret et stockage éphémère

**Objectif :** séparer la configuration de l'image et distinguer configuration et données sensibles.

## Travail demandé

1. Lire le ConfigMap et repérer les variables d'environnement.
2. Modifier `APP_MESSAGE`, réappliquer le ConfigMap et observer le comportement.
3. Créer le Secret de démonstration.
4. Vérifier que l'application indique seulement si une clé est configurée.
5. Expliquer la différence entre `emptyDir`, ConfigMap et Secret.

```bash
kubectl -n kube-training describe configmap flask-app-config
kubectl -n kube-training create secret generic flask-app-secret \
  --from-literal=API_KEY='demo-not-a-real-secret'
kubectl -n kube-training get secret flask-app-secret
kubectl -n kube-training describe secret flask-app-secret
```

N'utilisez aucun secret personnel ou de production et ne collez pas de valeur secrète dans un manifeste commité.

## Débrief

- Base64 signifie-t-il chiffré ?
- Que se passe-t-il si une variable d'environnement change dans le ConfigMap après le démarrage ?
- Pourquoi RBAC et chiffrement au repos comptent-ils ?
