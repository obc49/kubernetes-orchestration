# TP05 — Administration, diagnostic et sécurité

**Objectif :** diagnostiquer un incident à partir de l’état désiré, des événements, des logs et des ressources ; connaître les contrôles de sécurité essentiels d’un cluster.

## Prérequis

- TP03 et TP04 terminés.
- Cluster Kind disponible et application déployée.

## Partie A — diagnostic guidé

Le formateur fournit ou provoque un incident contrôlé (par exemple un sélecteur erroné dans une copie de Service, une image inexistante dans un Deployment de test, ou une contrainte de placement impossible). Ne pas casser durablement le Deployment fil rouge.

Suivre une démarche structurée :

1. Observer l’état global et les nœuds.
2. Identifier le Pod ou l’objet en anomalie.
3. Lire les événements et la description de l’objet.
4. Lire les logs et, si nécessaire, exécuter une commande dans un conteneur.
5. Vérifier Service, labels/selectors et endpoints.
6. Formuler une hypothèse, tester une correction et vérifier le retour à l’état attendu.

```bash
kubectl get nodes
kubectl -n kube-training get deploy,rs,pods,svc,endpoints
kubectl -n kube-training get events --sort-by=.lastTimestamp
kubectl -n kube-training describe pod <nom-du-pod>
kubectl -n kube-training logs deployment/flask-app --all-pods=true
kubectl -n kube-training exec deployment/flask-app -- printenv APP_ENV
kubectl -n kube-training get endpoints flask-app
```

Pour comparer les logs du conteneur précédent après un redémarrage, utiliser `kubectl logs <pod> --previous` si un conteneur précédent existe.

## Partie B — administration et supervision

Expliquer le rôle de `kubectl`, API Server, etcd, kubelet et du control plane. Distinguer les logs applicatifs, les événements Kubernetes, les métriques et les alertes. Présenter conceptuellement Node Problem Detector pour la détection de problèmes de nœud et StackDriver (désormais associé à Google Cloud Operations) comme exemple de supervision cloud ; leur installation complète n’est pas requise dans ce laboratoire.

## Partie C — sécurité

Pour chaque point, donner un risque et une mesure de réduction :

- **API et RBAC :** authentification, autorisation, moindre privilège, comptes de service et séparation des namespaces.
- **Secrets :** éviter Git et les logs ; limiter les accès ; comprendre que base64 n’est pas du chiffrement.
- **Ressources :** requests/limits, quotas et limites de namespace comme moyens de réduire les abus de ressources.
- **Réseau :** rôle des NetworkPolicies et fait que leur effet dépend du CNI.
- **etcd :** accès réseau restreint, authentification/chiffrement adaptés et protection des sauvegardes.
- **Nœuds :** correctifs, accès d’administration limité et surveillance de l’état des nœuds.

Dans Kind, identifier ce qui est réellement configuré et ce qui reste une recommandation ou une démonstration conceptuelle. Ne pas prétendre qu’une NetworkPolicy est appliquée si le CNI ne la prend pas en charge.

## Restitution

Présenter l’incident, les indices observés, la cause probable, la correction, puis deux mesures de prévention. Indiquer explicitement les limites du laboratoire par rapport à un cluster de production.

## Débrief

- Quelle différence entre `describe`, `logs` et `exec` ?
- Pourquoi un Pod Running peut-il ne pas recevoir de trafic ?
- Quelle différence entre authentification et autorisation RBAC ?
- Pourquoi faut-il protéger etcd et ses sauvegardes ?
