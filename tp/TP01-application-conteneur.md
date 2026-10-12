# TP01 — Application et conteneur Docker

**Objectif :** comprendre et tester l’application qui servira de fil rouge avant son déploiement sur Kubernetes.

## Travail demandé

1. Repérer le point d’entrée, les dépendances et les endpoints.
2. Créer un environnement Python et exécuter les tests.
3. Construire l’image Docker.
4. Lancer le conteneur en définissant `APP_ENV` et `APP_MESSAGE`.
5. Tester `/`, `/health` et `/ready`.
6. Consulter les logs et nettoyer le conteneur.

## Commandes

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt pytest
pytest -q

docker build -t kubernetes-orchestration:training .
docker run --rm -d --name kube-training-test -p 5000:5000 \
  -e APP_ENV=formation \
  -e APP_MESSAGE="Bonjour depuis Docker" \
  kubernetes-orchestration:training

curl -i http://localhost:5000/
curl -i http://localhost:5000/health
curl -i http://localhost:5000/ready
docker logs kube-training-test
docker rm -f kube-training-test
```

Si le port 5000 est déjà utilisé, remplacez le port hôte par `5001:5000` et adaptez les URL.

## Débrief

- Différence entre image, conteneur et processus ?
- Pourquoi l’application écoute-t-elle sur `0.0.0.0` ?
- Pourquoi la configuration et les secrets ne doivent-ils pas être intégrés à l’image ?
- Quelle différence entre les endpoints `/health` et `/ready` ?
