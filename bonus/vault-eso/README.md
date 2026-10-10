# Bonus — Vault comme fournisseur de secrets pour ESO

**Optionnel — hors du socle obligatoire de 14 heures.**

Architecture visée :

```text
HashiCorp Vault
      |
      v
External Secrets Operator (ESO)
      |
      v
Kubernetes Secret
      |
      v
Application Flask
```

**Ce parcours n'utilise pas Vault Agent Injector.** ESO lit le secret depuis Vault et crée/actualise un Secret Kubernetes ; l'application le consomme ensuite via le mécanisme Kubernetes standard.

## Démonstration proposée

1. Expliquer les rôles de Vault, ESO, `SecretStore`/`ClusterSecretStore` et `ExternalSecret`.
2. Installer Vault et ESO uniquement dans un environnement de laboratoire préparé.
3. Configurer une authentification et des permissions minimales pour lire un chemin de test dans Vault.
4. Créer un `SecretStore` puis un `ExternalSecret`.
5. Vérifier que le Secret Kubernetes est créé sans afficher sa valeur.
6. Relier le Secret à la variable `API_KEY` de l'application et vérifier que l'application n'en révèle jamais le contenu.
7. Discuter rotation, RBAC, chiffrement au repos, audit et limites du Secret Kubernetes.

Documentation :
- ESO : https://external-secrets.io/
- Vault : https://developer.hashicorp.com/vault/docs

## Précautions

- Ne pas versionner de token Vault, mot de passe ou secret réel.
- Ne pas présenter base64 comme du chiffrement.
- Préparer versions et configuration du cluster à l'avance : ce bonus dépend de plusieurs composants et ne doit pas mettre en risque le timing du cours principal.
