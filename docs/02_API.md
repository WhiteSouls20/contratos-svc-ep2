# Contratos — Contrato de la API REST

## Base

- **Base path**: `/api/contratos`
- **Formato**: JSON — **Puerto**: 8080 (configurable con `PORT`)

## Recursos

| Método | Ruta | Códigos de estado | Descripción |
|--------|------|-------------------|-------------|
| GET | `/api/contratos` | 200 | Lista todos los recursos |
| GET | `/api/contratos/{id}` | 200 / 404 | Obtiene un recurso por id |
| POST | `/api/contratos` | 201 / 400 | Crea un recurso |
| PUT | `/api/contratos/{id}` | 200 / 404 / 400 | Actualiza un recurso |
| DELETE | `/api/contratos/{id}` | 204 / 404 | Elimina un recurso |

## Atributos de un recurso

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| id | Long | - | Identificador autogenerado |
| nombre | String | Sí | Nombre del recurso |

| propiedad | String | No | Campo del dominio |
| arrendatario | String | No | Campo del dominio |

## Ejemplos con curl

```bash
# Listar
curl http://localhost:8080/api/contratos

# Crear
curl -X POST http://localhost:8080/api/contratos \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Mi recurso"}'

# Obtener por id
curl http://localhost:8080/api/contratos/1

# Actualizar
curl -X PUT http://localhost:8080/api/contratos/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Recurso actualizado"}'

# Eliminar
curl -X DELETE http://localhost:8080/api/contratos/1
```
