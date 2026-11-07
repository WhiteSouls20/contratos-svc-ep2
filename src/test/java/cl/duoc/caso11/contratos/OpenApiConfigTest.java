package cl.duoc.caso11.contratos;

import org.junit.jupiter.api.Test;
import cl.duoc.caso11.contratos.config.OpenApiConfig;

import static org.assertj.core.api.Assertions.assertThat;

class OpenApiConfigTest {

    @Test
    void beanOpenApiGenerado() {
        assertThat(new OpenApiConfig().customOpenAPI()).isNotNull();
    }
}
