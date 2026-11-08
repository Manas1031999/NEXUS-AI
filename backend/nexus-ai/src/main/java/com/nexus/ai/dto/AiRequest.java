package com.nexus.ai.dto;

public record AiRequest(
        String prompt,
        String provider
) {
}