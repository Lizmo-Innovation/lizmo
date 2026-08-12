package app.lizmo.security;

import app.lizmo.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import javax.crypto.SecretKey;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

    private final SecretKey key;
    private final JwtProperties props;

    public JwtService(JwtProperties props) {
        this.props = props;
        this.key = Keys.hmacShaKeyFor(props.secret().getBytes(StandardCharsets.UTF_8));
    }

    public String issueAccessToken(UUID userId, List<String> profiles) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("profiles", profiles)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(props.accessTokenTtl())))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
