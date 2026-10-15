# TP04 — Configurer l’application et comprendre ses ressources

## Objectif

Modifier la configuration de l’application, lire ses requests/limits, tester le placement d’un Pod et monter un volume `emptyDir` dans le Deployment.

## Prérequis

- TP03 terminé.
- Le Deployment `flask-app` fonctionne dans le namespace `kube-training`.
- Travaillez depuis la racine du dépôt.

## Partie A — Modifier la configuration avec ConfigMap

Affichez le ConfigMap et la configuration actuelle :

```bash
kubectl -n kube-training get configmap flask-app-config -o yaml
kubectl -n kube-training get pods
```

Ouvrez `manifests/10-configmap.yaml` et modifiez `APP_MESSAGE`, par exemple :

```yaml
APP_MESSAGE: "Mon message a changé"
```

Appliquez la modification et redémarrez les Pods pour que la nouvelle variable d’environnement soit lue :

```bash
kubectl apply -f manifests/10-configmap.yaml
kubectl -n kube-training rollout restart deployment/flask-app
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Dans un autre terminal, vérifiez le nouveau message avec `curl http://localhost:8080/`. Arrêtez le `port-forward` avec `Ctrl+C`.

## Partie B — Secret applicatif

Créez un Secret de démonstration. N’utilisez aucune vraie clé :

```bash
kubectl -n kube-training create secret generic flask-app-secret \
  --from-literal=API_KEY='demo-not-a-real-secret' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n kube-training get secret flask-app-secret
```

Le Deployment référence déjà ce Secret de façon optionnelle. Redémarrez le Deployment puis vérifiez que les Pods sont prêts :

```bash
kubectl -n kube-training rollout restart deployment/flask-app
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get pods
```

Un Secret Kubernetes standard est encodé en base64 ; ce n’est pas automatiquement du chiffrement. Ne l’affichez pas avec `-o yaml` et ne le commitez jamais.

## Partie C — Comprendre requests et limits

Lisez la section `resources` dans `manifests/20-deployment.yaml` :

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 500m
    memory: 128Mi
```

Répondez avant de poursuivre :

- Que représente `100m` de CPU ? (Indice : 1000m = 1 CPU.)
- À quoi sert `requests` lors du placement du Pod ?
- Que peut-il se passer si un conteneur dépasse sa limite mémoire ?

Observez les ressources :

```bash
kubectl -n kube-training describe pod <nom-du-pod>
kubectl describe nodes
kubectl -n kube-training get events --sort-by=.lastTimestamp
```

Remplacez `<nom-du-pod>` par le nom réel d’un Pod.

## Partie D — Observer le placement avec nodeSelector

Un `nodeSelector` demande à Kubernetes de placer le Pod sur un nœud qui possède un label précis.

1. Affichez les noms des nœuds :

```bash
kubectl get nodes
```

2. Choisissez un worker et ajoutez-lui un label :

```bash
kubectl label node <nom-du-worker> tp04=ok
kubectl get nodes --show-labels
```

3. Dans une copie de test du Deployment, ajoutez sous `spec.template.spec` :

```yaml
nodeSelector:
  tp04: ok
```

Appliquez uniquement cette copie de test. Vérifiez sur quel nœud le Pod est placé avec `kubectl get pods -o wide`.

4. Dans la copie de test, remplacez la valeur par `absent`. Observez l’état du Pod et les événements :

```bash
kubectl describe pod <nom-du-pod-de-test>
kubectl get events --sort-by=.lastTimestamp
```

Un Pod sans nœud compatible reste généralement en `Pending` avec un événement de type `FailedScheduling`. Restaurez la configuration et supprimez les ressources de test.

5. Retirez le label ajouté :

```bash
kubectl label node <nom-du-worker> tp04-
```

## Partie E — Monter un volume emptyDir

Un volume `emptyDir` est un répertoire temporaire créé pour un Pod. Les conteneurs du même Pod peuvent le partager. Les données restent disponibles pendant la vie du Pod, mais elles sont perdues quand ce Pod est supprimé et remplacé.

1. Ouvrez `manifests/20-deployment.yaml`.
2. Dans le conteneur `flask-app`, ajoutez sous `ports:` ce montage :

```yaml
          volumeMounts:
            - name: donnees-temporaires
              mountPath: /tmp/formation
```

3. Dans `spec.template.spec`, au même niveau que `containers:`, ajoutez :

```yaml
      volumes:
        - name: donnees-temporaires
          emptyDir: {}
```

Conservez le champ `imagePullSecrets` ajouté au TP03. Respectez l’indentation YAML.

4. Appliquez le Deployment et vérifiez le montage :

```bash
kubectl apply -f manifests/20-deployment.yaml
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get pods
kubectl -n kube-training exec deployment/flask-app -- sh -c 'echo "bonjour" > /tmp/formation/test.txt && cat /tmp/formation/test.txt'
```

5. Supprimez un Pod du Deployment, puis observez sa recréation :

```bash
kubectl -n kube-training get pods
kubectl -n kube-training delete pod <nom-du-pod>
kubectl -n kube-training get pods -w
```

Arrêtez le suivi avec `Ctrl+C`. Une fois le nouveau Pod prêt, vérifiez si le fichier existe :

```bash
kubectl -n kube-training exec deployment/flask-app -- sh -c 'ls -l /tmp/formation'
```

Le nouveau Pod possède un nouveau volume `emptyDir` : l’ancien fichier n’est plus là.

## À retenir

- Un ConfigMap sert à injecter de la configuration non sensible.
- Un Secret sert à stocker des données sensibles, mais doit être protégé par des droits et une configuration adaptés.
- Les requests influencent le placement ; les limits définissent des plafonds.
- `nodeSelector` impose une contrainte simple sur les labels des nœuds.
- `emptyDir` est temporaire : sa durée de vie est celle du Pod, pas celle du conteneur.
- Un PVC sert à demander un stockage persistant ; il n’est pas créé dans cet exercice.

## Questions

1. Pourquoi faut-il redémarrer le Pod pour relire une variable d’environnement issue du ConfigMap ?
2. Quelle différence entre requests et limits ?
3. Pourquoi le Pod reste-t-il Pending quand aucun nœud ne porte le label demandé ?
4. À quel moment les données d’un `emptyDir` sont-elles perdues ?
5. Quelle différence entre `emptyDir` et un stockage persistant demandé via PVC ?


---

**Suite :** [TP05 — Diagnostiquer une panne et vérifier les accès](TP05-administration-diagnostic-securite.md)
