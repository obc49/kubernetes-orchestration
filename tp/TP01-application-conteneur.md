# TP01 — De l’application à l’image publiée

## Objectif

À la fin de ce TP, vous saurez lancer l’application Flask, la conteneuriser, construire une image Docker et la publier dans votre registre GHCR. Cette image sera utilisée dans les TP Kubernetes.

## 1. Découvrir l’application

Depuis la racine du dépôt :

```bash
ls
ls app
```

Repérez le fichier `app/app.py`, les dépendances et les tests.

Créez un environnement Python et lancez les tests :

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt pytest
pytest -q
```

Résultat attendu : les tests passent.

## 2. Construire et tester l’image en local

Construisez l’image :

```bash
docker build -t kubernetes-orchestration:tp01 .
docker images kubernetes-orchestration
```

Lancez le conteneur :

```bash
docker run --rm -d --name flask-tp01 -p 5000:5000 \
  -e APP_ENV=formation \
  -e APP_MESSAGE="Bonjour depuis Docker" \
  kubernetes-orchestration:tp01
```

Testez les trois endpoints :

```bash
curl -i http://localhost:5000/
curl -i http://localhost:5000/health
curl -i http://localhost:5000/ready
docker logs flask-tp01
docker rm -f flask-tp01
```

Si le port 5000 est déjà utilisé, remplacez `5000:5000` par `5001:5000` et utilisez le port 5001 dans les URL.

## 3. Préparer l’accès à GHCR

GHCR est le registre d’images de GitHub. Pour publier votre propre image, utilisez un compte GitHub autorisé à publier un package. Si vous travaillez à partir d’un fork, remplacez `OWNER` par votre identifiant GitHub.

Créez un token avec le droit minimal nécessaire pour publier des packages (`write:packages`). Ne réutilisez pas un token professionnel et ne l’ajoutez jamais au dépôt.

Connectez Docker à GHCR. La saisie du token reste masquée :

```bash
read -p "Identifiant GitHub : " GHCR_USER
read -s -p "Token GHCR : " GHCR_TOKEN
echo
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
unset GHCR_TOKEN
```

Si la connexion échoue, vérifiez les droits du token et l’accès au package.

## 4. Construire et publier votre image

Choisissez un tag unique pour votre image :

```bash
export OWNER="votre-identifiant-github"
export IMAGE="ghcr.io/$OWNER/kubernetes-orchestration"
export TAG="tp01-1"
```

Remplacez `votre-identifiant-github` par votre identifiant GitHub. Construisez, taguez et publiez l’image :

```bash
docker build -t "$IMAGE:$TAG" .
docker push "$IMAGE:$TAG"
```

Vérifiez que la publication est terminée dans GitHub → Packages. Si le package est privé, gardez-le privé : les TP suivants vous apprendront à autoriser Kubernetes à le télécharger.

Notez l’adresse exacte de votre image, par exemple `ghcr.io/mon-compte/kubernetes-orchestration:tp01-1`. Vous en aurez besoin au TP03.

## 5. Nettoyer le poste

```bash
docker logout ghcr.io
unset OWNER IMAGE TAG GHCR_USER
```

Ne supprimez pas l’image publiée : elle sera utilisée dans les TP suivants.

## À retenir

- Une image est le paquet qui contient l’application et ce dont elle a besoin pour démarrer.
- Un conteneur est une instance lancée à partir d’une image.
- GHCR stocke et distribue les images.
- Un tag permet de désigner une version de l’image.
- Un registre privé exige une authentification pour télécharger l’image.

## Questions

1. Quelle différence entre image et conteneur ?
2. À quoi servent `/health` et `/ready` ?
3. Quelle est l’adresse complète de l’image que vous venez de publier ?
4. Pourquoi ne faut-il jamais mettre le token dans le Dockerfile ou dans Git ?
