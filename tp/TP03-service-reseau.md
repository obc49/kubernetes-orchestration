# TP03 — Service et accès réseau

**Objectif :** dissocier l'accès à l'application de l'identité d'un Pod.

## Travail demandé

1. Appliquer le Service.
2. Vérifier le selector et les endpoints.
3. Faire un port-forward vers le Service.
4. Expliquer pourquoi l'adresse d'un Pod n'est pas un point d'accès stable.

```bash
kubectl apply -f manifests/30-service.yaml
kubectl -n kube-training get svc,endpoints
kubectl -n kube-training describe svc flask-app
kubectl -n kube-training port-forward svc/flask-app 8080:80
curl -i http://localhost:8080/
```

## Débrief

- Que fait le selector du Service ?
- Rôle des ports `port` et `targetPort` ?
- Quand envisager Ingress ou Gateway API ? (discussion, hors TP de base)
