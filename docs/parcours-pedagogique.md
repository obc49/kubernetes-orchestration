# Parcours pédagogique — Kubernetes Orchestration (14 heures)

Formation de deux jours, 7 heures effectives par jour. Fil rouge : application Flask, image privée GHCR, déploiement Kubernetes dans Kind, Gateway API avec NGINX Gateway Fabric et exposition LoadBalancer locale avec MetalLB.

## Jour 1 — construire, publier et déployer (7 h)

| Séquence | Contenu | TP associé |
|---|---|---|
| 1. Introduction et architecture (45 min) | Besoins d’orchestration, état désiré, réconciliation, control plane et workers | Démonstrations courtes |
| 2. Application et conteneur (60 min) | Application Flask, endpoints, Dockerfile, image et logs | TP01 |
| 3. Registre et publication (60 min) | GHCR, tags, CI de publication, package privé | TP02 |
| 4. Authentification au registre (45 min) | Token à privilèges minimaux, Secret de pull, namespace | TP03 |
| 5. Objets Kubernetes (120 min) | Namespace, Pod, ReplicaSet, Deployment, labels/selectors, Service, ConfigMap, Secret, probes et ressources | TP04 |
| 6. Déploiement et port-forward (70 min) | Rollout, endpoints, tests HTTP, suppression d’un Pod et réconciliation | TP04 |
| 7. Synthèse et questions (20 min) | Récapitulatif, erreurs courantes, préparation du jour 2 | TP01–TP04 |

## Jour 2 — routage, exposition et diagnostic (7 h)

| Séquence | Contenu | TP associé |
|---|---|---|
| 8. Révision et diagnostic (45 min) | Pods Ready, Service/endpoints, events, logs, requests/limits et probes | TP04 |
| 9. Gateway API (120 min) | CRD, GatewayClass, Gateway, HTTPRoute, NGINX Gateway Fabric et conditions d’état | TP05 |
| 10. LoadBalancer local (90 min) | Service de données NGINX, NodePort, MetalLB, pool IP et chemin réseau depuis l’hôte | TP06 |
| 11. Défi final et restitution (165 min) | Valider le routage, tester les endpoints, supprimer un Pod, diagnostiquer un incident et proposer des améliorations | TP06 |

Les durées comprennent explications, démonstrations, manipulation et débrief ; ajuster la profondeur selon le groupe sans ajouter de TP.

## Objectifs pédagogiques

À la fin, les participants doivent pouvoir :
- expliquer les principaux composants Kubernetes et le modèle déclaratif ;
- construire et identifier une image de conteneur ;
- publier/consommer une image privée GHCR avec un Secret de pull ;
- déployer une application avec Deployment et Service ;
- externaliser la configuration et distinguer Secret et ConfigMap ;
- lire requests/limits et interpréter les probes ;
- exposer l’application avec Gateway API et NGINX Gateway Fabric ;
- comprendre la simulation LoadBalancer avec MetalLB dans Kind ;
- diagnostiquer les problèmes courants avec `kubectl describe`, logs, événements et endpoints.

## Hors socle obligatoire

FluxCD, Vault + External Secrets Operator, RBAC avancé, NetworkPolicy, stockage persistant, autoscaling, scheduler approfondi et architecture de production sont des extensions ou des discussions, sauf adaptation explicite par le formateur.

## Principes d’animation

Pour chaque notion : **concept court → démonstration guidée → TP → correction/débrief**. Les corrections détaillées restent dans le support formateur privé, séparées des énoncés apprenants.

## Points de vigilance

- 1 CPU = 1000m ; 500m = 0,5 CPU.
- Les requests participent au placement ; une limite CPU peut entraîner du throttling ; dépasser une limite mémoire peut conduire à `OOMKilled`.
- Readiness contrôle l’admission du Pod au trafic ; liveness aide à détecter un conteneur qui ne répond plus ; startup protège les démarrages lents.
- Un Secret Kubernetes standard n’est pas automatiquement chiffré.
- Les NetworkPolicies ne sont pas dans le socle ; leur application dépend du CNI.
- Kind et MetalLB constituent un laboratoire, pas un LoadBalancer de production.
