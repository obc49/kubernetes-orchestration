# TP05 — Exposer l’application avec Gateway API

**Objectif :** configurer un point d’entrée HTTP avec Gateway API et NGINX Gateway Fabric, sans utiliser l’ancien contrôleur `ingress-nginx`.

## Prérequis

- TP04 terminé ; Deployment disponible et Service `flask-app` opérationnel.
- Kind, `kubectl` et Helm 3.
- Suivre les versions fixées et les commandes du [guide d’installation](../docs/installation-gateway-metallb.md).

## Travail demandé

1. Installer les CRD Gateway API standard.
2. Installer NGINX Gateway Fabric avec la version fixée dans le guide.
3. Appliquer `manifests/40-gateway.yaml` et `manifests/50-httproute.yaml`.
4. Vérifier que la Gateway est programmée et que la route est acceptée.
5. Tester `/`, `/health` et `/ready` via un port-forward vers le Service de données NGINX.
6. Expliquer le trajet du trafic : client → NGINX Gateway Fabric → Gateway/HTTPRoute → Service `flask-app` → Pods.

## Commandes de contrôle

```bash
kubectl get gatewayclass
kubectl -n nginx-gateway get pods,svc
kubectl -n kube-training get gateway,httproute
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
kubectl -n kube-training get endpoints flask-app
```

Après avoir créé la Gateway, le Service de données NGINX associé est normalement `flask-gateway-nginx` dans le namespace `kube-training`. Vérifier son nom avec `kubectl -n kube-training get svc`, puis utiliser le port-forward documenté dans le guide formateur. Ne pas transférer le port vers le Service du contrôleur dans `nginx-gateway`. Ouvrir un second terminal pour les requêtes HTTP.

## En cas d’échec

- Vérifier que les CRD sont installées.
- Vérifier que `GatewayClass nginx` est `Accepted=True`.
- Vérifier les conditions `Accepted` et `Programmed` de la Gateway et de la route.
- Vérifier que le Service `flask-app` possède des endpoints.
- Consulter les événements et les logs du contrôleur.
- Utiliser `port-forward svc/flask-app 8080:80` comme diagnostic de secours pour isoler le problème de routage.

## Débrief

- Différence entre GatewayClass, Gateway et HTTPRoute ?
- Pourquoi le Service applicatif reste-t-il un ClusterIP ?
- Quelle est la différence entre un contrôleur, une ressource de configuration et le backend applicatif ?
