package com.nexus.ai.controller;

import com.nexus.ai.dto.AiRequest;
import com.nexus.ai.dto.AiResponse;
import com.nexus.ai.service.OllamaService;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final OllamaService ollamaService;

    public AiController(OllamaService ollamaService) {
        this.ollamaService = ollamaService;
    }

    @PostMapping("/generate")
    @ResponseStatus(HttpStatus.OK)
    public AiResponse generate(@RequestBody AiRequest request) {

        if (request == null || request.prompt() == null
                || request.prompt().isBlank()) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Prompt cannot be empty"
            );
        }

        return ollamaService.generateResponse(request.prompt());
    }
}