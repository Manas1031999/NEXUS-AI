package com.nexus.ai.service;

import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class AiProviderManager {

    private final Map<String, AiProvider> providers;

    public AiProviderManager(List<AiProvider> providerList) {

        this.providers = providerList.stream()
                .collect(Collectors.toMap(
                        AiProvider::getProviderName,
                        Function.identity()));
    }

    public AiProvider getProvider(String providerName) {

        AiProvider provider = providers.get(providerName.toLowerCase());

        if (provider == null) {
            throw new IllegalArgumentException(
                    "Unsupported AI provider: " + providerName
                            + ". Available providers: " + getAvailableProviders());
        }

        return provider;
    }

    public List<String> getAvailableProviders() {
        return providers.keySet().stream().toList();
    }
}