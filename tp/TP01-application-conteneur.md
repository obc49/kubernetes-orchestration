# TP01 — De l’application à l’image publiée

Ce TP se fait entièrement sur votre poste, avec Docker. Le cluster Kubernetes est créé au TP02.

## Objectif

À la fin de ce TP, vous saurez lancer l’application Flask, la conteneuriser, construire une image Docker et la publier dans GHCR, le registre d’images de GitHub. Cette image sera utilisée dans les TP Kubernetes.

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
pip install -r app/requirements.txt 'pytest>=7'
pytest -q
```

Résultat attendu : les tests passent. Si la commande n’est pas trouvée, utilisez `python -m pytest -q`.

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

Le conteneur démarre en arrière-plan : la commande rend la main avant que
l’application écoute. Attendez qu’elle réponde avant de la tester :

```bash
curl --retry 15 --retry-delay 1 --retry-connrefused -fsS http://localhost:5000/health
```

`--retry 15` et `--retry-delay 1` autorisent quinze tentatives espacées d’une
seconde ; `--retry-connrefused` demande de réessayer aussi quand rien n’écoute
encore. Pendant l’attente, des lignes `Couldn’t connect to server` peuvent
s’afficher : c’est normal. Vous devez voir apparaître `{"status":"ok"}`.

Si rien ne vient au bout de quinze secondes, l’application n’a pas démarré.
Regardez pourquoi avant de poursuivre :

```bash
docker logs flask-tp01
```

Testez les trois routes :

```bash
curl -i http://localhost:5000/
curl -i http://localhost:5000/health
curl -i http://localhost:5000/ready
docker logs flask-tp01
docker rm -f flask-tp01
```

Les routes `/health` et `/ready` ne servent pas à l'utilisateur : elles servent à Kubernetes. Vous verrez au TP03 comment le cluster s'en sert pour savoir si l'application fonctionne et si elle peut recevoir du trafic.

Si le port 5000 est déjà utilisé, remplacez `5000:5000` par `5001:5000` et utilisez le port 5001 dans les URL.

## 3. Préparer l’accès à GHCR

GHCR est le registre d’images de GitHub. Pour publier votre propre image, utilisez un compte GitHub autorisé à publier un package. Vous publierez dans votre propre espace GHCR, celui de votre fork.

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
export OWNER="$GHCR_USER"
export IMAGE="ghcr.io/$OWNER/kubernetes-orchestration"
export TAG="tp01-1"
```

Construisez, taguez et publiez l’image :

```bash
docker build -t "$IMAGE:$TAG" .
docker push "$IMAGE:$TAG"
```

Vérifiez que la publication est terminée dans GitHub → Packages. Ouvrez **Package settings** et vérifiez que la visibilité du package est **Private**. Si nécessaire, changez-la avant de poursuivre. Le TP03 s’appuie sur un package privé pour vous faire observer le problème de téléchargement puis le corriger.

Notez l’adresse exacte de votre image, par exemple `ghcr.io/VOTRE-IDENTIFIANT/kubernetes-orchestration:tp01-1`. Vous en aurez besoin au TP03.

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


---

**Suite :** [TP02 — Premiers pas dans Kubernetes](TP02-premiers-pas-kubernetes.md)
