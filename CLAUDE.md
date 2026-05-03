# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- Java 21, Spring Boot 4.0.5
- Thymeleaf + HTMX (server-side rendered, no SPA)
- PostgreSQL 17 via Docker, Flyway migrations, Spring Data JPA
- Maven Wrapper (`./mvnw`)

## Commands

```bash
# Start DB only (then run backend locally)
docker compose up -d db

# Run backend (local profile: localhost:5432/portfolio)
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# Run everything in Docker
docker compose up -d --build

# Tests
./mvnw test

# Build JAR
./mvnw clean package
```

App: `http://localhost:8080` — Health: `http://localhost:8080/api/health`

Optional: create `.env` with `TWELVE_DATA_API_KEY=<key>` for market data.

## Architecture

Base package: `de.groothues.portfolio`

Planned package layout (mostly unimplemented — see `architecture.md` for the full design):

```
api/page/          ← Thymeleaf page controllers
api/rest/          ← REST controllers
application/       ← services (PortfolioService, TransactionService, …)
domain/model/      ← enums and value types (AssetType, TransactionType, …)
domain/calculation/← calculators
integration/marketdata/ ← TwelveData and exchange-rate clients
persistence/entity/     ← JPA entities
persistence/repository/ ← Spring Data repositories
config/            ← MarketDataProperties, CacheConfig, SchedulerConfig
support/           ← utilities
```

The project is in skeleton phase. Only `HomePageController` and its template exist; no entities, migrations, services, or integration code have been written yet.

## Spring Profiles

| Profile | DB host | Use case |
|---------|---------|----------|
| `local` | `localhost:5432` | Backend on host, DB in Docker |
| `docker` | env vars (`SPRING_DATASOURCE_*`) | Full Docker Compose |

Default profile in `application.yaml` is `local`. JPA DDL is set to `validate` — all schema changes go through Flyway migrations in `src/main/resources/db/migration/`.
