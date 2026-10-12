# TP02 — Publier et identifier une image privée sur GHCR

**Objectif :** comprendre le cycle de publication d’une image et identifier une version précise à déployer.

## Travail demandé

1. Ouvrir l’onglet Actions du dépôt et vérifier le workflow de publication.
2. Identifier le package `ghcr.io/oboyo-training/kubernetes-orchestration` et vérifier sa visibilité.
3. Repérer le tag SHA créé par le workflow et noter le tag de formation communiqué par le formateur.
4. Expliquer pourquoi un tag SHA est plus reproductible que `latest`.
5. Si demandé par le formateur, construire et publier une image depuis un poste autorisé.

## Vérifications

- Workflow vert sur un push vers `main`.
- Package visible dans GitHub Packages avec la visibilité attendue (privée pour ce cours).
- Image disponible sous un tag précis.
- Aucun token ni fichier de credentials dans Git.

## Publication manuelle facultative

N’exécuter ces commandes que si le formateur autorise une publication depuis votre poste. Utiliser un token personnel limité aux droits nécessaires (`write:packages`, et les droits de lecture nécessaires) ; ne jamais écrire sa valeur en clair dans une commande versionnée.

```bash
export GHCR_USER="votre-identifiant-github"
read -s -p "Token GHCR : " GHCR_TOKEN
echo
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
unset GHCR_TOKEN

docker build -t ghcr.io/oboyo-training/kubernetes-orchestration:formation .
# Le push est réservé aux personnes autorisées :
# docker push ghcr.io/oboyo-training/kubernetes-orchestration:formation
docker logout ghcr.io
```

Le workflow publie les tags à partir de `main`. Un push depuis une branche de TP ne publie pas automatiquement l’image.

## Débrief

- À quoi sert un registre d’images ?
- Différence entre tag mutable et tag SHA ?
- Pourquoi le package GHCR doit-il être privé pour l’exercice suivant ?
- Pourquoi ne faut-il jamais publier un token dans Git ou dans les logs ?
