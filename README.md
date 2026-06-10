# API Web Workshop Organizer

Bienvenue sur l'API Web Workshop Organizer ! Cette application facilite
l'organisation d'ateliers ouverts au public. Qu'il s'agisse de stages de
programmation, de cours d'art ou de tout autre type d'atelier, cette API permet
de gérer les inscriptions, les plannings et les ressources.

## Table des matières

1. Contexte
2. Présentation technique
3. Compilation et exécution
4. Configuration
5. Tests
6. Empaquetage
7. Publication dans GitHub Packages

## Contexte

Les ateliers jouent un rôle essentiel dans l'apprentissage et la collaboration.
Cette application vise à simplifier leur organisation en facilitant la gestion
des participants, des sessions et du matériel. Elle accompagne aussi bien les
organisateurs expérimentés que ceux qui préparent leur premier atelier.

## Présentation technique

- **Java Development Kit (JDK) :** l'application utilise **JDK 21**, testé avec
  **Adoptium**.
- **Base de données :** le backend utilise **PostgreSQL 13** pour le stockage
  des données.
- **Outil de build :** **Gradle 8.7** gère les dépendances et la compilation du
  projet.
- **Spring Boot :** l'application repose sur **Spring Boot 3.2.4** pour créer
  l'API REST.
- **Serveur d'applications :** l'application peut être exécutée sur un serveur
  Tomcat **10.1.24**.

## Compilation et exécution

Pour compiler et exécuter l'application localement :

1. Vérifiez que JDK 21 est installé.
2. Clonez ce dépôt.
3. Placez-vous à la racine du projet.
4. Compilez le code Java :

   ```bash
   ./gradlew clean compileJava
   ```

5. Exécutez l'application localement avec l'une des méthodes suivantes :
   - lancez la méthode principale de la classe `Application` depuis votre IDE ;
   - utilisez le plugin Gradle de Spring Boot :

     ```bash
     ./gradlew bootRun
     ```

Pour la production, générez une archive WAR et déployez-la sur un serveur
Tomcat.

Après avoir construit l'image Docker avec le tag `workshop-organizer`, démarrez
l'application avec :

```bash
docker compose up -d
```

## Étape 3 - Conteneurisation avec PostgreSQL

La stack Docker contient deux services :

1. `app` compile, teste et empaquette l'API avec Gradle, puis exécute le WAR
   avec Eclipse Temurin JRE 21 ;
2. `db` fournit PostgreSQL 13 et conserve ses données dans un volume Docker
   nommé.

### État de validation

L'Étape 3 a été validée localement le 10 juin 2026 :

- build Gradle, génération OpenAPI et packaging WAR réussis ;
- 2 tests unitaires JUnit réussis pendant le build de l'image ;
- PostgreSQL passé à l'état `healthy` avant le démarrage de l'API ;
- conteneur Spring Boot passé à l'état `healthy` ;
- `http://localhost:8080/api/workshops` : HTTP `200` en JSON ;
- persistance confirmée après `docker compose down` puis
  `docker compose up -d` ;
- donnée de contrôle retrouvée après recréation des conteneurs ;
- donnée et table temporaires supprimées après le contrôle ;
- conteneurs et réseau Compose nettoyés sans suppression du volume.

### Fichiers Docker

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Compilation Gradle puis image d'exécution JRE |
| `docker-compose.yml` | Orchestration de l'API et de PostgreSQL |
| `.dockerignore` | Réduction du contexte transmis au démon Docker |
| `.gitattributes` | Fins de ligne compatibles avec Linux et WSL |

### Construction multi-stage

La première étape du `Dockerfile` utilise :

```dockerfile
FROM eclipse-temurin:21-jdk AS build
```

Elle exécute :

```bash
./gradlew clean test bootWar --no-daemon
```

Cette commande :

- nettoie les anciens artefacts ;
- génère les interfaces Java depuis la spécification OpenAPI ;
- compile le projet ;
- exécute les tests JUnit ;
- crée une archive Spring Boot WAR exécutable.

La seconde étape utilise uniquement le JRE :

```dockerfile
FROM eclipse-temurin:21-jre
```

Le JDK, les sources, le cache Gradle et les dépendances de compilation ne sont
pas présents dans l'image finale.

### Variables de connexion PostgreSQL

Spring Boot reçoit les trois variables demandées :

| Variable | Valeur Compose par défaut |
|---|---|
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://db:5432/workshopsdb` |
| `SPRING_DATASOURCE_USERNAME` | `workshops_user` |
| `SPRING_DATASOURCE_PASSWORD` | `oc2024` |

Dans l'URL JDBC, `db` est le nom DNS du service PostgreSQL sur le réseau privé
créé par Compose. Il ne faut pas utiliser `localhost`, qui désignerait le
conteneur Spring Boot lui-même.

Les paramètres PostgreSQL peuvent être surchargés sans modifier le fichier :

```bash
POSTGRES_DB=workshopsdb \
POSTGRES_USER=workshops_user \
POSTGRES_PASSWORD=mot_de_passe_local \
docker compose up -d --build
```

Les valeurs proposées sont destinées uniquement au développement local. Un
secret de production ne doit jamais être écrit dans le dépôt.

### Démarrer la stack

Depuis la racine du backend :

```bash
docker compose up -d --build
```

L'API devient accessible sur :

```text
http://localhost:8080/api/workshops
```

Contrôle rapide :

```bash
curl http://localhost:8080/api/workshops
```

### Healthchecks et ordre de démarrage

PostgreSQL est contrôlé avec :

```bash
pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

Le service `app` dépend de la condition `service_healthy`. Spring Boot n'est
donc démarré qu'après l'acceptation des connexions par PostgreSQL.

L'API possède aussi son propre healthcheck sur l'endpoint métier :

```text
http://127.0.0.1:8080/api/workshops
```

Vérifier les états :

```bash
docker compose ps
docker compose logs app
docker compose logs db
```

Les deux services doivent apparaître avec l'état `healthy`.

### Persistance PostgreSQL

Le volume nommé `postgres_data` est monté dans :

```text
/var/lib/postgresql/data
```

La commande suivante arrête et recrée les conteneurs sans supprimer les
données :

```bash
docker compose down
docker compose up -d
```

Pour supprimer volontairement les données :

```bash
docker compose down --volumes --remove-orphans
```

Cette dernière commande est destructive pour la base locale.

### Arrêter sans supprimer les données

```bash
docker compose down --remove-orphans
```

Le réseau et les conteneurs sont supprimés, mais le volume nommé est conservé.

### Changer le port publié

Si `8080` est occupé :

```bash
BACKEND_PORT=8081 docker compose up -d --build
```

L'API est alors accessible sur
`http://localhost:8081/api/workshops`, tandis que Spring Boot continue
d'écouter sur le port `8080` à l'intérieur du conteneur.

### Dépannage Docker

Afficher les services et leurs healthchecks :

```bash
docker compose ps
docker inspect --format '{{json .State.Health}}' \
  "$(docker compose ps -q app)"
```

Afficher les journaux :

```bash
docker compose logs --tail=200 app
docker compose logs --tail=200 db
```

Vérifier que PostgreSQL répond depuis son conteneur :

```bash
docker compose exec db \
  pg_isready -U workshops_user -d workshopsdb
```

En cas d'ancienne base incompatible, supprimer explicitement le volume local,
puis reconstruire :

```bash
docker compose down --volumes --remove-orphans
docker compose up -d --build
```

## Configuration

L'application peut être configurée avec les variables d'environnement
suivantes :

- `SPRING_DATASOURCE_URL` : URL JDBC d'accès à la base de données, par exemple
  `jdbc:postgresql://db:5432/mydatabase`.
- `SPRING_DATASOURCE_USERNAME` : nom de l'utilisateur de la base de données.
- `SPRING_DATASOURCE_PASSWORD` : mot de passe de l'utilisateur de la base de
  données.

## Tests

Pour vérifier le bon fonctionnement de l'application, exécutez :

```bash
./gradlew clean test
```

Les rapports JUnit sont générés dans le dossier `build/test-results/test`.

## Empaquetage

Pour préparer l'application au déploiement, générez une archive WAR :

```bash
./gradlew bootWar
```

Le fichier WAR généré peut être utilisé avec différents serveurs
d'applications, notamment Tomcat et WildFly.

## Publication dans GitHub Packages

Le dépôt Gradle `GitHubPackages` publie l'archive WAR dans le registre Maven
associé au dépôt GitHub :

```text
https://maven.pkg.github.com/msm-oc-projects/msm-projet-06-backend
```

Dans GitHub Actions, le workflow utilise automatiquement :

- `GITHUB_REPOSITORY` pour identifier le dépôt ;
- `GITHUB_ACTOR` comme utilisateur ;
- `GITHUB_TOKEN` avec la permission `packages: write`.

La publication est exécutée après la création d'une version par
semantic-release.

Pour publier manuellement, utilisez un Personal Access Token autorisé à écrire
dans GitHub Packages :

```bash
export GITHUB_REPOSITORY=msm-oc-projects/msm-projet-06-backend
export GITHUB_ACTOR=votre-utilisateur-github
export GITHUB_TOKEN=votre-token
./gradlew publish
```

Il est également possible de placer les identifiants dans
`~/.gradle/gradle.properties` :

```properties
gpr.user=votre-utilisateur-github
gpr.key=votre-token
```

Puis de publier :

```bash
./gradlew publish
```

Ne versionnez jamais le token.
