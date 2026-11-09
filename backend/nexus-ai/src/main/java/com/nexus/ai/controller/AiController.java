
package com.nexus.ai.controller;

import com.nexus.ai.dto.AiHistoryResponse;
import com.nexus.ai.dto.AiRequest;
import com.nexus.ai.dto.AiResponse;
import com.nexus.ai.dto.ProviderResponse;
import com.nexus.ai.service.AiProvider;
import com.nexus.ai.service.AiProviderManager;
import com.nexus.ai.service.AiRequestHistoryService;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiProviderManager providerManager;
    private final AiRequestHistoryService historyService;

    public AiController(
            AiProviderManager providerManager,
            AiRequestHistoryService historyService) {
        this.providerManager = providerManager;
        this.historyService = historyService;
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

        long startTime = System.nanoTime();

        AiResponse response = provider.generateResponse(request.prompt());

        long responseTimeMs = (System.nanoTime() - startTime) / 1_000_000;

        historyService.saveHistory(
                request.prompt(),
                providerName,
                response,
                responseTimeMs);

        return response;
    }

    @GetMapping("/providers")
    public ProviderResponse getProviders() {

        return new ProviderResponse(
                providerManager.getAvailableProviders());
    }

    @GetMapping("/history")
    public List<AiHistoryResponse> getAllHistory() {

        return historyService.getAllHistory();
    }
}
