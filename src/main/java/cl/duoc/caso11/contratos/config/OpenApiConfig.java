package cl.duoc.caso11.contratos.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Contratos API")
                        .version("1.0.0")
                        .description("Microservicio Contratos del caso caso11 - InmoNube."));
    }
}
