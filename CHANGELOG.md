# Changelog
contratos-svc

## [1.1.0] - 2026 (Evaluacion Parcial 2)
Dockerfile multi-etapa optimizado (JRE Alpine, usuario sin root, capas de Spring Boot, healthcheck).
Pipeline CI/CD en GitHub Actions: pruebas, Snyk (dependencias, codigo e imagen), build y publicacion en GHCR, despliegue automatico en Kubernetes (kind).
Dependabot para Maven, Docker y GitHub Actions.
Orquestacion con Kubernetes (Deployment, Service, HPA, PDB) y Docker Compose endurecido.
Perfil `prod`: consola H2 deshabilitada y endpoints de Actuator restringidos.
Migracion de Spring Boot 3.3.5 a 4.1.2 y springdoc 2.6.0 a 3.2.0: Snyk bloqueo el pipeline por vulnerabilidades altas/criticas (Tomcat, Spring MVC, Jackson) que la rama 3.5.x ya no corrige.
Pruebas adaptadas a Spring Boot 4 (@MockitoBean, TestRestTemplate en spring-boot-resttestclient).

## [1.0.0] - 2026
Version inicial del microservicio contratos.
Pagina de presentacion con Swagger UI, OpenAPI y ReDoc.
Implementacion de modelo GitFlow y pipeline CI.
