package cl.duoc.caso11.contratos.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.caso11.contratos.model.Contrato;

public interface ContratoRepository extends JpaRepository<Contrato, Long> {
}
