# NEXUS AI

**A locally hosted, multi-provider AI assistant platform built with Java
21 and Spring Boot.**

NEXUS AI is a personal engineering project focused on building a
practical AI backend that routes requests to different AI providers
through one REST API. It currently supports a local Ollama model and
Google's Gemini API.

> **Project status:** Core multi-provider integration is working. Ollama
> and Gemini have both been tested successfully through the NEXUS AI
> API, including a fresh startup through the PowerShell startup script.

## Current Features

-   Spring Boot REST API on port `8080`.
-   Multi-provider architecture using a common `AiProvider` interface.
-   Provider selection per request.
-   Ollama integration for local inference using `qwen2.5:1.5b`.
-   Gemini integration using `gemini-3.8-flash` (subject to model
    availability and free-tier quotas).
-   Provider discovery and health-check endpoints.
-   Centralized handling for invalid provider requests.
-   PostgreSQL configuration.
-   Docker Compose setup for Ollama with a persistent model volume.
-   PowerShell scripts to start and stop the local development
    environment.
-   Bruno collection for API testing.

## Technology Stack

  Area                Technology
  ------------------- -------------------
  Language            Java 21
  Backend             Spring Boot
  Build               Maven Wrapper
  Local AI runtime    Ollama
  Local model         Qwen 2.5 1.5B
  Cloud AI provider   Google Gemini API
  Database            PostgreSQL 18
  Containers          Docker Desktop
  API testing         Bruno
  Source control      Git and GitHub

## Architecture

``` text
                    Bruno / API Client
                            |
                            v
                 Spring Boot REST API
                    localhost:8080
                            |
                            v
                     AiController
                            |
                            v
                   AiProviderManager
                     /           \
                    v             v
              OllamaService   GeminiService
                    |             |
                    v             v
              Local Ollama    Gemini API
              Qwen 2.5 1.5B  gemini-3.8-flash
```

Both providers implement the shared `AiProvider` interface. The
controller uses `AiProviderManager` to select the requested provider,
allowing clients to use one API endpoint for different models.

## API Endpoints

Base URL: `http://localhost:8080`

### Health Check

``` http
GET /api/v1/health
```

Confirms that the backend is running.

### List Available Providers

``` http
GET /api/v1/ai/providers
```

Returns the providers registered with the application.

### Generate an AI Response

``` http
POST /api/v1/ai/generate
Content-Type: application/json
```

Ollama request:

``` json
{
  "prompt": "Explain dependency injection in Spring Boot.",
  "provider": "ollama"
}
```

Gemini request:

``` json
{
  "prompt": "Explain dependency injection in Spring Boot.",
  "provider": "gemini"
}
```

If `provider` is omitted, the current controller defaults to `ollama`.

A successful response contains fields such as:

``` json
{
  "application": "NEXUS AI",
  "provider": "gemini",
  "model": "gemini-3.8-flash",
  "response": "Generated response text...",
  "status": "SUCCESS"
}
```

The generated response text will vary.

## Local Development Requirements

The current development environment is Windows with PowerShell. Install:

-   Java 21
-   Git
-   Docker Desktop
-   PostgreSQL 18
-   Bruno (recommended for API testing)

## Configuration

Backend configuration is maintained in:

`backend/nexus-ai/src/main/resources/application.properties`

Relevant properties:

``` properties
spring.application.name=nexus-ai
server.port=8080

spring.datasource.url=jdbc:postgresql://localhost:5432/nexus_ai
spring.datasource.username=${DB_USERNAME:postgres}
spring.datasource.password=${DB_PASSWORD}

nexus.ai.ollama.base-url=http://localhost:11434
nexus.ai.ollama.model=qwen2.5:1.5b

nexus.ai.gemini.base-url=https://generativelanguage.googleapis.com/v1beta
nexus.ai.gemini.model=gemini-3.8-flash
nexus.ai.gemini.api-key=${GEMINI_API_KEY}
```

### Secrets and API keys

**Never commit database passwords or API keys to GitHub.**

The startup script prompts for the PostgreSQL password and Gemini API
key using secure PowerShell input when the corresponding environment
variables are not already set. The values are passed to the backend
process through environment variables; do not hardcode them into source
files.

Gemini usage depends on the account's available quota and Google's
current free-tier terms. This project does not assume unlimited free API
access.

## Run NEXUS AI on Windows

Run commands from the repository root.

### Start

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\start-nexus.ps1"
```

The startup script:

1.  Loads the PostgreSQL password securely if it is not already
    available.
2.  Loads the Gemini API key securely if it is not already available.
3.  Checks Java.
4.  Starts PostgreSQL if it is stopped.
5.  Starts Ollama through Docker Compose and checks that the configured
    model is available.
6.  Starts the Spring Boot backend if it is not already healthy.
7.  Waits for the health endpoint.

### Stop

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\stop-nexus.ps1"
```

The shutdown script stops the managed backend process and Ollama
container. PostgreSQL remains running, and the Ollama model volume is
preserved.

### Logs

Runtime logs are written under `logs/`. Do not commit local runtime logs
or PID files.

## Ollama and Docker

Ollama is managed by `docker-compose.yml`.

-   Container: `nexus-ollama`
-   Image: `ollama/ollama:latest`
-   Host API: `http://localhost:11434`
-   Model: `qwen2.5:1.5b`
-   Persistent Docker volume: `nexus_ollama`

The model is stored in a persistent Docker volume so stopping or
recreating the container does not require downloading it again.

Check available local models:

``` powershell
Invoke-RestMethod http://localhost:11434/api/tags
```

## API Testing with Bruno

The Bruno collection currently includes requests for:

-   Health Check
-   Get Available Providers
-   Generate Response
-   Generate Response -- Ollama
-   Generate Response -- Invalid Provider
-   Generate Gemini

Verified outcomes:

  Test                          Expected result   Observed
  ------------------------- ------------------- ----------
  Health Check                         `200 OK`     Passed
  Get Available Providers              `200 OK`     Passed
  Generate with Ollama                 `200 OK`     Passed
  Invalid provider            `400 Bad Request`     Passed
  Generate with Gemini                 `200 OK`     Passed

Gemini was also tested after a fresh startup through `start-nexus.ps1`,
confirming that the securely prompted API key reaches the backend
process.

## Project Structure

``` text
NEXUS-AI/
├── backend/
│   └── nexus-ai/
│       ├── src/
│       │   └── main/
│       │       ├── java/
│       │       │   └── com/nexus/ai/
│       │       │       ├── controller/
│       │       │       ├── dto/
│       │       │       ├── exception/
│       │       │       └── service/
│       │       └── resources/
│       │           └── application.properties
│       └── mvnw.cmd
├── scripts/
│   ├── start-nexus.ps1
│   ├── stop-nexus.ps1
│   ├── start-ollama.ps1
│   └── stop-ollama.ps1
├── logs/                 # Local runtime output; do not commit
├── docker-compose.yml
└── README.md
```

## Development Progress

### Completed

-   [x] Set up Java 21 and Maven Wrapper.
-   [x] Configure PostgreSQL database connectivity.
-   [x] Run Ollama using Docker Compose.
-   [x] Persist the Ollama model using a Docker volume.
-   [x] Integrate Qwen 2.5 1.5B through Ollama.
-   [x] Build the common `AiProvider` abstraction.
-   [x] Implement provider selection with `AiProviderManager`.
-   [x] Add AI generation and provider-list endpoints.
-   [x] Add centralized exception handling for invalid provider
    selection.
-   [x] Integrate Gemini.
-   [x] Load PostgreSQL and Gemini credentials through secure PowerShell
    prompts.
-   [x] Create start/stop scripts for the local environment.
-   [x] Test the APIs using Bruno.
-   [x] Verify Gemini after a fresh startup through `start-nexus.ps1`.

### Next Steps

-   [ ] Improve Gemini error handling and diagnostics without exposing
    secrets.
-   [ ] Add automated tests for provider selection and error scenarios.
-   [ ] Add AI request/response history persistence in PostgreSQL.
-   [ ] Design provider fallback and retry behaviour.
-   [ ] Add request validation, limits, and safer error responses.
-   [ ] Build a frontend for interacting with NEXUS AI.
-   [ ] Add deployment and operations documentation.

## Development Philosophy

NEXUS AI is being developed incrementally. Each feature is implemented,
tested locally, and documented.

The initial focus is a reliable backend foundation, local-first
inference, provider flexibility, secure configuration, and reproducible
development workflows.

## Disclaimer

This is an actively developed personal project. Features, configuration,
model identifiers, and API behaviour may change as development
continues.
