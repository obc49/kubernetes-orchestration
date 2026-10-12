# Guide formateur — Gateway API et MetalLB dans Kind

Ce guide décrit les versions et la topologie retenues pour le laboratoire. Le parcours a été validé dans l’environnement formateur Windows + WSL2 ; les étapes d’accès depuis d’autres OS doivent être vérifiées sur les postes utilisés en session.

## Topologie

```text
Navigateur / curl sur l’hôte
  -> 127.0.0.1:80
  -> port mapping Kind (port du nœud 30080)
  -> Service de données NGINX Gateway Fabric (NodePort 30080)
  -> Gateway / HTTPRoute
  -> Service ClusterIP flask-app:80
  -> Pods Flask:5000
```

MetalLB attribue aussi une IP LoadBalancer au Service NGINX dans le réseau Docker/Kind. Cette IP est utile pour illustrer le type LoadBalancer, mais elle n’est pas nécessairement directement routable depuis l’hôte ; le test local passe par le port mapping et le NodePort.

## 1. Préparer Kind

La configuration `kind/cluster.yaml` mappe le port 80 de l’hôte vers le port 30080 du nœud control-plane. Si le cluster a été créé avant cette modification, il faut généralement le recréer pour prendre en compte le port mapping.

```bash
kind delete cluster --name kube-training
kind create cluster --config kind/cluster.yaml --wait 120s
kubectl get nodes -o wide
```

Ne supprimer le cluster qu’après avoir prévenu les participants : cela détruit l’état du laboratoire.

## 2. Installer Gateway API et NGINX Gateway Fabric

Versions du laboratoire : NGINX Gateway Fabric **2.7.2**, Gateway API standard CRDs distribuées avec cette version.

```bash
kubectl apply -f "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.7.2"

helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --version 2.7.2 \
  --create-namespace --namespace nginx-gateway \
  --wait --timeout 5m \
  --set nginx.service.type=LoadBalancer \
  --set nginx.service.externalTrafficPolicy=Cluster \
  --set-json 'nginx.service.nodePorts=[{"port":30080,"listenerPort":80}]'
```

Contrôler :

```bash
kubectl -n nginx-gateway get pods,svc
kubectl get gatewayclass
kubectl describe gatewayclass nginx
```

Attendu : contrôleur opérationnel et GatewayClass `nginx` acceptée. Le Service de données doit publier le NodePort `30080`.

## 3. Déployer l’application

Exécuter TP03 pour créer le Secret de pull GHCR, puis TP04 pour appliquer les manifests applicatifs. Avant de poursuivre :

```bash
kubectl -n kube-training rollout status deployment/flask-app
kubectl -n kube-training get pods,svc,endpoints
```

## 4. Créer Gateway et HTTPRoute (TP05)

```bash
kubectl apply -f manifests/40-gateway.yaml
kubectl apply -f manifests/50-httproute.yaml
kubectl -n kube-training get gateway,httproute
kubectl -n kube-training describe gateway flask-gateway
kubectl -n kube-training describe httproute flask-route
```

Après avoir créé la Gateway et l’HTTPRoute, le Service de données est créé dans le namespace de la Gateway (`kube-training`). Dans l’environnement de formation, son nom est `flask-gateway-nginx`. Vérifier son nom et ses ports avant le port-forward :

```bash
kubectl -n kube-training get svc
```

Dans un terminal dédié, transférer le port vers le Service de données associé à la Gateway :

```bash
kubectl -n kube-training port-forward svc/flask-gateway-nginx 8080:80
```

Puis dans un autre terminal :

```bash
curl -i -H 'Host: flask.local' http://localhost:8080/
curl -i -H 'Host: flask.local' http://localhost:8080/health
curl -i -H 'Host: flask.local' http://localhost:8080/ready
```

Si le nom du Service diffère dans la version installée, utiliser le Service de données NGINX créé pour `flask-gateway`, pas le Service du contrôleur. Si l’implémentation de Gateway ne requiert pas de Host particulier, le header peut être omis.

## 5. Installer MetalLB (TP06)

Version retenue : MetalLB **0.16.1**.

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml
kubectl -n metallb-system get pods
```

Attendre que le controller et les speakers soient opérationnels.

### Vérifier le réseau avant d’appliquer le pool

Le pool dans `manifests/60-metallb-config.yaml` utilise `172.20.255.200-172.20.255.250`, retenu pour le laboratoire formateur. Vérifier que le réseau Docker Kind utilise bien une plage qui contient cette adresse et qu’aucun équipement ne l’utilise. Si le sous-réseau est différent ou si la plage chevauche des adresses existantes, modifier le pool avant application.

```bash
docker network inspect kind
kubectl apply -f manifests/60-metallb-config.yaml
kubectl -n nginx-gateway get svc
```

Attendu : le Service NGINX de type LoadBalancer reçoit une IP externe du pool. Ne pas confondre cette adresse dans le réseau Docker avec une adresse forcément routable depuis le système hôte.

## 6. Tester depuis l’hôte

Sur l’environnement formateur Windows + WSL2, le mapping Kind permet de tester :

```bash
curl -i http://flask.127.0.0.1.nip.io/
curl -i http://flask.127.0.0.1.nip.io/health
curl -i http://flask.127.0.0.1.nip.io/ready
```

Le nom nip.io résout ici vers 127.0.0.1 et le trafic entre par le port 80 de l’hôte. Si le port 80 est occupé, arrêter le service qui l’utilise ou ajuster explicitement le mapping et les URL pour le laboratoire.

## 7. Checklist de diagnostic

1. `kubectl -n kube-training get pods` : deux Pods applicatifs Ready.
2. `kubectl -n kube-training get endpoints flask-app` : endpoints présents.
3. `kubectl get gatewayclass` : classe `nginx` acceptée.
4. `kubectl -n kube-training get gateway,httproute` : conditions acceptées/programmed.
5. `kubectl -n nginx-gateway get svc` : type LoadBalancer et NodePort 30080.
6. `kubectl -n metallb-system get pods` : controller et speakers opérationnels.
7. `kubectl get events -A --sort-by=.metadata.creationTimestamp` : événements récents.
8. Consulter les logs du contrôleur NGINX Gateway Fabric.
9. Isoler le backend avec `kubectl -n kube-training port-forward svc/flask-app 8080:80`.

## Limites

Ce laboratoire simule un chemin réseau de développement. Il ne représente pas une architecture de production, ne fournit pas de haute disponibilité de load balancer équivalente à un cloud managé et ne garantit pas que l’IP MetalLB soit directement joignable depuis tous les OS.
