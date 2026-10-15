# Programme — Kubernetes : orchestration des conteneurs

Formation de deux jours, soit 14 heures. Le parcours suit une progression simple : **comprendre une notion, observer une démonstration, la mettre en pratique, puis vérifier le résultat**.

## Jour 1 — Découvrir Kubernetes et déployer une application

| Séquence | Contenu | TP |
|---|---|---|
| Introduction | Pourquoi Kubernetes, modèle déclaratif, état souhaité | Démonstrations |
| Architecture | Control plane, API Server, etcd, scheduler, controller manager, kubelet, nœuds et Pods | Démonstrations |
| Installation | Options d’installation, Kind, kubectl, vérification du cluster | TP02 |
| Application et conteneurs | Application Flask, Dockerfile, image, conteneur, endpoints | TP01 |
| Registre d’images | GHCR, tags, publication d’une image | TP01 |
| Premiers objets Kubernetes | Namespace, Pod, labels, selectors, Service, port-forward | TP02 |
| Déploiement de l’application | Deployment, ReplicaSet, Service, image privée et imagePullSecret | TP03 |

## Jour 2 — Configurer, administrer et exposer l’application

| Séquence | Contenu | TP |
|---|---|---|
| Configuration | ConfigMap et Secret | TP04 |
| Ressources et placement | Requests, limits CPU/mémoire, nodeSelector et événements de scheduling | TP04 |
| Stockage | Volume emptyDir, durée de vie des données, introduction au PVC et au stockage persistant | TP04 |
| Administration | get, describe, logs, exec, events, états des Pods et méthode de diagnostic | TP05 |
| Sécurité | RBAC, ServiceAccount, moindre privilège, Secrets, NetworkPolicy et limites du laboratoire | TP05 |
| Supervision | Logs, événements, métriques, détection de problèmes de nœud et solutions de supervision cloud | TP05 |
| Exposition HTTP | Gateway API, GatewayClass, Gateway, HTTPRoute et NGINX Gateway Fabric | TP06 |
| Synthèse | Vérification du fonctionnement, diagnostic et restitution | TP03 à TP06 |

## Objectifs pédagogiques

À la fin de la formation, vous serez capable de :

- expliquer le rôle de Kubernetes et les principaux composants d’un cluster ;
- créer et inspecter un cluster de laboratoire avec Kind et kubectl ;
- construire et publier une image de conteneur ;
- créer un Pod, un Service, un namespace, des labels et des selectors ;
- déployer une application avec Deployment et comprendre le rôle du ReplicaSet ;
- configurer une application avec ConfigMap et Secret ;
- lire requests et limits, observer le placement et utiliser un volume emptyDir ;
- diagnostiquer les problèmes courants à partir des états, événements, descriptions et logs ;
- expliquer les bases de RBAC et les limites des NetworkPolicies selon le CNI ;
- comprendre le rôle des outils de détection des problèmes de nœud et de supervision ;
- exposer une application HTTP avec Gateway API.

## Documentation officielle

- [Kubernetes — Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes — Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl — Référence rapide](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
- [Kind — Documentation](https://kind.sigs.k8s.io/)
- [Gateway API — Documentation](https://gateway-api.sigs.k8s.io/)
- [NGINX Gateway Fabric — Documentation](https://docs.nginx.com/nginx-gateway-fabric/)
- [Flux — Documentation](https://fluxcd.io/flux/)
- [External Secrets Operator — Documentation](https://external-secrets.io/)
- [HashiCorp Vault — Documentation](https://developer.hashicorp.com/vault/docs)
