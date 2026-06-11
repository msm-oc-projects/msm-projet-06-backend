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

La documentation de l'étape de conteneurisation avec PostgreSQL est centralisée
dans
[`msm-projet-06-ops/docs/etape-1.3-conteneurisation-backend.md`](https://github.com/msm-oc-projects/msm-projet-06-ops/blob/main/docs/etape-1.3-conteneurisation-backend.md).

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
