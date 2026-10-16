# TP06 — Exposer l’application avec Gateway API

## Objectif

Installer le contrôleur NGINX Gateway Fabric, créer une Gateway et une HTTPRoute, puis accéder à l’application avec `curl`, et en option depuis votre navigateur.

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
kubectl -n kube-training wait --for=condition=Programmed gateway/flask-gateway --timeout=120s
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
kubectl -n kube-training get svc flask-gateway-nginx
```

La Gateway définit le point d’entrée HTTP. La HTTPRoute indique vers quel Service envoyer les requêtes. Le contrôleur crée le Service de données `flask-gateway-nginx` dans le namespace `kube-training` lorsque la Gateway est prise en charge.

## 3. Tester depuis le poste

Ouvrez deux terminaux.

**Terminal 1 :** lancez le `port-forward` vers le Service de données NGINX et laissez-le actif.

```bash
kubectl -n kube-training port-forward svc/flask-gateway-nginx 8080:80
```

Si le port 8080 est déjà utilisé sur votre poste, remplacez-le par 8081 ou un autre port libre. Seul le port local change.

**Terminal 2 :** testez les trois endpoints :

```bash
curl -i -H 'Host: flask.local' http://127.0.0.1:8080/
curl -i -H 'Host: flask.local' http://127.0.0.1:8080/health
curl -i -H 'Host: flask.local' http://127.0.0.1:8080/ready
```

La HTTPRoute ne répond que pour le nom d’hôte `flask.local`. Vérifiez le cas négatif :

```bash
curl -i http://127.0.0.1:8080/
```

Sans l’en-tête `Host: flask.local`, la requête ne correspond pas à la route et doit retourner `404`. Avec `curl`, il n’est pas nécessaire de modifier le fichier hosts : l’en-tête `Host` suffit.

Facultatif, pour tester depuis un navigateur : ajoutez la ligne suivante dans le fichier hosts (`/etc/hosts` sous Linux/WSL, ou `C:\Windows\System32\drivers\etc\hosts` sous Windows) :

```text
127.0.0.1 flask.local
```

Puis ouvrez `http://flask.local:8080/`. Sans cette ligne, le navigateur ne peut pas envoyer le nom d’hôte attendu par la HTTPRoute.

## 4. Si cela ne fonctionne pas

Vérifiez dans cet ordre :

```bash
kubectl get gatewayclass
kubectl -n nginx-gateway get pods,svc
kubectl -n kube-training get pods,svc,endpoints
kubectl -n kube-training get svc flask-gateway-nginx
kubectl -n kube-training get gateway,httproute
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
```

- Le contrôleur doit être opérationnel.
- Le Service `flask-app` doit avoir des endpoints.
- La Gateway et la HTTPRoute doivent avoir des conditions favorables.
- Le Service `flask-gateway-nginx` doit exister dans le namespace `kube-training`.
- Le `port-forward` doit être actif dans le premier terminal.

Si le test externe échoue, vérifiez d’abord l’application seule. Arrêtez le `port-forward` du premier terminal avec `Ctrl+C`, ou utilisez un autre port local, par exemple 8081.

```bash
kubectl -n kube-training port-forward svc/flask-app 8081:80
curl -i http://localhost:8081/health
```

Arrêtez le `port-forward` avec `Ctrl+C`. Cette vérification permet de distinguer un problème applicatif d’un problème de routage.

## À retenir

- GatewayClass identifie l’implémentation du contrôleur.
- Gateway définit le point d’entrée et son listener.
- HTTPRoute décrit les règles de routage vers un Service.
- Le Service applicatif reste un Service ClusterIP.
- Le Service de données est de type NodePort, ce qui serait le point d’entrée sur un vrai cluster ; en laboratoire nous l’atteignons par `port-forward` pour ne dépendre d’aucun port fixe du poste.

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
