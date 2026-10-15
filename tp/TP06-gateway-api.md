# TP06 — Exposer l’application avec Gateway API

## Objectif

Installer le contrôleur NGINX Gateway Fabric, créer une Gateway et une HTTPRoute, puis accéder à l’application depuis votre navigateur ou avec `curl`.

## Prérequis

- TP03 terminé : l’application fonctionne dans `kube-training`.
- Kind, `kubectl`, Helm 3 et accès Internet.
- Vous travaillez depuis la racine du dépôt.

## 1. Installer Gateway API et NGINX Gateway Fabric

Suivez le [guide d’installation pour les apprenants](../docs/installation-gateway.md). Il contient les commandes complètes, les versions utilisées et les vérifications à effectuer.

Vérifiez que le contrôleur fonctionne :

```bash
kubectl -n nginx-gateway get pods,svc
kubectl get gatewayclass
```

La GatewayClass `nginx` doit être acceptée avant de continuer.

## 2. Créer la Gateway et la route HTTP

Appliquez les deux manifestes :

```bash
kubectl apply -f manifests/40-gateway.yaml
kubectl apply -f manifests/50-httproute.yaml
kubectl -n kube-training get gateway,httproute
```

Vérifiez les détails :

```bash
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
```

La Gateway définit le point d’entrée HTTP. La HTTPRoute indique vers quel Service envoyer les requêtes.

## 3. Tester depuis le poste

```bash
curl -i -H 'Host: flask.local' http://127.0.0.1/
curl -i -H 'Host: flask.local' http://127.0.0.1/health
curl -i -H 'Host: flask.local' http://127.0.0.1/ready
```

Le test utilise le nom d’hôte `flask.local` dans l’en-tête HTTP. Il n’est pas nécessaire de modifier le fichier hosts.

## 4. Si cela ne fonctionne pas

Vérifiez dans cet ordre :

```bash
kubectl get gatewayclass
kubectl -n nginx-gateway get pods,svc
kubectl -n kube-training get pods,svc,endpoints
kubectl -n kube-training get gateway,httproute
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
```

- Le contrôleur doit être opérationnel.
- Le Service `flask-app` doit avoir des endpoints.
- La Gateway et la HTTPRoute doivent avoir des conditions favorables.
- Le Service de données NGINX doit exposer le NodePort `30080`.
- Le port mapping de Kind doit relier le port 80 du poste au port 30080 du nœud.

Si le test externe échoue, vérifiez d’abord l’application seule :

```bash
kubectl -n kube-training port-forward svc/flask-app 8080:80
curl -i http://localhost:8080/health
```

Arrêtez le `port-forward` avec `Ctrl+C`. Cette vérification permet de distinguer un problème applicatif d’un problème de routage.

## À retenir

- GatewayClass identifie l’implémentation du contrôleur.
- Gateway définit le point d’entrée et son listener.
- HTTPRoute décrit les règles de routage vers un Service.
- Le Service applicatif reste un Service ClusterIP.
- Le montage Kind + NodePort sert au laboratoire ; il ne remplace pas un LoadBalancer de production.

## Questions

1. Quel est le rôle de GatewayClass, Gateway et HTTPRoute ?
2. Où se situe le Service `flask-app` dans le trajet du trafic ?
3. Comment distinguer une panne applicative d’une panne de routage ?
4. Pourquoi ce montage n’est-il pas une exposition de production ?


---

## Pour aller plus loin — TP bonus

Les TP bonus sont facultatifs. Faites-les après les six TP principaux.

- [Bonus — Déployer une application avec Flux](../bonus/fluxcd/README.md)
- [Bonus — Utiliser Vault avec External Secrets Operator](../bonus/vault-eso/README.md)

**Retour au dépôt :** [README principal](../README.md)
