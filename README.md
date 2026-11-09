# NEXUS AI

![CI](https://github.com/Manas1031999/NEXUS-AI/actions/workflows/ci.yml/badge.svg)

**A locally hosted, multi-provider AI assistant platform built with Java 21 and Spring Boot.**

NEXUS AI is a personal engineering project focused on building a practical AI backend that routes requests to different AI providers through a unified REST API. It currently supports local inference using Ollama and cloud-based generation using Google's Gemini API.

> **Project Status:** Multi-provider AI integration and PostgreSQL-based AI request history are implemented and tested. Ollama and Gemini are accessible through a common REST API. AI prompts, generated responses, provider details, model names, execution status, response times, and timestamps are persisted in PostgreSQL.

## Current Features

- Spring Boot REST API running on port `8080`.
- Multi-provider architecture using a common `AiProvider` interface.
- Provider selection per request.
- Ollama integration for local inference using `qwen2.5:1.5b`.
- Gemini integration using `gemini-3.8-flash` (subject to model availability and free-tier quotas).
- Provider discovery and health-check endpoints.
- Centralized exception handling for invalid provider requests.
- Improved Gemini API error handling and diagnostics.
- PostgreSQL integration using Spring Data JPA and Hibernate.
- AI request and response history persistence.
- AI request history REST API.
- Response time tracking for AI provider requests.
- Docker Compose setup for Ollama with a persistent model volume.
- PowerShell scripts to start and stop the local development environment.
- Bruno collection for API testing.
- GitHub Actions CI workflow.

## Technology Stack

| Area | Technology |
|---|---|
| Language | Java 21 |
| Backend | Spring Boot |
| Build | Maven Wrapper |
| Local AI Runtime | Ollama |
| Local Model | Qwen 2.5 1.5B |
| Cloud AI Provider | Google Gemini API |
| Database | PostgreSQL 18 |
| ORM | Spring Data JPA / Hibernate |
| Containers | Docker Desktop |
| API Testing | Bruno |
| Source Control | Git and GitHub |
| CI/CD | GitHub Actions |

## Architecture

```text
                       Bruno / API Client
                               |
                               v
                    Spring Boot REST API
                       localhost:8080
                               |
                               v
                         AiController
                               |
                  +------------+-------------+
                  |                          |
                  v                          v
           AiProviderManager        AiRequestHistoryService
                  |                          |
          +-------+-------+                  v
          |               |            AiRequestHistoryRepository
          v               v                  |
    OllamaService   GeminiService             v
          |               |             PostgreSQL 18
          v               v             ai_request_history
    Local Ollama      Gemini API
    Qwen 2.5 1.5B    Gemini Flash
```

Both AI providers implement the shared `AiProvider` interface.

The `AiProviderManager` selects the requested provider, allowing clients to use one API endpoint for different AI models.

The `AiRequestHistoryService` manages AI request history persistence and retrieval through Spring Data JPA.

Successful AI requests are stored in PostgreSQL with their prompts, generated responses, provider information, model names, execution status, response times, and timestamps.

## API Endpoints

Base URL: `http://localhost:8080`

### Health Check

```http
GET /api/v1/health
```

Confirms that the backend is running.

### List Available Providers

```http
GET /api/v1/ai/providers
```

Returns the providers registered with the application.

Example response:

```json
{
  "providers": [
    "gemini",
    "ollama"
  ]
}
```

### Generate an AI Response

```http
POST /api/v1/ai/generate
Content-Type: application/json
```

**Ollama request:**

```json
{
  "prompt": "Explain dependency injection in Spring Boot.",
  "provider": "ollama"
}
```

**Gemini request:**

```json
{
  "prompt": "Explain dependency injection in Spring Boot.",
  "provider": "gemini"
}
```

If `provider` is omitted, the controller defaults to `ollama`.

A successful response contains fields such as:

```json
{
  "application": "NEXUS AI",
  "provider": "gemini",
  "model": "gemini-3.8-flash",
  "response": "Generated response text...",
  "status": "SUCCESS"
}
```

The generated response text will vary.

### Get AI Request History

```http
GET /api/v1/ai/history
```

Returns the stored AI request history from PostgreSQL.

Example response:

```json
[
  {
    "id": 1,
    "prompt": "Explain Spring Boot dependency injection.",
    "provider": "gemini",
    "model": "gemini-3.8-flash",
    "response": "Generated response text...",
    "status": "SUCCESS",
    "responseTimeMs": 199681,
    "createdAt": "2026-11-10T02:35:12.595681"
  }
]
```

History records include:

- Request ID
- Original prompt
- AI provider
- Model name
- Generated response
- Execution status
- Response time in milliseconds
- Creation timestamp

Records are returned in descending creation-time order.

## Local Development Requirements

The current development environment is Windows with PowerShell.

Install the following:

- Java 21
- Git
- Docker Desktop
- PostgreSQL 18
- Bruno (recommended for API testing)

## Configuration

Backend configuration is maintained in:

`backend/nexus-ai/src/main/resources/application.properties`

Relevant properties:

```properties
spring.application.name=nexus-ai
server.port=8080

spring.datasource.url=jdbc:postgresql://localhost:5432/nexus_ai
spring.datasource.username=${DB_USERNAME:postgres}
spring.datasource.password=${DB_PASSWORD}

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.open-in-view=false

nexus.ai.ollama.base-url=http://localhost:11434
nexus.ai.ollama.model=qwen2.5:1.5b

nexus.ai.gemini.base-url=https://generativelanguage.googleapis.com/v1beta
nexus.ai.gemini.model=gemini-3.8-flash
nexus.ai.gemini.api-key=${GEMINI_API_KEY:}
```

### Secrets and API Keys

**Never commit database passwords or API keys to GitHub.**

The startup script prompts for the PostgreSQL password and Gemini API key using secure PowerShell input when the corresponding environment variables are not already set.

The values are passed to the backend process through environment variables. Do not hardcode credentials into source files or commit them to version control.

Gemini usage depends on the account's available quota and Google's current free-tier terms. This project does not assume unlimited free API access.

## Run NEXUS AI on Windows

Run commands from the repository root.

### Start

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\start-nexus.ps1"
```

The startup script:

1. Loads the PostgreSQL password securely if it is not already available.
2. Loads the Gemini API key securely if it is not already available.
3. Checks Java.
4. Starts PostgreSQL if it is stopped.
5. Starts Ollama through Docker Compose and checks that the configured model is available.
6. Starts the Spring Boot backend if it is not already healthy.
7. Waits for the health endpoint.

### Stop

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\stop-nexus.ps1"
```

The shutdown script stops the managed backend process and Ollama container. PostgreSQL remains running, and the Ollama model volume is preserved.

### Logs

Runtime logs are written under `logs/`.

Do not commit local runtime logs or PID files.

## Ollama and Docker

Ollama is managed by `docker-compose.yml`.

- Container: `nexus-ollama`
- Image: `ollama/ollama:latest`
- Host API: `http://localhost:11434`
- Model: `qwen2.5:1.5b`
- Persistent Docker volume: `nexus_ollama`

The model is stored in a persistent Docker volume so stopping or recreating the container does not require downloading it again.

Check available local models:

```powershell
Invoke-RestMethod http://localhost:11434/api/tags
```

**Note:** The current project uses Docker Compose to manage Ollama. The Spring Boot backend currently runs directly on Windows; a dedicated backend Dockerfile and full containerized deployment are planned for a future stage.

## API Testing with Bruno

The Bruno collection currently includes requests for:

- Health Check
- Get Available Providers
- Generate Response
- Generate Response - Ollama
- Generate Response - Invalid Provider
- Generate Gemini
- Get AI History

### Verified API Tests

| Test | Expected Result | Observed |
|---|---|---|
| Health Check | `200 OK` | Passed |
| Get Available Providers | `200 OK` | Passed |
| Generate with Ollama | `200 OK` | Passed |
| Invalid Provider | `400 Bad Request` | Passed |
| Generate with Gemini | `200 OK` | Passed |
| Get AI History | `200 OK` | Passed |
| PostgreSQL History Persistence | Records saved | Passed |

Both Gemini and Ollama have been tested successfully. Their request history has also been verified in the same PostgreSQL table.

## Project Structure

```text
NEXUS-AI/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── backend/
│   └── nexus-ai/
│       ├── src/
│       │   ├── main/
│       │   │   ├── java/
│       │   │   │   └── com/nexus/ai/
│       │   │   │       ├── controller/
│       │   │   │       ├── dto/
│       │   │   │       ├── entity/
│       │   │   │       ├── exception/
│       │   │   │       ├── repository/
│       │   │   │       └── service/
│       │   │   │
│       │   │   └── resources/
│       │   │       └── application.properties
│       │   │
│       │   └── test/
│       │
│       └── mvnw.cmd
│
├── bruno/
│   ├── AI/
│   ├── Health/
│   └── environments/
│
├── scripts/
│   ├── start-nexus.ps1
│   ├── stop-nexus.ps1
│   ├── start-ollama.ps1
│   └── stop-ollama.ps1
│
├── logs/                 # Local runtime output; do not commit
├── docker-compose.yml
├── README.md
└── LICENSE
```

## Development Progress

### Completed

- [x] Set up Java 21 and Maven Wrapper.
- [x] Configure PostgreSQL database connectivity.
- [x] Run Ollama using Docker Compose.
- [x] Persist the Ollama model using a Docker volume.
- [x] Integrate Qwen 2.5 1.5B through Ollama.
- [x] Build the common `AiProvider` abstraction.
- [x] Implement provider selection with `AiProviderManager`.
- [x] Add AI generation and provider-list endpoints.
- [x] Add centralized exception handling for invalid provider selection.
- [x] Integrate Gemini.
- [x] Improve Gemini error handling and diagnostics.
- [x] Load PostgreSQL and Gemini credentials through secure PowerShell prompts.
- [x] Create start/stop scripts for the local environment.
- [x] Test the APIs using Bruno.
- [x] Verify Gemini after a fresh startup through `start-nexus.ps1`.
- [x] Create AI request history entity and repository.
- [x] Implement AI request history persistence in PostgreSQL.
- [x] Store provider, model, prompt, response, status, and response time.
- [x] Add AI request history REST API.
- [x] Verify history persistence for both Gemini and Ollama.

### Next Steps

- [ ] Add pagination and filtering to the AI history API.
- [ ] Add automated tests for provider selection and error scenarios.
- [ ] Implement failed request history tracking.
- [ ] Design provider fallback and retry behaviour.
- [ ] Add request validation, limits, and safer error responses.
- [ ] Improve AI response latency and performance.
- [ ] Build a frontend for interacting with NEXUS AI.
- [ ] Create a Dockerfile for the Spring Boot backend.
- [ ] Explore full containerized deployment using Docker Compose.
- [ ] Add deployment and operations documentation.

## Development Philosophy

NEXUS AI is being developed incrementally. Each feature is implemented, tested locally, and documented.

The initial focus is a reliable backend foundation, local-first inference, provider flexibility, secure configuration, persistent request history, and reproducible development workflows.

## Disclaimer

This is an actively developed personal project. Features, configuration, model identifiers, and API behaviour may change as development continues.