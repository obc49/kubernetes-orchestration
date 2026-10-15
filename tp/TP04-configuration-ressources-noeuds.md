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

Un `nodeSelector` demande à Kubernetes de placer un Pod sur un nœud qui possède un label précis. Nous allons utiliser un Deployment de test pour ne pas modifier l’application principale.

1. Choisissez un worker et ajoutez-lui un label :

```bash
kubectl get nodes
kubectl label node <nom-du-worker> tp04=ok
kubectl get nodes --show-labels
```

Remplacez `<nom-du-worker>` par le nom réel du worker.

2. Créez une copie du Deployment :

```bash
cp manifests/20-deployment.yaml /tmp/deployment-tp04.yaml
```

Dans `/tmp/deployment-tp04.yaml`, effectuez les modifications suivantes :

- `metadata.name` : `flask-app-tp04`
- `spec.replicas` : `1`
- `spec.selector.matchLabels.app.kubernetes.io/name` : `flask-app-tp04`
- `spec.template.metadata.labels.app.kubernetes.io/name` : `flask-app-tp04`
- Sous `spec.template.spec`, ajoutez :

```yaml
      nodeSelector:
        tp04: ok
```

Conservez l’image et `imagePullSecrets` du fichier d’origine. Si l’image GHCR est privée, le Deployment de test doit lui aussi référencer `ghcr-pull`.

3. Appliquez le Deployment de test et observez le nœud choisi :

```bash
kubectl apply -f /tmp/deployment-tp04.yaml
kubectl -n kube-training rollout status deployment/flask-app-tp04
kubectl -n kube-training get pods -l app.kubernetes.io/name=flask-app-tp04 -o wide
```

4. Dans le même fichier, remplacez `tp04: ok` par `tp04: absent`, puis appliquez la modification :

```bash
kubectl apply -f /tmp/deployment-tp04.yaml
kubectl -n kube-training get pods -l app.kubernetes.io/name=flask-app-tp04
kubectl -n kube-training get events --sort-by=.lastTimestamp
```

Le nouveau Pod reste normalement `Pending`, car aucun nœud ne porte le label demandé. L’application principale `flask-app` continue de fonctionner : vous avez modifié uniquement le Deployment de test.

5. Supprimez le Deployment de test et le label :

```bash
kubectl -n kube-training delete deployment flask-app-tp04
kubectl label node <nom-du-worker> tp04-
rm -f /tmp/deployment-tp04.yaml
```

## Partie E — Monter un volume emptyDir (facultatif)

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

## Partie F — Mettre à jour l’application et revenir en arrière (environ 15 minutes)

Cette partie vous montre comment publier une nouvelle version, effectuer un rolling update et revenir à la version précédente.

1. Dans `app/app.py`, modifiez le message par défaut retourné par la page d’accueil. Par exemple, remplacez `Application Flask opérationnelle.` par `Version TP04-2 : application mise à jour.`

2. Construisez et publiez une nouvelle image. Utilisez le même compte GHCR que dans le TP01 :

```bash
export OWNER="votre-identifiant-github"
export IMAGE="ghcr.io/$OWNER/kubernetes-orchestration"
docker build -t "$IMAGE:tp04-2" .
docker push "$IMAGE:tp04-2"
```

Vérifiez que le package reste privé. Le Secret `ghcr-pull` créé au TP03 doit toujours permettre de télécharger cette image.

3. Remplacez l’image du Deployment :

```bash
kubectl -n kube-training set image deployment/flask-app flask-app="$IMAGE:tp04-2"
kubectl -n kube-training rollout status deployment/flask-app
```

4. Observez les ReplicaSets et l’historique :

```bash
kubectl -n kube-training get replicasets
kubectl -n kube-training rollout history deployment/flask-app
```

Vous devez voir l’ancien ReplicaSet et le nouveau. Kubernetes remplace progressivement les Pods selon la stratégie de mise à jour du Deployment.

5. Revenez à la version précédente :

```bash
kubectl -n kube-training rollout undo deployment/flask-app
kubectl -n kube-training rollout status deployment/flask-app
```

6. Vérifiez le message précédent avec un `port-forward` :

```bash
kubectl -n kube-training port-forward svc/flask-app 8080:80
```

Dans un autre terminal :

```bash
curl -i http://127.0.0.1:8080/
```

Arrêtez le `port-forward` avec `Ctrl+C`. Le titre HTML précédent doit être revenu. Pour le vérifier, cherchez la balise `<title>` dans la réponse de `curl`.  Si le port 8080 est déjà utilisé, choisissez un autre port local libre.

## À retenir

- Un ConfigMap sert à injecter de la configuration non sensible.
- Un Secret sert à stocker des données sensibles, mais doit être protégé par des droits et une configuration adaptés.
- Les requests influencent le placement ; les limits définissent des plafonds.
- `nodeSelector` impose une contrainte simple sur les labels des nœuds.
- `emptyDir` est temporaire : sa durée de vie est celle du Pod, pas celle du conteneur.
- Un rolling update remplace progressivement les Pods ; `rollout undo` permet de revenir à la révision précédente.
- Un PVC sert à demander un stockage persistant ; il n’est pas créé dans cet exercice.

## Questions

1. Pourquoi faut-il redémarrer le Pod pour relire une variable d’environnement issue du ConfigMap ?
2. Quelle différence entre requests et limits ?
3. Pourquoi le Pod reste-t-il Pending quand aucun nœud ne porte le label demandé ?
4. À quel moment les données d’un `emptyDir` sont-elles perdues ?
5. Quelle différence entre `emptyDir` et un stockage persistant demandé via PVC ?


---

**Suite :** [TP05 — Diagnostiquer une panne et vérifier les accès](TP05-administration-diagnostic-securite.md)
