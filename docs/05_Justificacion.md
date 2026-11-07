# ms-contratos — Justificación del servicio y cobertura de requisitos

**Caso caso11 — InmoNube** (Plataforma inmobiliaria) · EP01

Este documento justifica la existencia de **ms-contratos** como microservicio independiente: qué requisitos del negocio cubre (funcionales, no funcionales y de seguridad), por qué está delimitado así (SRP), y qué tecnología AWS se usa para cada responsabilidad y **por qué**. Los diagramas que respaldan esta justificación están en `docs/diagramas/`.

---

## 1. Misión del servicio

ms-contratos mantiente el seguimiento en tiempo real del proceso: consume los eventos y señales del dominio (estados, posición, sensores, etapas), mantiene el estado vigente consultable en milisegundos y notifica las transiciones del caso caso11 (InmoNube).

> Su perfil de carga es de ingesta continua de eventos de alta frecuencia (GPS, sensores, cambios de etapa) — miles por segundo en hora punta — lo que exige un almacén clave-valor de baja latencia y colas persistentes que no pierdan ni un solo evento.

---

## 2. Requisitos funcionales que cubre

| RF | Requisito (de `00_PresentacionEmpresa.md`) | Qué hace ms-contratos al respecto | Evidencia |
|----|------------------------------------------|-------------------------------|-----------|
| **RF-05** | Generar y firmar contratos de arriendo en línea | Ingresa y consulta el estado en tiempo real: cada evento actualiza el recurso y dispara la notificación correspondiente | diagrama de secuencia (evento en tiempo real) |

**Por qué estos RF justifican un servicio aparte:** Su perfil de carga es de ingesta continua de eventos de alta frecuencia (GPS, sensores, cambios de etapa) — miles por segundo en hora punta — lo que exige un almacén clave-valor de baja latencia y colas persistentes que no pierdan ni un solo evento.

---

## 3. Requisitos no funcionales que cubre

| RNF | Criterio | Cómo lo cumple ms-contratos | Decisión técnica |
|-----|----------|--------------------------|------------------|
| **RNF-05** (Rendimiento) | Búsqueda con filtros en menos de 2 segundos; subida y procesamiento de fotos en menos de 10 segundos | Respuestas dentro del umbral exigido por el caso (ver alarmas p95) | Caché/bajo acoplamiento + CloudWatch con alarma de latencia |
| **RNF-01** (Escalabilidad) | La búsqueda de propiedades debe escalar en campañas de lanzamiento sin afectar contratos | Auto scaling independiente de este servicio (2→20 tareas Fargate según carga) | ECS Fargate + alarmas de CloudWatch: solo este componente escala en el pico |
| **RNF-06** (Integridad) | Los contratos firmados deben ser inmutables y auditables | Escritura persistida antes de confirmar; eventos por cola con DLQ ante fallas | Aurora transaccional + SQS persistido + idempotencia |

**Justificación SRP (IE9):** ms-contratos tiene **una sola razón de cambio**: las reglas de seguimiento y transición de estados del proceso en tiempo real. Si mañana cambia esa regla, **ningún otro servicio se modifica**.

---

## 4. Requisitos de seguridad que cubre (mapeo STRIDE)

| Amenaza | Escenario en este servicio | Contramedida |
|---------|-----------------------------|--------------|
| **S**poofing | Enviar eventos falsos desde un dispositivo o actor ajeno | JWT del emisor + credenciales IAM por tarea; eventos rechazados si el emisor no corresponde |
| **T**ampering | Alterar el estado o la posición reportada | Validación de coherencia del evento (secuencia/timestamp) y escritura condicional en el almacén |
| **R**epudiation | Negar un evento o transición de estado | Cada evento queda persistido con emisor y timestamp; trail auditable en CloudWatch/CloudTrail |
| **I**nformation disclosure | Consultar el seguimiento de un recurso ajeno | Autorización por recurso (owner) y cifrado at-rest (KMS) del almacén de eventos |
| **D**enial of service | Inundar el canal con eventos basura (flooding) | Throttling por dispositivo en API Gateway + cola SQS que absorbe el pico + DLQ para lo inválido |
| **E**levation of privilege | Invocar comandos de control sin rol | Roles separados (consulta vs. control) verificados por endpoint; SG que solo acepta el ALB |

---

## 5. Stack tecnológico y por qué cada tecnología

### 5.1 Stack de la aplicación

| Tecnología | Para qué se usa en ms-contratos |
|------------|------------------------------|
| **Java 21 + Spring Boot 3.3** | Framework estándar de la asignatura: implementa la API REST, la lógica de negocio y el acceso a datos del servicio |
| **Spring Data JPA** | Persistencia de las entidades del dominio en la base de datos propia (repositorios por entidad) |
| **Bean Validation** | Validación de los payloads de entrada antes de procesar (jakarta.validation) |
| **springdoc-openapi** | Documentación viva del contrato REST (Swagger UI / ReDoc) para consumidores y equipo |
| **Docker + Docker Compose** | Empaquetado reproducible; la misma imagen corre en local y en ECS Fargate |
| **JUnit 5 + Mockito + MockMvc** | Pruebas unitarias y de contrato HTTP (cobertura 100 % LINE con JaCoCo) |
| **Cucumber (BDD)** | Escenarios en español alineados a los endpoints, ejecutados contra el servidor real |

### 5.2 Stack AWS y justificación de cada servicio

| Servicio AWS | Rol en ms-contratos | Por qué se eligió |
|--------------|----------------|--------------------|
| **Amazon DynamoDB (Global Tables)** | Almacén clave-valor del estado en tiempo real | Miles de escrituras/segundo con latencia de un dígito: el único motor que sostiene el RNF de rendimiento en tiempo real |
| **Amazon SQS (+ DLQ)** | Ingesta persistida de eventos de alta frecuencia | Ningún evento se pierde aunque el servicio se sature (RNF de consistencia) |
| **Amazon EventBridge** | Consume eventos del dominio y publica transiciones | Desacople entre el proceso y su seguimiento |
| **AWS Lambda** | Materialización y agregados del flujo | Procesamiento intermitente que escala a cero |
| **ECS Fargate** | Runtime con auto scaling 2→20 tareas | Absorbe el pico de ingesta solo de este servicio (RNF de escalabilidad) |
| **CloudWatch + X-Ray** | Métricas de ingesta y latencia del flujo | Alarma si el evento tarda más que el umbral del caso (IE8) |

### 5.3 Patrones aplicados (IE5)

| Patrón | Dónde |
|--------|-------|
| **Event-Driven Architecture** | Consume eventos del bus y actualiza el estado en tiempo real |
| **Cola de mensajes (SQS + DLQ)** | Absorbe picos de miles de eventos por segundo sin pérdida |
| **CQRS-lite** | Escritura al flujo de eventos + lectura del estado materializado en DynamoDB |

---

## 6. Delimitación: qué NO hace ms-contratos (IE9/IE10)

| No hace | Lo hace | Por qué |
|---------|---------|---------|
| usuarios | ms-usuarios | razones de cambio distintas: la autenticación se centraliza aquí, pero el negocio de cada dominio queda en su servicio |
| propiedades | ms-propiedades | razones de cambio distintas: el catálogo consulta y publica; las operaciones de negocio las orquesta el servicio transaccional |
| búsqueda | ms-busqueda | razones de cambio distintas: el catálogo consulta y publica; las operaciones de negocio las orquesta el servicio transaccional |
| pagos de arriendo | ms-pagosarriendo | razones de cambio distintas: el dinero se procesa aquí, pero la operación que lo origina vive en el servicio central |

---

## 7. Diagramas que respaldan esta justificación

```
docs/diagramas/
├── c4/
│   ├── C4-1-Contexto     el servicio, sus actores y sus vecinos
│   ├── C4-2-Contenedor   la API, la BD propia y los componentes del dominio
│   └── C4-3-Componentes  validador/service, clientes, publicador, repos
├── secuencia/
│   └── Secuencia-Contrato   evento en tiempo real
└── infraestructura/
    └── Infra-AWS         despliegue solo de este servicio, con iconos oficiales AWS
```

