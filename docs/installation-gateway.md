# Guide d’installation — Gateway API dans Kind

Ce guide accompagne le TP06. Suivez les étapes dans l’ordre. Il utilise Kind, Gateway API et NGINX Gateway Fabric. MetalLB n’est pas nécessaire.

## 1. Vérifier le cluster Kind

Depuis la racine du dépôt :

```bash
kubectl get nodes
```

Les trois nœuds doivent être `Ready`. Le fichier `kind/cluster.yaml` relie le port 80 de votre poste au port 30080 du nœud Kind. Si le cluster a été créé sans ce mapping, recréez-le avant de poursuivre. Attention : supprimer un cluster efface les ressources qu’il contient.

```bash
kind delete cluster --name kube-training
kind create cluster --config kind/cluster.yaml --wait 120s
kubectl get nodes -o wide
```

## 2. Installer les ressources Gateway API

Nous utilisons NGINX Gateway Fabric 2.7.2 pour ce laboratoire. Installez les CRD Gateway API standard correspondant à cette version :

```bash
kubectl apply -f "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.7.2"
```

## 3. Installer NGINX Gateway Fabric avec Helm

```bash
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --version 2.7.2 \
  --create-namespace --namespace nginx-gateway \
  --wait --timeout 5m \
  --set nginx.service.type=NodePort \
  --set nginx.service.externalTrafficPolicy=Cluster \
  --set-json 'nginx.service.nodePorts=[{"port":30080,"listenerPort":80}]'
```

Attendez la fin de l’installation, puis vérifiez les Pods et les Services :

```bash
kubectl -n nginx-gateway get pods,svc
kubectl get gatewayclass
kubectl describe gatewayclass nginx
```

Les Pods du contrôleur doivent être opérationnels et la GatewayClass `nginx` doit être acceptée. Repérez le Service de données NGINX et vérifiez qu’il expose le NodePort `30080`.

## 4. Vérifier l’application

Avant de créer la Gateway, l’application doit fonctionner :

```bash
kubectl -n kube-training get pods,svc,endpoints
kubectl -n kube-training rollout status deployment/flask-app
```

Si les Pods ne sont pas prêts, revenez au TP03 et corrigez le problème avant de continuer.

## 5. Vérifier le mapping des ports

Le chemin réseau de ce TP est :

```text
Votre poste : 127.0.0.1:80
        |
        v
Port mapping Kind : port 80 du poste -> port 30080 du nœud
        |
        v
Service de données NGINX : NodePort 30080
        |
        v
Gateway -> HTTPRoute -> Service flask-app:80 -> Pods Flask:5000
```

Le nom du Service de données dépend de la configuration du contrôleur. Pour l’identifier :

```bash
kubectl -n nginx-gateway get svc
kubectl -n kube-training get svc
```

Ne confondez pas le Service du contrôleur avec le Service de données qui reçoit le trafic de la Gateway.

## 6. Si l’installation ne fonctionne pas

Vérifiez les éléments dans cet ordre :

```bash
helm list -n nginx-gateway
kubectl -n nginx-gateway get pods,svc
kubectl get gatewayclass
kubectl -n nginx-gateway logs deployment/ngf
```

Si le nom du Deployment diffère, récupérez son nom avec `kubectl -n nginx-gateway get deployments`, puis relancez la commande `logs`.

Si le NodePort 30080 n’apparaît pas, vérifiez les valeurs du chart installé et la documentation de la version 2.7.2 avant de poursuivre.

## Version et limites du laboratoire

Ce TP utilise les versions épinglées de Gateway API et NGINX Gateway Fabric indiquées ci-dessus. Si vous changez de version, vérifiez la compatibilité des CRD et des valeurs Helm.

Kind et NodePort servent à comprendre le routage HTTP dans un laboratoire. Ce montage n’est pas un LoadBalancer cloud et ne configure ni IP publique, ni TLS de production, ni haute disponibilité.
