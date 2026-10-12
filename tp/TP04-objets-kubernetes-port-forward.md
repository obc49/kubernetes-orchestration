# TP04 — Objets Kubernetes et port-forward

**Objectif :** déployer l’application dans Kind et comprendre Namespace, ConfigMap, Deployment, ReplicaSet, Pod et Service.

## Travail demandé

1. Créer le cluster Kind si nécessaire et vérifier ses nœuds.
2. Appliquer le Namespace et le ConfigMap.
3. Vérifier que le Deployment référence l’image et le Secret de pull.
4. Déployer l’application et attendre le rollout.
5. Inspecter labels, Pods, ReplicaSet, Service et endpoints.
6. Tester l’application avec `port-forward`.
7. Supprimer un Pod et observer sa recréation.
8. Modifier `APP_MESSAGE` dans le ConfigMap, puis redémarrer le Deployment pour recharger les variables d’environnement.
9. Créer le Secret applicatif de démonstration et vérifier que seule sa présence est indiquée.

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

kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Dans un second terminal :

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/health
curl -i http://localhost:8080/ready
```

### Configuration et Secret applicatif

Modifier `APP_MESSAGE` dans `manifests/10-configmap.yaml`, puis :

```bash
kubectl apply -f manifests/10-configmap.yaml
kubectl -n kube-training rollout restart deployment/flask-app
kubectl -n kube-training rollout status deployment/flask-app

kubectl -n kube-training create secret generic flask-app-secret \
  --from-literal=API_KEY='demo-not-a-real-secret' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n kube-training rollout restart deployment/flask-app
kubectl -n kube-training rollout status deployment/flask-app
```

Recharger la page et vérifier que l’application indique uniquement si une clé est configurée. Ne pas afficher ni commiter de valeur réelle.

## Débrief

- Pourquoi un Deployment est-il préférable à un Pod isolé ?
- Quelle différence entre Service `port` et `targetPort` ?
- Pourquoi modifier une variable du ConfigMap ne modifie-t-il pas l’environnement d’un processus déjà démarré ?
- Pourquoi un Service donne-t-il un point d’accès plus stable qu’une adresse de Pod ?
