# syntax=docker/dockerfile:1

# ---------- Etapa 1: compilacion ----------
FROM maven:3.9-eclipse-temurin-26-alpine AS build
WORKDIR /app
COPY pom.xml ./
RUN --mount=type=cache,target=/root/.m2 mvn -B -q dependency:go-offline
COPY src ./src
# Las pruebas se ejecutan en el job "test" del pipeline, no dentro de la imagen
RUN --mount=type=cache,target=/root/.m2 mvn -B -q package -DskipTests \
    && java -Djarmode=tools -jar target/*.jar extract --layers --launcher --destination target/layers

# ---------- Etapa 2: runtime (solo JRE, sin Maven ni codigo fuente) ----------
FROM eclipse-temurin:21-jre-alpine

ARG GIT_SHA=local
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="contratos-svc" \
      org.opencontainers.image.description="Microservicio Contratos - caso11 InmoNube" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}"

# Usuario sin privilegios
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
WORKDIR /app

# Capas de Spring Boot: las dependencias cambian poco y quedan cacheadas
COPY --from=build --chown=app:app /app/target/layers/dependencies/ ./
COPY --from=build --chown=app:app /app/target/layers/spring-boot-loader/ ./
COPY --from=build --chown=app:app /app/target/layers/snapshot-dependencies/ ./
COPY --from=build --chown=app:app /app/target/layers/application/ ./

USER app
EXPOSE 8080

# La JVM respeta los limites de memoria del contenedor
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError" \
    APP_VERSION="${GIT_SHA}"

HEALTHCHECK --interval=15s --timeout=3s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health/readiness || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
