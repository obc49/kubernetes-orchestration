# Bonus — GitOps avec FluxCD

**Optionnel — hors du socle obligatoire de 14 heures.**

Objectif : comparer les commandes impératives et une réconciliation déclarative pilotée depuis Git.

## Démonstration proposée

1. Installer Flux sur un cluster de laboratoire en suivant la documentation officielle.
2. Placer une copie des manifests applicatifs dans un dépôt Git ou sous-répertoire isolé.
3. Créer une source Git et une ressource `Kustomization`.
4. Modifier le nombre de réplicas dans Git et observer la réconciliation.
5. Discuter dérive, modèle pull, droits d'accès et séparation des environnements.

Documentation : https://fluxcd.io/flux/

Ne pas installer Flux au début de la formation : ce sujet est une extension si le groupe avance vite.
