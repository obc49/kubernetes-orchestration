# Parcours pédagogique — Kubernetes Orchestration (14 heures)

Formation de deux jours, 7 heures effectives par jour (420 minutes). Fil rouge : application Flask, image privée GHCR, déploiement dans Kind, administration Kubernetes et exposition HTTP avec Gateway API + NGINX Gateway Fabric.

## Jour 1 — architecture, conteneur et déploiement (7 h)

| Séquence | Contenu | Durée | TP |
|---|---|---:|---|
| 1. Introduction et architecture | Origines et rôle de Kubernetes, control plane, API Server, etcd, workers, kubelet, Pods, labels, contrôleurs, Services | 60 min | Démonstrations |
| 2. Installation et outillage | Options Minikube/kubeadm/Kind, kubectl, création du cluster de laboratoire et lecture des nœuds | 35 min | Démo guidée |
| 3. Application et conteneur | Flask, endpoints, Dockerfile, construction et inspection d’image | 55 min | TP01 |
| 4. Registre et authentification | GHCR, tags immuables, visibilité privée, token minimal et Secret de pull | 65 min | TP02 |
| 5. Objets et réseau Kubernetes | Namespace, Pod, ReplicaSet, Deployment, labels/selectors, Service, endpoints, port-forward | 125 min | TP03 |
| 6. Récapitulatif | Questions, erreurs fréquentes, vérification des acquis | 20 min | TP01–TP03 |
| 7. Marge pédagogique | Pause active ou approfondissement guidé sans créer de TP supplémentaire | 60 min | Selon le groupe |

**Total jour 1 : 420 minutes.** Les pauses légales/logistiques sont à organiser en dehors des 7 heures effectives si le cadre de la session les exclut.

## Jour 2 — configuration, exploitation et exposition HTTP (7 h)

| Séquence | Contenu | Durée | TP |
|---|---|---:|---|
| 8. Révision et ressources | ConfigMap/Secret, requests/limits CPU-mémoire, probes, stockage éphémère/persistant, placement et contraintes de nœuds | 90 min | TP04 |
| 9. Administration et diagnostic | `kubectl describe`, logs, events, `kubectl exec`, état des nœuds, incidents de scheduling et d’application | 100 min | TP05 |
| 10. Sécurité et observabilité | RBAC/API, exposition minimale, NetworkPolicy et dépendance au CNI, protection d’etcd, rôle de Node Problem Detector et de StackDriver/Cloud Monitoring | 65 min | TP05 |
| 11. Gateway API | CRD, GatewayClass, Gateway, HTTPRoute, NGINX Gateway Fabric, conditions d’état et chemin du trafic | 105 min | TP06 |
| 12. Défi final et restitution | Déployer, tester, diagnostiquer une panne, démontrer le routage et présenter les limites du laboratoire | 60 min | TP03–TP06 |

**Total jour 2 : 420 minutes.** Les durées incluent explications, démonstrations, manipulation et débrief ; ajuster la profondeur au groupe sans ajouter de TP.

## Objectifs pédagogiques

À la fin, les participants doivent pouvoir :
- expliquer les composants Kubernetes, le modèle déclaratif et le cycle de réconciliation ;
- distinguer les options d’installation et utiliser un cluster de laboratoire ;
- déployer une application avec Pod, Deployment et Service ;
- configurer l’application et interpréter requests/limits, probes, stockage et placement ;
- administrer et diagnostiquer un cluster avec les commandes kubectl essentielles ;
- expliquer les contrôles d’accès API, RBAC, les limites des Secrets, les NetworkPolicies et la protection d’etcd ;
- comprendre les rôles de Node Problem Detector et des solutions de supervision cloud, sans imposer leur installation dans le laboratoire ;
- exposer une application HTTP avec Gateway API et NGINX Gateway Fabric.

## Hors socle obligatoire

FluxCD, Vault + External Secrets Operator, mise en place complète de Node Problem Detector ou Cloud Monitoring, stockage persistant de production, autoscaling et architecture HA sont des extensions ou des discussions, sauf adaptation explicite par le formateur.

## Principes d’animation

Pour chaque notion : **concept court → démonstration guidée → TP → correction/débrief**. Les corrections détaillées restent dans le support formateur privé, séparées des énoncés apprenants.

## Points de vigilance formateur

- 1 CPU = 1000m ; 500m = 0,5 CPU.
- Les requests participent au placement ; une limite CPU peut entraîner du throttling ; dépasser une limite mémoire peut conduire à `OOMKilled`.
- Readiness contrôle l’admission du Pod au trafic ; liveness aide à détecter un conteneur qui ne répond plus ; startup protège les démarrages lents.
- Une variable d’environnement issue d’un ConfigMap ou Secret est lue au démarrage du conteneur ; un redémarrage du Pod est nécessaire pour charger la nouvelle valeur.
- Un Secret Kubernetes standard n’est pas automatiquement chiffré.
- Les NetworkPolicies ne sont effectives que si le CNI les applique.
- Kind est un laboratoire, pas une représentation complète d’un cluster de production.
