# TP03 — Pod, Deployment, Service et port-forward

**Objectif :** déployer l’application dans Kind et comprendre le rôle du Pod, du Deployment, du ReplicaSet, des labels/selectors et du Service.

## Prérequis

- TP02 terminé : image disponible et Secret `ghcr-pull` créé dans `kube-training`.
- Cluster Kind créé avec `kind/cluster.yaml`.

## Travail demandé

1. Vérifier les nœuds et créer les objets applicatifs.
2. Décrire la relation entre Deployment, ReplicaSet et Pods.
3. Inspecter labels, selectors, probes, Service et endpoints.
4. Attendre la fin du rollout et vérifier les deux réplicas attendus.
5. Tester le Service via `port-forward`.
6. Supprimer un Pod et observer sa recréation par le contrôleur.
7. Simuler un problème de disponibilité en observant les conditions Ready et les endpoints.

## Commandes

```bash
kubectl get nodes -o wide
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/10-configmap.yaml
kubectl apply -f manifests/20-deployment.yaml
kubectl apply -f manifests/30-service.yaml

kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get deploy,rs,pods,svc,endpoints -o wide
kubectl -n kube-training describe deployment flask-app
kubectl -n kube-training get pods --show-labels
```

Dans un terminal dédié :

```bash
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Dans un autre terminal :

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/health
curl -i http://localhost:8080/ready
```

Pour observer la réconciliation, supprimer un Pod identifié avec `kubectl -n kube-training delete pod <nom-du-pod>`, puis surveiller `kubectl -n kube-training get pods -w`.

## Débrief

- Pourquoi un Deployment est-il préférable à un Pod isolé ?
- Quel est le rôle du ReplicaSet ?
- Quelle différence entre Service `port` et `targetPort` ?
- Pourquoi un Service fournit-il un point d’accès plus stable qu’une adresse de Pod ?
- Quelle différence entre Pod en cours d’exécution et Pod Ready ?
