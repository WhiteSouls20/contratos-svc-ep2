package cl.duoc.caso11.contratos.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.caso11.contratos.model.Contrato;
import cl.duoc.caso11.contratos.repository.ContratoRepository;

@Service
public class ContratoService {

    private final ContratoRepository repository;

    public ContratoService(ContratoRepository repository) {
        this.repository = repository;
    }

    public List<Contrato> findAll() {
        return repository.findAll();
    }

    public Optional<Contrato> findById(Long id) {
        return repository.findById(id);
    }

    public Contrato create(Contrato recurso) {
        return repository.save(recurso);
    }

    public Optional<Contrato> update(Long id, Contrato datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setPropiedad(datos.getPropiedad());
            existente.setArrendatario(datos.getArrendatario());
            return repository.save(existente);
        });
    }

    public boolean delete(Long id) {
        return repository.findById(id).map(existente -> {
            repository.delete(existente);
            return true;
        }).orElse(false);
    }
}
