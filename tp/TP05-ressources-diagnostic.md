# TP05 — Ressources, probes et diagnostic

**Objectif :** comprendre pourquoi un Pod est planifié, redémarré ou non prêt.

## Travail demandé

1. Inspecter les `requests` et `limits`.
2. Expliquer `100m`, `500m`, `64Mi` et `128Mi`.
3. Examiner startup, readiness et liveness probes.
4. Diagnostiquer un problème fourni par le formateur.
5. Distinguer `Pending`, `CrashLoopBackOff`, `ImagePullBackOff` et `OOMKilled`.

```bash
kubectl -n kube-training get pods -o wide
kubectl -n kube-training describe pod <nom-du-pod>
kubectl -n kube-training logs <nom-du-pod>
kubectl -n kube-training logs <nom-du-pod> --previous
kubectl -n kube-training get events --sort-by=.metadata.creationTimestamp
kubectl -n kube-training rollout status deployment/flask-app
```

## Débrief

- Différence entre request et limit ?
- Que signifie 1000m CPU ?
- Pourquoi readiness n'est-elle pas un mécanisme de redémarrage ?
