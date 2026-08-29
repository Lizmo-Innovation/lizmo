package app.lizmo.property;

import org.springframework.data.jpa.repository.JpaRepository;

public interface IssuedPropertyCodeRepository
        extends JpaRepository<IssuedPropertyCode, String> {
}
