package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Exchange a refresh token for a new access token")
public record RefreshRequest(@NotBlank String refreshToken) {
}
