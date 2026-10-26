# Projet intégrateur — une base de données et ses traitements

Ce projet est **facultatif** et se fait **après la formation**, à votre rythme. Il ne remplace aucun des six TP : il les rassemble.

Vous allez déployer une petite base PostgreSQL qui conserve ses données, l’initialiser avec un `Job`, puis la rafraîchir périodiquement avec un `CronJob`. C’est la charpente d’une plateforme de données : un entrepôt qui garde son état, et des traitements qui s’exécutent puis se terminent.

Comptez une à deux heures. Il n’y a pas de correction à rendre.

## Ce que vous réutilisez

| Venu de | Vous le réemployez pour |
|---|---|
| TP02 | Namespace, Service, labels et selectors |
| TP03 | Deployment, sondes, `securityContext` |
| TP04 | Secret, ConfigMap, requests et limits, PVC |
| TP05 | `describe`, `logs`, `events` quand quelque chose coince |

Et deux objets nouveaux, présentés en cours mais jamais pratiqués : le `Job` et le `CronJob`.

## Prérequis

- Le cluster Kind de la formation, ou un cluster neuf créé avec `kind create cluster --config kind/cluster.yaml --wait 120s`.
- `kubectl` qui répond.
- Aucune image privée : tout vient d’images publiques, vous n’avez pas besoin de votre token GHCR.

## Étape 1 — Le namespace et le mot de passe

Travaillez à l’écart des TP, dans un namespace dédié :

```bash
kubectl create namespace projet
```

Le mot de passe de la base va dans un Secret, jamais dans un manifeste commité.

```bash
kubectl -n projet create secret generic postgres-auth \
  --from-literal=POSTGRES_PASSWORD='motdepasse-de-lab' \
  --dry-run=client -o yaml | kubectl apply -f -
```

`motdepasse-de-lab` est une valeur fictive, à conserver telle quelle : n’y mettez aucun mot de passe réel. Un Secret Kubernetes n’est pas un coffre-fort — il est encodé en base64, pas chiffré, comme vu au TP04 — et ce cluster est un lab.

Cette forme est celle du TP03 : elle crée le Secret ou le met à jour, vous pouvez donc la relancer.

## Étape 2 — Le volume et la base

Créez le fichier `/tmp/projet-postgres.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: projet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: projet
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: postgres
  ports:
    - name: postgres
      port: 5432
      targetPort: postgres
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: projet
  labels:
    app.kubernetes.io/name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: postgres
  template:
    metadata:
      labels:
        app.kubernetes.io/name: postgres
    spec:
      securityContext:
        fsGroup: 999
      containers:
        - name: postgres
          image: postgres:18
          ports:
            - name: postgres
              containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: formation
            - name: POSTGRES_USER
              value: formation
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-auth
                  key: POSTGRES_PASSWORD
          volumeMounts:
            - name: donnees
              mountPath: /var/lib/postgresql
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 1000m
              memory: 1Gi
          startupProbe:
            exec:
              command: ["pg_isready", "-U", "formation", "-d", "formation"]
            periodSeconds: 5
            failureThreshold: 30
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "formation", "-d", "formation"]
            periodSeconds: 5
          livenessProbe:
            exec:
              command: ["pg_isready", "-U", "formation", "-d", "formation"]
            periodSeconds: 20
            failureThreshold: 3
      volumes:
        - name: donnees
          persistentVolumeClaim:
            claimName: postgres-data
```

Quatre points à retenir avant d’appliquer :

- **`replicas: 1`.** Deux serveurs PostgreSQL écrivant dans le même répertoire corrompraient la base. Accessoirement, `ReadWriteOnce` limite le montage à un seul **nœud** — pas à un seul Pod : deux répliques du même nœud monteraient le volume, celle placée sur l’autre nœud resterait bloquée.
- **Un `Deployment` pour une base, c’est un choix de TP.** Il rend la démonstration du PVC lisible, rien de plus. En production, un `StatefulSet` donne à chaque réplique son nom et son volume, et un opérateur ajoute la bascule et les sauvegardes.
- **`fsGroup: 999`**, au niveau du Pod et non du conteneur : c’est là que Kubernetes le lit pour ajuster les droits du volume. L’image Debian fait tourner PostgreSQL sous l’UID 999 ; en variante Alpine, c’est 70.
- **`mountPath: /var/lib/postgresql`**, et non `/var/lib/postgresql/data`. Depuis PostgreSQL 18, l’image a déplacé son volume d’un cran. Le chemin des tutoriels vise les versions 17 et antérieures.

Les trois sondes se répartissent le travail. La `startupProbe` couvre le démarrage : tant qu’elle n’a pas réussi, aucune autre sonde ne s’exécute, ce qui laisse à la base jusqu’à deux minutes et demie pour s’ouvrir sans risquer un redémarrage. La `readinessProbe` décide ensuite si le Service envoie du trafic. La `livenessProbe`, enfin, ne redémarre le conteneur qu’après trois échecs consécutifs.

Appliquez, puis observez le PVC avant que le Pod ne démarre :

```bash
kubectl apply -f /tmp/projet-postgres.yaml
kubectl -n projet get pvc
```

Le PVC peut apparaître en `Pending`. Ce n’est pas une panne : la StorageClass `standard` de Kind attend le premier consommateur avant de provisionner le volume. Il passe en `Bound` dès que le Pod est placé.

```bash
kubectl -n projet rollout status deployment/postgres
kubectl -n projet get pvc,pods
```

Si le Pod reste en `CrashLoopBackOff`, reprenez la méthode du TP05 : `describe pod`, puis `logs`.

## Étape 3 — Un Job qui initialise la base

Un `Job` exécute une tâche, la mène à son terme, et s’arrête. C’est le modèle d’un chargement de données, d’une migration de schéma ou d’une transformation.

Créez `/tmp/projet-init.yaml` :

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: init-schema
  namespace: projet
spec:
  backoffLimit: 3
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: psql
          image: postgres:18
          env:
            - name: PGHOST
              value: postgres
            - name: PGUSER
              value: formation
            - name: PGDATABASE
              value: formation
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-auth
                  key: POSTGRES_PASSWORD
          command:
            - psql
            - -v
            - ON_ERROR_STOP=1
            - -c
            - |
              CREATE TABLE IF NOT EXISTS mesures (
                id serial PRIMARY KEY,
                source text NOT NULL,
                valeur integer NOT NULL,
                vu_le timestamptz NOT NULL DEFAULT now()
              );
              INSERT INTO mesures (source, valeur)
              VALUES ('capteur-a', 12), ('capteur-b', 37), ('capteur-a', 21);
```

Appliquez et suivez :

```bash
kubectl apply -f /tmp/projet-init.yaml
kubectl -n projet wait --for=condition=complete job/init-schema --timeout=120s
kubectl -n projet get job init-schema
kubectl -n projet logs job/init-schema
```

Observez la différence avec un Deployment : le Pod du Job passe en `Completed` et n’est pas remplacé. `kubectl get pods` le montre toujours, terminé, jusqu’à ce que vous supprimiez le Job.

Un Job porte un nom unique. Pour le relancer, supprimez-le d’abord :

```bash
kubectl -n projet delete job init-schema
```

Attention à ce que vous relanceriez : `CREATE TABLE IF NOT EXISTS` ne fait rien la seconde fois, mais l’`INSERT` ajoute de nouveau les trois mesures. **Un Job n’est pas idempotent par nature** — c’est au traitement de l’être. Relancez-le si vous voulez le constater : les moyennes de l’étape suivante changeront.

## Étape 4 — Un CronJob qui rafraîchit

Un `CronJob` crée un `Job` à heure dite. C’est le modèle d’une synchronisation périodique ou d’un rafraîchissement d’agrégats.

Créez `/tmp/projet-cron.yaml` :

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: agregat
  namespace: projet
spec:
  schedule: "*/2 * * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: psql
              image: postgres:18
              env:
                - name: PGHOST
                  value: postgres
                - name: PGUSER
                  value: formation
                - name: PGDATABASE
                  value: formation
                - name: PGPASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: postgres-auth
                      key: POSTGRES_PASSWORD
              command:
                - psql
                - -v
                - ON_ERROR_STOP=1
                - -c
                - |
                  SELECT source, count(*) AS n, avg(valeur)::numeric(10,2) AS moyenne
                  FROM mesures GROUP BY source ORDER BY source;
```

Appliquez, puis attendez le premier déclenchement :

```bash
kubectl apply -f /tmp/projet-cron.yaml
kubectl -n projet get cronjob agregat
```

La colonne `SCHEDULE` affiche `*/2 * * * *` et `LAST SCHEDULE` reste vide tant que rien ne s’est déclenché. Deux minutes plus tard :

```bash
kubectl -n projet get jobs
kubectl -n projet get pods
```

Attendez que la colonne `COMPLETIONS` du Job affiche `1/1`. Relevez alors le nom de son Pod, en état `Completed`, et lisez son résultat :

```bash
kubectl -n projet logs <nom-du-pod>
```

Vous devez voir le tableau des moyennes par source.

Pour déclencher immédiatement sans attendre l’échéance :

```bash
kubectl -n projet create job essai-manuel --from=cronjob/agregat
kubectl -n projet wait --for=condition=complete job/essai-manuel --timeout=120s
kubectl -n projet logs job/essai-manuel
```

Sans l’attente, la lecture des logs arriverait avant que le Pod ait eu le temps de s’exécuter.

## Étape 5 — Vérifier que les données survivent

C’est le but de tout l’exercice. Supprimez le Pod de la base et constatez que les mesures sont toujours là.

```bash
kubectl -n projet get pods -l app.kubernetes.io/name=postgres
```

Relevez le nom du Pod, puis :

```bash
kubectl -n projet delete pod <nom-du-pod>
kubectl -n projet rollout status deployment/postgres
kubectl -n projet create job verification --from=cronjob/agregat
kubectl -n projet wait --for=condition=complete job/verification --timeout=120s
kubectl -n projet logs job/verification
```

Les moyennes sont identiques à celles de l’étape 4 : le Pod a été recréé, le volume lui a été rattaché, et les données n’ont pas bougé. Comparez avec la partie E du TP04, où le fichier posé dans un `emptyDir` disparaissait avec son Pod.

## Nettoyage

Avant de supprimer quoi que ce soit, regardez la chaîne qui relie votre PVC au volume réel :

```bash
kubectl get storageclass
kubectl -n projet get pvc
kubectl get pv
```

La StorageClass `standard` de Kind affiche `RECLAIMPOLICY: Delete`. Le volume réellement créé pour répondre à votre PVC est un **PersistentVolume**, un PV : il en hérite, et sa colonne `RECLAIM POLICY` l’affiche aussi.

La suite se déroule en trois temps, qu’il faut distinguer :

1. Supprimer le **namespace** emporte tout ce qu’il contient : Deployment, Service, Jobs, CronJob, Secret — et le PVC.
2. La disparition du **PVC** libère le **PV** auquel il était lié.
3. Ce qu’il advient du PV dépend alors de sa **politique de récupération**. Avec `Delete`, le PV et les données sont effacés. Avec `Retain`, le PV survivrait et les données avec lui, à charge pour un administrateur de les reprendre.

Sur ce cluster, la politique est `Delete` : **la commande ci-dessous détruit les données du lab.**

```bash
kubectl delete namespace projet
kubectl get pv
```

La seconde commande confirme la disparition du volume. Sur un autre cluster, vérifiez la politique de la StorageClass avant de conclure : rien ne garantit qu’elle soit réglée de la même façon.

## Pour aller plus loin

Dans l’ordre où cela vous servira :

1. **Remplacez le Deployment par un `StatefulSet`.** Vous y gagnez un nom de Pod stable et un volume créé automatiquement par réplique, via `volumeClaimTemplates`. C’est la forme sous laquelle les bases se déploient réellement.
2. **Installez la même base par un chart Helm** plutôt qu’avec vos manifestes, et comparez. C’est ainsi que se livrent la plupart des composants d’une plateforme de données.
3. **Remplacez le `psql` du CronJob par votre propre traitement**, dans votre propre image. Le squelette ne change pas.
4. **Donnez au CronJob un compte de service dédié** et les seuls droits dont il a besoin, comme au TP05.

## Liens utiles

Documentation officielle des objets rencontrés dans ce projet.

| Sujet | Lien |
|---|---|
| Volumes et PersistentVolumeClaim | [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) · [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) |
| Deployment, Job, CronJob, StatefulSet | [Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/) |
| StatefulSet en détail | [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) |
| Sondes readiness et liveness | [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| Secret, ressources, securityContext | [Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/) |
| Cluster local | [Kind](https://kind.sigs.k8s.io/) |

Une seule image est utilisée ici, `postgres:18`, pour la base comme pour les traitements. Ses variantes et ses variables d’environnement sont décrites dans le [dépôt officiel de l’image](https://github.com/docker-library/postgres).

---

**Retour :** [README principal](../../README.md) · [Index des TP](../../tp/README.md)
