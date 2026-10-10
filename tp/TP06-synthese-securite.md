# TP06 — Synthèse et sécurité

**Objectif :** livrer un déploiement vérifié et justifier les choix techniques.

## Mission

À partir des fichiers du dépôt, livrer l'application dans le namespace `kube-training` et démontrer :

- deux réplicas disponibles ;
- un Service qui cible les bons Pods ;
- une configuration externalisée ;
- des probes et des ressources définies ;
- un conteneur exécuté sans root ;
- une méthode de diagnostic documentée ;
- aucun secret réel dans Git.

## Vérifications attendues

```bash
kubectl -n kube-training get all
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training describe deployment flask-app
kubectl -n kube-training get endpoints flask-app
kubectl -n kube-training port-forward svc/flask-app 8080:80
curl -i http://localhost:8080/health
```

## Restitution

Présenter l'architecture, expliquer une panne rencontrée et sa résolution, puis citer deux améliorations à envisager avant une mise en production.

La sécurité Kubernetes ne se résume pas à un Secret : elle inclut identités, RBAC, moindre privilège, configuration des conteneurs, réseau, images et observabilité.
