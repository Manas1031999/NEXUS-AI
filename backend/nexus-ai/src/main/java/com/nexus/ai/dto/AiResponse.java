package com.nexus.ai.dto;

public record AiResponse(
    String application,
    String provider,
    String model,
    String response,
    String status
) {
}