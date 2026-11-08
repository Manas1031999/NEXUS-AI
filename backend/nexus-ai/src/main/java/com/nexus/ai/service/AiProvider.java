package com.nexus.ai.service;

import com.nexus.ai.dto.AiResponse;

public interface AiProvider {

    AiResponse generateResponse(String prompt);

    String getProviderName();
}