package app.lizmo.security;

import app.lizmo.config.CorsProperties;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Browser clients only — the admin web app, and Flutter web during
     * development. Origins are configured rather than wildcarded, since
     * allowing "*" alongside credentials is rejected by browsers anyway.
     */
    @Bean
    CorsConfigurationSource corsConfigurationSource(CorsProperties properties) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(properties.allowedOrigins());
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    SecurityFilterChain filterChain(
            HttpSecurity http,
            JwtAuthenticationFilter jwtFilter,
            RestAuthenticationEntryPoint authenticationEntryPoint,
            RestAccessDeniedHandler accessDeniedHandler,
            CorsConfigurationSource corsConfigurationSource) throws Exception {

        return http.csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/**").permitAll()
                        // The one GET that has to be public: somebody following
                        // an invitation link has no account yet, or is not
                        // signed in on the device the email opened. Named
                        // rather than opening every GET under /auth.
                        .requestMatchers(HttpMethod.GET, "/api/v1/auth/invitations/*").permitAll()
                        // Where to write to Lizmo. Public by requirement: the
                        // account deletion page shows it, and that page has to
                        // work for somebody who has already uninstalled the
                        // app and cannot sign in to ask.
                        .requestMatchers(HttpMethod.GET, "/api/v1/platform/support").permitAll()
                        // Asked on the splash screen, before anybody signs
                        // in: an app too old to be allowed in cannot first
                        // be made to log in.
                        .requestMatchers(HttpMethod.GET, "/api/v1/platform/app-version").permitAll()
                        // The sub-paths too, not just /actuator/health: Cloud
                        // Run's liveness probe hits /actuator/health/liveness,
                        // and a 401 counts as a failed probe. Three of those
                        // and the container is killed -- an authentication
                        // rule quietly restarting a healthy service.
                        .requestMatchers("/actuator/health", "/actuator/health/**",
                                "/actuator/info").permitAll()
                        // Unmatched requests are forwarded here internally. Without
                        // this, a genuine 404 is re-checked as an unauthenticated
                        // request and surfaces as 403, hiding the real cause.
                        // Let through at the Spring level and defended inside
                        // by JobAuthoriser, which verifies Google's OIDC token.
                        // Spring's own filter would reject the scheduler's
                        // token as an unparseable Lizmo JWT before the
                        // controller ever saw it.
                        .requestMatchers("/internal/jobs/**").permitAll()
                        .requestMatchers("/error").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        // Restricted as a whole rather than per endpoint, so a
                        // route added under /admin later cannot be left open by
                        // somebody forgetting an annotation on it.
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated())
                // 401 for "not signed in", 403 for "signed in but not allowed".
                .exceptionHandling(e -> e
                        .authenticationEntryPoint(authenticationEntryPoint)
                        .accessDeniedHandler(accessDeniedHandler))
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }
}
