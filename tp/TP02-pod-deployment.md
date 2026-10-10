# TP02 — Pod, Deployment et réconciliation

**Objectif :** déployer l'application et comprendre l'état désiré.

## Travail demandé

1. Créer le cluster Kind.
2. Charger l'image locale dans Kind.
3. Appliquer le Namespace, le ConfigMap et le Deployment.
4. Observer Pods, labels, ReplicaSet et événements.
5. Supprimer un Pod et observer le contrôleur.
6. Passer à trois réplicas, puis revenir à deux.

```bash
kind create cluster --name kube-training --config kind/cluster.yaml
kind load docker-image kubernetes-orchestration:training --name kube-training
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/10-configmap.yaml
kubectl apply -f manifests/20-deployment.yaml
kubectl -n kube-training get deploy,rs,pods -o wide
kubectl -n kube-training describe deployment flask-app
```

## Débrief

- Pourquoi un Deployment plutôt qu'un Pod isolé ?
- Qui recrée un Pod supprimé ?
- Quel est le rôle des selectors et des labels ?
