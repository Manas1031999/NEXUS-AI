
package com.nexus.ai.service;


import com.nexus.ai.dto.AiResponse;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@Service
public class GeminiService implements AiProvider {

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final String model;
    private final String apiKey;

    public GeminiService(
            @Value("${nexus.ai.gemini.base-url}") String baseUrl,
            @Value("${nexus.ai.gemini.model}") String model,
            @Value("${nexus.ai.gemini.api-key}") String apiKey,
            ObjectMapper objectMapper) {

        this.restClient = RestClient.create(baseUrl);
        this.objectMapper = objectMapper;
        this.model = model;
        this.apiKey = apiKey;
    }

    @Override
    public AiResponse generateResponse(String prompt) {

        if (apiKey == null || apiKey.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Gemini API key is not configured"
            );
        }

        Map<String, Object> request = Map.of(
                "contents", List.of(
                        Map.of(
                                "parts", List.of(
                                        Map.of("text", prompt)
                                )
                        )
                )
        );

        try {

            JsonNode result = restClient.post()
                    .uri("/models/{model}:generateContent", model)
                    .header("x-goog-api-key", apiKey)
                    .body(request)
                    .retrieve()
                    .body(JsonNode.class);

            if (result == null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY,
                        "Empty response received from Gemini"
                );
            }

            JsonNode candidates = result.path("candidates");

            if (!candidates.isArray() || candidates.isEmpty()) {

                String blockReason = result
                        .path("promptFeedback")
                        .path("blockReason")
                        .asText("");

                String message = blockReason.isBlank()
                        ? "Gemini did not generate a response"
                        : "Gemini blocked the prompt: " + blockReason;

                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY,
                        message
                );
            }

            JsonNode parts = candidates
                    .get(0)
                    .path("content")
                    .path("parts");

            if (!parts.isArray() || parts.isEmpty()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY,
                        "Gemini returned an empty response"
                );
            }

            StringBuilder response = new StringBuilder();

            for (JsonNode part : parts) {
                if (part.hasNonNull("text")) {
                    response.append(part.get("text").asText());
                }
            }

            if (response.isEmpty()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY,
                        "Gemini response contains no text"
                );
            }

            return new AiResponse(
                    "NEXUS AI",
                    getProviderName(),
                    model,
                    response.toString(),
                    "SUCCESS"
            );

        } catch (RestClientResponseException ex) {

            int statusCode = ex.getStatusCode().value();
            String providerMessage = extractErrorMessage(
                    ex.getResponseBodyAsString()
            );

            HttpStatus httpStatus;
            String message;

            switch (statusCode) {

                case 400 -> {
                    httpStatus = HttpStatus.BAD_REQUEST;
                    message = "Gemini rejected the request: " + providerMessage;
                }

                case 401, 403 -> {
                    httpStatus = HttpStatus.FORBIDDEN;
                    message = "Gemini API authentication or permission error: "
                            + providerMessage;
                }

                case 404 -> {
                    httpStatus = HttpStatus.BAD_GATEWAY;
                    message = "Gemini model or endpoint not found: "
                            + providerMessage;
                }

                case 429 -> {
                    httpStatus = HttpStatus.TOO_MANY_REQUESTS;
                    message = "Gemini rate limit or quota exceeded: "
                            + providerMessage;
                }

                default -> {
                    httpStatus = HttpStatus.BAD_GATEWAY;
                    message = "Gemini API error (HTTP "
                            + statusCode + "): " + providerMessage;
                }
            }

            throw new ResponseStatusException(httpStatus, message);

        } catch (RestClientException ex) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Unable to communicate with Gemini"
            );
        }
    }

    private String extractErrorMessage(String responseBody) {

        if (responseBody == null || responseBody.isBlank()) {
            return "No error details provided";
        }

        try {
            JsonNode root = objectMapper.readTree(responseBody);
            String message = root.path("error").path("message").asText("");

            return message.isBlank()
                    ? "Gemini returned an error"
                    : message;

        } catch (Exception ex) {
            return "Gemini returned an unreadable error response";
        }
    }

    @Override
    public String getProviderName() {
        return "gemini";
    }
}
