# Changelog
contratos-svc

## [1.1.0] - 2026 (Evaluacion Parcial 2)
Dockerfile multi-etapa optimizado (JRE Alpine, usuario sin root, capas de Spring Boot, healthcheck).
Pipeline CI/CD en GitHub Actions: pruebas, Snyk (dependencias, codigo e imagen), build y publicacion en GHCR, despliegue automatico en Kubernetes (kind).
Dependabot para Maven, Docker y GitHub Actions.
Orquestacion con Kubernetes (Deployment, Service, HPA, PDB) y Docker Compose endurecido.
Perfil `prod`: consola H2 deshabilitada y endpoints de Actuator restringidos.
Actualizacion de Spring Boot 3.3.5 -> 3.5.16 y springdoc 2.6.0 -> 2.8.17 para corregir vulnerabilidades altas/criticas detectadas por Snyk (Tomcat, Spring MVC, Jackson).

## [1.0.0] - 2026
Version inicial del microservicio contratos.
Pagina de presentacion con Swagger UI, OpenAPI y ReDoc.
Implementacion de modelo GitFlow y pipeline CI.
