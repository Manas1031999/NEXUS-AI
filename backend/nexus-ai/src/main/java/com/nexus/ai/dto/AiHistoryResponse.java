
package com.nexus.ai.dto;

import java.time.LocalDateTime;

public record AiHistoryResponse(
        Long id,
        String prompt,
        String provider,
        String model,
        String response,
        String status,
        Long responseTimeMs,
        LocalDateTime createdAt
) {}
