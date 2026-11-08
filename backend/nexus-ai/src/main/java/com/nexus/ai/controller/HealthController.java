package com.nexus.ai.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    @GetMapping
    public Map<String, String> health() {

        return Map.of(
            "application", "NEXUS AI",
            "status", "UP",
            "message", "NEXUS AI is running successfully!"
        );
    }
}