# Parcours pédagogique — socle technique

Ce dépôt accompagne une formation de 14 heures sur deux jours. Le formateur ajuste les durées au niveau du groupe.

## Jour 1 — comprendre et déployer

1. Pourquoi Kubernetes : état désiré, réconciliation et cas d'usage.
2. Architecture : API Server, etcd, scheduler, controller-manager, kubelet et runtime ; prise en main de Kind.
3. Pod, ReplicaSet et Deployment : déclarer, observer, mettre à l'échelle, supprimer un Pod et constater la réconciliation.
4. Service et réseau : labels/selectors, ClusterIP, DNS interne, port-forward.
5. Configuration : ConfigMap, Secret, stockage éphémère et limites.
6. TP d'intégration : déployer et exposer l'application.

## Jour 2 — exploiter, diagnostiquer et sécuriser

7. Requests/limits et placement : capacité, Pending, CPU en millicores, mémoire et nodeSelector.
8. Cycle de vie, probes et diagnostic : describe, logs, logs --previous, événements, CrashLoopBackOff, ImagePullBackOff.
9. Sécurité : contexte d'exécution, ServiceAccount/RBAC, Secrets, moindre privilège et limites des NetworkPolicies.
10. Administration : rollouts, mise à l'échelle, mise à jour et retour arrière.
11. Mini-projet final, restitution et synthèse.

## Philosophie d'animation

Pour chaque notion : **concept court → démonstration guidée → TP → débrief**. Les slides expliquent les décisions et les pièges ; elles ne remplacent pas la manipulation.

## Notes techniques à ne pas oublier

- 1 CPU = 1000m ; 500m = 0,5 CPU.
- Les requests servent notamment au placement ; une limite CPU peut provoquer du throttling ; dépasser une limite mémoire peut entraîner un OOMKilled.
- Un Secret Kubernetes standard est encodé en base64, pas automatiquement chiffré.
- La readiness probe contrôle si le Pod reçoit du trafic ; la liveness probe aide à détecter un processus qui ne répond plus ; la startup probe protège les démarrages lents.
- NetworkPolicy : vérifier le CNI et son mode d'application avant la démonstration. Kind seul ne garantit pas l'application des politiques réseau.
