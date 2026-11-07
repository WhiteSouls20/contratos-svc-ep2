# language: es
Característica: Servicio Contratos (microservicio contratos del caso caso11)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Contratos" está disponible
    Cuando consulto el listado de "contratos"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "contrato" con nombre "hola-cucumber"
    Cuando consulto el "contrato" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "contrato" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "contrato"
    Entonces la eliminación responde con código 204
    Y al consultar el "contrato" eliminado responde 404
