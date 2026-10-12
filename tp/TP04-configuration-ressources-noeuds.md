# TP04 — Configuration, ressources, placement et stockage

**Objectif :** configurer une application et lire les paramètres qui influencent le démarrage, le placement et la consommation de ressources des Pods.

## Prérequis

- TP03 terminé ; application déployée dans `kube-training`.
- Savoir lire un manifeste YAML et utiliser `kubectl`.

## Partie A — ConfigMap et Secret

1. Lire `manifests/10-configmap.yaml` et identifier la configuration injectée dans l’application.
2. Modifier `APP_MESSAGE`, appliquer le ConfigMap et redémarrer le Deployment pour recharger la variable d’environnement.
3. Créer un Secret applicatif de démonstration, sans donnée réelle, et vérifier que l’application indique uniquement si la clé est configurée.

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

Ne jamais afficher ni commiter de valeur réelle. Un Secret Kubernetes standard est encodé en base64, ce qui ne constitue pas à lui seul du chiffrement.

## Partie B — requests, limits et placement

1. Lire les champs `resources.requests` et `resources.limits` dans `manifests/20-deployment.yaml`.
2. Convertir `500m` en CPU et expliquer la différence entre request et limit.
3. Inspecter les Pods et les nœuds :

```bash
kubectl -n kube-training get pods -o wide
kubectl -n kube-training describe pod <nom-du-pod>
kubectl describe nodes
kubectl -n kube-training get events --sort-by=.lastTimestamp
```

4. À partir d’un exemple fourni par le formateur, ajouter temporairement un `nodeSelector` à un manifeste de test, puis expliquer ce qui se passe si aucun nœud ne possède le label demandé. Ne pas modifier le Deployment fil rouge sans conserver une copie du manifeste initial.
5. Distinguer `Pending`, `FailedScheduling`, `OOMKilled` et throttling CPU.

## Partie C — stockage

Comparer les usages d’un volume éphémère `emptyDir`, d’un volume persistant revendiqué par PVC et d’un stockage externe. Identifier quelles données survivent à la recréation d’un conteneur ou d’un Pod. Le laboratoire ne nécessite pas d’installer un provisionneur de stockage persistant.

## Débrief

- Pourquoi les requests influencent-elles le placement ?
- Que peut-il arriver lorsqu’une limite mémoire est dépassée ?
- Pourquoi une variable d’environnement n’est-elle pas actualisée dans un processus déjà démarré ?
- Quand choisir ConfigMap, Secret, stockage éphémère ou stockage persistant ?
