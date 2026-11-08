package com.nexus.ai.service;

import com.nexus.ai.dto.AiResponse;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@Service
public class OllamaService implements AiProvider {

    private final RestClient restClient;
    private final String model;

    public OllamaService(
            @Value("${nexus.ai.ollama.base-url}") String baseUrl,
            @Value("${nexus.ai.ollama.model}") String model) {

        this.restClient = RestClient.create(baseUrl);
        this.model = model;
    }

    @Override
    public AiResponse generateResponse(String prompt) {

        Map<String, Object> request = Map.of(
                "model", model,
                "prompt", prompt,
                "stream", false,
                "keep_alive", "30s",
                "options", Map.of(
                        "num_ctx", 1024,
                        "num_predict", 120,
                        "num_thread", 2,
                        "temperature", 0.3
                )
        );

        try {

            Map<?, ?> result = restClient.post()
                    .uri("/api/generate")
                    .body(request)
                    .retrieve()
                    .body(Map.class);

            if (result == null || result.get("response") == null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY,
                        "Empty response received from Ollama"
                );
            }

            return new AiResponse(
                    "NEXUS AI",
                    getProviderName(),
                    model,
                    result.get("response").toString(),
                    "SUCCESS"
            );

        } catch (RestClientException ex) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Unable to communicate with Ollama"
            );
        }
    }

    @Override
    public String getProviderName() {
        return "ollama";
    }
}