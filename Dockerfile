# Étape de construction : le JDK est nécessaire pour compiler, tester et
# empaqueter l'application. Il ne sera pas conservé dans l'image finale.
FROM eclipse-temurin:21-jdk AS build

# Répertoire de travail isolé pour les sources et les artefacts Gradle.
WORKDIR /workspace

# Les fichiers de configuration Gradle sont copiés avant les sources afin de
# mieux exploiter le cache Docker lorsque seul le code applicatif change.
COPY gradlew gradlew.bat settings.gradle build.gradle system.properties ./
COPY gradle ./gradle

# Le droit d'exécution est imposé dans l'image Linux, indépendamment des droits
# du fichier dans le poste Windows ou dans Git.
RUN chmod +x ./gradlew

# `.dockerignore` exclut les builds locaux, caches IDE et métadonnées Git.
COPY src ./src

# La construction vérifie également la suite JUnit avant de produire l'archive
# Spring Boot WAR exécutable. Une image ne peut donc pas être créée si les tests
# ou la compilation échouent.
RUN ./gradlew clean test bootWar --no-daemon

# Étape d'exécution : le JRE suffit pour lancer l'archive déjà compilée. Cette
# image est plus petite et expose moins d'outils qu'une image contenant le JDK.
FROM eclipse-temurin:21-jre

WORKDIR /app

# curl est utilisé uniquement par le healthcheck Docker de l'API. Le nettoyage
# des index APT limite la taille ajoutée à l'image finale.
RUN apt-get update \
    && apt-get install --no-install-recommends -y curl \
    && rm -rf /var/lib/apt/lists/*

# Le glob correspond à l'unique WAR généré par la tâche Gradle `bootWar`.
COPY --from=build /workspace/build/libs/*.war app.war

# Port HTTP écouté par Spring Boot. La publication sur l'hôte est gérée par
# docker-compose.yml.
EXPOSE 8080

# La forme JSON transmet correctement les signaux d'arrêt à la JVM.
ENTRYPOINT ["java", "-jar", "/app/app.war"]
