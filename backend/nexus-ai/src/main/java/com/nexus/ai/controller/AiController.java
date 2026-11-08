package com.nexus.ai.controller;

import com.nexus.ai.dto.AiRequest;
import com.nexus.ai.dto.AiResponse;
import com.nexus.ai.dto.ProviderResponse;
import com.nexus.ai.service.AiProvider;
import com.nexus.ai.service.AiProviderManager;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiProviderManager providerManager;

    public AiController(AiProviderManager providerManager) {
        this.providerManager = providerManager;
    }

    @PostMapping("/generate")
    @ResponseStatus(HttpStatus.OK)
    public AiResponse generate(@RequestBody AiRequest request) {

        if (request == null || request.prompt() == null
                || request.prompt().isBlank()) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Prompt cannot be empty");
        }

        String providerName = request.provider() == null
                || request.provider().isBlank()
                        ? "ollama"
                        : request.provider().trim().toLowerCase();

        AiProvider provider = providerManager.getProvider(providerName);

        return provider.generateResponse(request.prompt());
    }

    @GetMapping("/providers")
    public ProviderResponse getProviders() {

        return new ProviderResponse(
                providerManager.getAvailableProviders());
    }
}