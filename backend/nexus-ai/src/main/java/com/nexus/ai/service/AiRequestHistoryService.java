
package com.nexus.ai.service;

import com.nexus.ai.dto.AiHistoryResponse;
import com.nexus.ai.dto.AiResponse;
import com.nexus.ai.entity.AiRequestHistory;
import com.nexus.ai.repository.AiRequestHistoryRepository;

import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AiRequestHistoryService {

    private final AiRequestHistoryRepository historyRepository;

    public AiRequestHistoryService(
            AiRequestHistoryRepository historyRepository) {
        this.historyRepository = historyRepository;
    }

    public void saveHistory(
            String prompt,
            String provider,
            AiResponse response,
            long responseTimeMs) {

        AiRequestHistory history = new AiRequestHistory();

        history.setPrompt(prompt);
        history.setProvider(provider);
        history.setModel(response.model());
        history.setResponse(response.response());
        history.setStatus(response.status());
        history.setResponseTimeMs(responseTimeMs);

        historyRepository.save(history);
    }

    public List<AiHistoryResponse> getAllHistory() {

        return historyRepository
                .findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(history -> new AiHistoryResponse(
                        history.getId(),
                        history.getPrompt(),
                        history.getProvider(),
                        history.getModel(),
                        history.getResponse(),
                        history.getStatus(),
                        history.getResponseTimeMs(),
                        history.getCreatedAt()
                ))
                .toList();
    }
}
