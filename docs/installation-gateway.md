# Guide formateur — Gateway API et NGINX Gateway Fabric dans Kind

Ce guide décrit la topologie du TP06. Le parcours pratique utilise Kind, Gateway API et NGINX Gateway Fabric. **MetalLB n’est pas requis** : l’accès depuis l’hôte utilise un NodePort et un port mapping Kind.

## Topologie

```text
curl sur l’hôte
  -> 127.0.0.1:80
  -> port mapping Kind vers le nœud sur 30080
  -> Service de données NGINX (NodePort 30080)
  -> Gateway / HTTPRoute
  -> Service ClusterIP flask-app:80
  -> Pods Flask:5000
```

## 1. Préparer Kind

La configuration `kind/cluster.yaml` mappe le port 80 de l’hôte vers le port 30080 du nœud control-plane. Un cluster créé avant l’ajout du mapping doit être recréé pour le prendre en compte.

```bash
kind delete cluster --name kube-training
kind create cluster --config kind/cluster.yaml --wait 120s
kubectl get nodes -o wide
```

Prévenir les participants avant suppression : cela détruit l’état du laboratoire.

## 2. Installer Gateway API et NGINX Gateway Fabric

Version de laboratoire : NGINX Gateway Fabric **2.7.2**.

```bash
kubectl apply -f "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.7.2"

helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --version 2.7.2 \
  --create-namespace --namespace nginx-gateway \
  --wait --timeout 5m \
  --set nginx.service.type=NodePort \
  --set nginx.service.externalTrafficPolicy=Cluster \
  --set-json 'nginx.service.nodePorts=[{"port":30080,"listenerPort":80}]'
```

Vérifier les valeurs acceptées par le chart si la version est modifiée. Ne pas basculer vers un Service LoadBalancer sans nécessité : le parcours n’installe pas de contrôleur d’adresses IP.

```bash
kubectl -n nginx-gateway get pods,svc
kubectl get gatewayclass
kubectl describe gatewayclass nginx
```

Attendu : contrôleur opérationnel et GatewayClass `nginx` acceptée. Le Service de données doit exposer le NodePort `30080`. Si le chart n’assigne pas ce port comme attendu, inspecter `kubectl -n nginx-gateway get svc -o yaml` et corriger les valeurs du chart avant de poursuivre.

## 3. Déployer l’application

Exécuter TP02 pour créer le Secret de pull GHCR et TP03 pour appliquer les manifests applicatifs :

```bash
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get pods,svc,endpoints
```

## 4. Créer Gateway et HTTPRoute

```bash
kubectl apply -f manifests/40-gateway.yaml
kubectl apply -f manifests/50-httproute.yaml
kubectl -n kube-training get gateway,httproute
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
kubectl -n kube-training get svc
```

Inspecter les Services dans les deux namespaces :

```bash
kubectl -n nginx-gateway get svc
kubectl -n kube-training get svc
```

Le Service de données est créé pour la Gateway. Son nom dépend de la configuration/version ; identifier le Service associé à `flask-gateway` et vérifier ses ports. Ne pas confondre ce Service de données avec le Service du contrôleur `ngf` dans `nginx-gateway`.

## 5. Tester depuis l’hôte

```bash
curl -i -H 'Host: flask.local' http://127.0.0.1/
curl -i -H 'Host: flask.local' http://127.0.0.1/health
curl -i -H 'Host: flask.local' http://127.0.0.1/ready
```

Si l’accès direct ne fonctionne pas, vérifier successivement :
1. le port mapping dans `kind/cluster.yaml` ;
2. le NodePort 30080 du Service de données ;
3. les Pods/logs du contrôleur et les conditions GatewayClass/Gateway/HTTPRoute ;
4. les endpoints du Service `flask-app` ;
5. le host attendu par la règle HTTPRoute.

Diagnostic de secours pour isoler l’application :

```bash
kubectl -n kube-training port-forward svc/flask-app 8080:80
curl -i http://localhost:8080/health
```

## Limites

Kind et NodePort servent à illustrer le chemin du trafic dans un laboratoire. Ce montage n’est pas l’équivalent d’un LoadBalancer managé, d’une IP publique, d’une terminaison TLS de production ou d’une architecture hautement disponible.
