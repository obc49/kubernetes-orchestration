# TP06 — Exposer l’application avec Gateway API

**Objectif :** configurer et diagnostiquer une route HTTP externe avec Gateway API et NGINX Gateway Fabric, puis expliquer le chemin du trafic jusqu’aux Pods.

## Prérequis

- TP03 terminé ; Deployment et Service `flask-app` opérationnels.
- Kind, `kubectl`, Helm 3 et accès Internet.
- Lire le [guide formateur d’installation](../docs/installation-gateway.md).

## Travail demandé

1. Installer les CRD Gateway API standard et NGINX Gateway Fabric selon le guide.
2. Vérifier la GatewayClass `nginx`.
3. Appliquer `manifests/40-gateway.yaml` et `manifests/50-httproute.yaml`.
4. Vérifier les conditions de la Gateway et de l’HTTPRoute.
5. Tester `/`, `/health` et `/ready` depuis l’hôte.
6. Tracer le parcours : client → port mapping Kind → NodePort → proxy NGINX → Gateway/HTTPRoute → Service `flask-app` → Pods.
7. Diagnostiquer une route non acceptée ou un backend sans endpoints à partir des événements, conditions et services.

## Contrôles

```bash
kubectl get gatewayclass
kubectl -n nginx-gateway get pods,svc
kubectl -n kube-training get gateway,httproute
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
kubectl -n kube-training get svc,endpoints
```

Le guide détaille le NodePort 30080 et le mapping de l’hôte sur 127.0.0.1:80. Vérifier le nom du Service de données NGINX créé par le contrôleur avant de lancer les tests ; ne pas confondre ce Service avec celui du contrôleur.

## Vérifications finales

```bash
curl -i -H 'Host: flask.local' http://127.0.0.1/
curl -i -H 'Host: flask.local' http://127.0.0.1/health
curl -i -H 'Host: flask.local' http://127.0.0.1/ready
```

Si l’environnement de poste ne permet pas l’accès via le port mapping, isoler les couches avec un port-forward vers le Service applicatif, puis vers le Service de données NGINX. Noter précisément à quelle couche le test échoue.

## Restitution finale

Démontrer :
- deux Pods applicatifs Ready et un Service avec endpoints ;
- une Gateway programmée et une HTTPRoute acceptée ;
- des réponses HTTP attendues depuis l’hôte ;
- un diagnostic argumenté d’un problème de routage ;
- l’absence de secrets réels dans Git.

## Débrief

- Différence entre GatewayClass, Gateway et HTTPRoute ?
- Pourquoi le Service applicatif reste-t-il un ClusterIP ?
- Que fournit le NodePort dans ce laboratoire, et pourquoi n’est-ce pas un LoadBalancer cloud ?
- Quelles protections supplémentaires faudrait-il prévoir en production ?
