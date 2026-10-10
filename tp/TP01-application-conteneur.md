# TP01 — Application et conteneur

**Objectif :** comprendre ce que l'on déploiera ensuite sur Kubernetes.

## Travail demandé

1. Repérer le point d'entrée et les dépendances.
2. Créer un environnement Python et lancer les tests.
3. Construire l'image Docker.
4. Lancer le conteneur en configurant `APP_ENV` et `APP_MESSAGE`.
5. Tester `/`, `/health` et `/ready`.
6. Inspecter les logs et arrêter le conteneur proprement.

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt pytest
pytest -q
docker build -t kubernetes-orchestration:training .
docker run --rm -p 5000:5000 -e APP_ENV=formation kubernetes-orchestration:training
```

## Débrief

- Différence entre processus, conteneur et image ?
- Pourquoi l'application écoute-t-elle sur `0.0.0.0` ?
- Quelles informations ne faut-il pas intégrer à l'image ?
