
package com.nexus.ai.repository;

import com.nexus.ai.entity.AiRequestHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AiRequestHistoryRepository
        extends JpaRepository<AiRequestHistory, Long> {
}
