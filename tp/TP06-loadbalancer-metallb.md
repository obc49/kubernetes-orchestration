# TP06 — LoadBalancer local avec MetalLB

**Objectif :** simuler une adresse de type LoadBalancer dans Kind, tester l’accès HTTP final et consolider les diagnostics.

## Prérequis

- TP05 terminé ; NGINX Gateway Fabric et la Gateway sont installés.
- La configuration Kind contient le mapping du port hôte 80 vers le NodePort 30080.
- Lire le guide [installation Gateway API et MetalLB](../docs/installation-gateway-metallb.md) et vérifier la plage IP du réseau Docker/Kind.

## Travail demandé

1. Installer MetalLB avec la version fixée dans le guide.
2. Appliquer `manifests/60-metallb-config.yaml` après avoir vérifié que la plage d’adresses ne chevauche pas d’autres équipements.
3. Vérifier que les Pods MetalLB sont opérationnels et que le Service de données NGINX reçoit une adresse externe.
4. Tester les endpoints de l’application depuis l’hôte.
5. Supprimer un Pod applicatif, observer son remplacement et attendre le retour à l’état Ready.
6. Expliquer les limites de cette simulation locale.

## Commandes de contrôle

```bash
kubectl -n metallb-system get pods
kubectl apply -f manifests/60-metallb-config.yaml
kubectl -n nginx-gateway get svc
kubectl -n kube-training get gateway,httproute,pods,svc,endpoints
kubectl -n kube-training rollout status deployment/flask-app
```

Si le nom DNS local du guide est disponible, tester `http://flask.127.0.0.1.nip.io/`, puis `/health` et `/ready`. Si le test échoue, utiliser la checklist du guide et revenir temporairement au port-forward pour isoler la couche défaillante.

## Restitution finale

Démontrer :
- deux Pods applicatifs Ready ;
- un Service avec endpoints ;
- une Gateway programmée et une HTTPRoute acceptée ;
- une adresse LoadBalancer attribuée par MetalLB ;
- les réponses HTTP attendues ;
- une panne observée et diagnostiquée ;
- aucune clé réelle dans Git.

## Débrief

- Que fournit MetalLB dans un cluster local ?
- Pourquoi une IP LoadBalancer du réseau Docker n’est-elle pas forcément directement routable depuis l’hôte ?
- Quelles différences avec un LoadBalancer managé dans un cloud ?
- Quelles protections faudrait-il ajouter avant la production ?
