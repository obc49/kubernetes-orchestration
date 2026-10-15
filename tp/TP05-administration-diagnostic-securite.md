# TP05 — Diagnostiquer une panne et vérifier les accès

## Objectif

Utiliser les commandes de base pour trouver la cause d’un problème, corriger la configuration, puis vérifier les droits d’accès d’un compte de service.

## Prérequis

- TP03 terminé ; l’application fonctionne dans `kube-training`.
- TP04 terminé.
- Le cluster Kind est démarré.

## Partie A — Diagnostiquer un problème de Service

1. Vérifiez l’état de l’application :

```bash
kubectl -n kube-training get deployment,pods,svc,endpoints
```

2. Ouvrez `manifests/30-service.yaml`. Dans une copie nommée `/tmp/service-tp05.yaml`, remplacez temporairement le selector `app.kubernetes.io/name: flask-app` par `app.kubernetes.io/name: mauvaise-valeur`.

3. Appliquez la copie de test :

```bash
kubectl apply -f /tmp/service-tp05.yaml
kubectl -n kube-training get svc,endpoints
```

Le Service n’a plus d’endpoints car son selector ne correspond à aucun Pod. Retrouvez les labels des Pods et le selector du Service :

```bash
kubectl -n kube-training get pods --show-labels
kubectl -n kube-training describe svc flask-app
```

4. Restaurez le Service depuis le manifeste d’origine :

```bash
kubectl apply -f manifests/30-service.yaml
kubectl -n kube-training get endpoints flask-app
```

Les endpoints doivent réapparaître.

## Partie B — Utiliser les outils de diagnostic

Exécutez les commandes et identifiez ce que chacune apporte :

```bash
kubectl -n kube-training get pods
kubectl -n kube-training describe pod <nom-du-pod>
kubectl -n kube-training logs <nom-du-pod>
kubectl -n kube-training get events --sort-by=.lastTimestamp
kubectl -n kube-training exec deployment/flask-app -- printenv APP_ENV
```

Remplacez `<nom-du-pod>` par un nom de Pod existant. Si un conteneur a redémarré, `kubectl logs <nom-du-pod> --previous` permet de consulter les logs du conteneur précédent.

## Partie C — Vérifier les droits avec RBAC

RBAC permet de définir ce qu’un compte a le droit de faire dans Kubernetes. Nous allons autoriser un compte de service à lire les ConfigMaps du namespace `kube-training`.

Créez les ressources :

```bash
kubectl -n kube-training create serviceaccount lecteur-config
```

Créez le fichier `/tmp/role-tp05.yaml` :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: lecture-configmaps
  namespace: kube-training
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: lecteur-config-binding
  namespace: kube-training
subjects:
  - kind: ServiceAccount
    name: lecteur-config
    namespace: kube-training
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: lecture-configmaps
```

Appliquez le fichier et vérifiez les droits :

```bash
kubectl apply -f /tmp/role-tp05.yaml
kubectl auth can-i get configmaps -n kube-training --as=system:serviceaccount:kube-training:lecteur-config
kubectl auth can-i delete pods -n kube-training --as=system:serviceaccount:kube-training:lecteur-config
```

Résultat attendu : la première commande répond `yes`, la seconde `no`. Le compte ne reçoit que les droits définis dans le Role.

## Partie D — Comprendre les limites de la sécurité réseau

Une NetworkPolicy peut limiter les flux entre Pods, mais son effet dépend du plugin réseau (CNI) qui équipe le cluster. Dans ce laboratoire, ne concluez pas qu’un flux est bloqué simplement parce qu’un manifeste NetworkPolicy est accepté par l’API.

Répondez à ces questions :
- Quel risque réduit une NetworkPolicy ?
- Pourquoi faut-il vérifier que le CNI applique les règles ?
- Pourquoi un Secret Kubernetes ne doit-il pas être commité dans Git ?
- Pourquoi faut-il limiter les droits RBAC au strict nécessaire ?

## Partie E — Observer l’état des nœuds et la supervision

Kubernetes expose l’état de chaque nœud et les événements récents. Utilisez ces commandes :

```bash
kubectl get nodes
kubectl describe node <nom-du-worker>
kubectl get events -A --field-selector type=Warning
```

Remplacez `<nom-du-worker>` par le nom d’un nœud. Dans la sortie de `describe node`, repérez la section `Conditions` et les événements. Les conditions indiquent si le nœud est prêt et si certains problèmes sont détectés.

**Node Problem Detector** est un composant qui surveille le nœud lui-même, par exemple le noyau, le disque ou le runtime des conteneurs. Il remonte les problèmes détectés sous forme de conditions et d’événements Kubernetes. Il n’est pas installé dans ce laboratoire.

**Google Cloud Operations** (anciennement Stackdriver) est un exemple d’outillage de supervision proposé par un fournisseur cloud. Il peut centraliser les journaux, les métriques et les alertes d’un environnement cloud. Il n’est pas installé dans ce laboratoire.

Distinguez ces quatre notions :

- **Logs** : messages émis par une application ou un composant.
- **Événements** : faits ponctuels enregistrés par Kubernetes, par exemple un échec de scheduling.
- **Métriques** : mesures numériques suivies dans le temps, comme l’utilisation CPU ou mémoire.
- **Alertes** : notifications déclenchées lorsqu’une règle ou un seuil est atteint.

## Nettoyage

Supprimez les ressources RBAC créées pour ce TP :

```bash
kubectl -n kube-training delete rolebinding lecteur-config-binding
kubectl -n kube-training delete role lecture-configmaps
kubectl -n kube-training delete serviceaccount lecteur-config
rm -f /tmp/role-tp05.yaml /tmp/service-tp05.yaml
```

## À retenir

Pour diagnostiquer, vérifiez l’état, les événements, la description de la ressource et les logs. Formulez une hypothèse, corrigez un seul élément, puis vérifiez le résultat.

## Questions

1. Pourquoi un Pod peut-il être Ready alors que le Service n’a aucun endpoint ?
2. Quelle différence entre `get`, `describe`, `logs` et `exec` ?
3. À quoi servent Role et RoleBinding ?
4. Pourquoi la commande `kubectl auth can-i` est-elle utile ?
5. Pourquoi faut-il tester l’effet d’une NetworkPolicy sur un CNI qui la prend en charge ?
6. Quelle différence entre logs, événements, métriques et alertes ?
7. Quel type de problème Node Problem Detector peut-il signaler ?


---

**Suite :** [TP06 — Exposer l’application avec Gateway API](TP06-gateway-api.md)
