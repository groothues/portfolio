# Portfolio

Private web-based portfolio tracker for a single user with support for a few portfolios, international stocks and ETFs.

## Tech stack

- Spring Boot backend
- Thymeleaf + HTMX UI (MVP)
- PostgreSQL database
- Flyway migrations
- Docker / Docker Compose

## Project structure

The **project root** is also the **Spring Boot source root**.

```text
portfolio/
├── Dockerfile
├── pom.xml
├── mvnw
├── mvnw.cmd
├── docker-compose.yaml
├── src/
│   ├── main/
│   │   ├── java/de/groothues/portfolio/
│   │   └── resources/
│   └── test/
└── README.md
```

## Root package

All Java classes use this base package:

```text
de.groothues.portfolio
```

## Profiles

The application supports these Spring profiles:

- `local` → backend runs locally, database runs in Docker or locally on the host
- `docker` → backend runs inside Docker Compose

By default, the application can be configured to use profile `local`.

## Prerequisites

- Java 21+
- Maven or Maven Wrapper (`./mvnw`)
- Docker Desktop on macOS
- Docker Compose

## Configuration

### Local profile database settings

The `local` profile expects PostgreSQL at:

- host: `localhost`
- port: `5432`
- database: `portfolio`
- username: `portfolio`
- password: `portfolio`

### Docker profile database settings

The `docker` profile expects PostgreSQL at:

- host: `db`
- port: `5432`
- database: `portfolio`
- username: `portfolio`
- password: `portfolio`

### Optional API key

Create a `.env` file next to `docker-compose.yaml` if you want to provide a market-data API key:

```env
TWELVE_DATA_API_KEY=your_api_key_here
```

---

# Start options

## Option 1: Start only the database and run backend locally

This is the recommended setup for development.

### Start only the database

```bash
docker compose up -d db
```

### Start the backend locally with the `local` profile

From the project root:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

### Alternative: start the backend JAR locally

Build first:

```bash
./mvnw clean package
```

Then run:

```bash
java -jar target/portfolio.jar --spring.profiles.active=local
```

If your final artifact name differs, replace `target/portfolio.jar` with the actual JAR file name from `target/`.

---

## Option 2: Start the complete application with Docker Compose

This starts:

- PostgreSQL database container
- Spring Boot backend container

```bash
docker compose up -d --build
```

This uses the `docker` Spring profile for the backend container.

---

## Option 3: Start the application in the foreground

Useful when you want to see logs directly in the terminal.

```bash
docker compose up --build
```

Stop with `Ctrl+C`.

---

# Stop options

## Stop only the database

```bash
docker compose stop db
```

## Stop only the backend

```bash
docker compose stop backend
```

## Stop the complete application

```bash
docker compose down
```

## Stop the database and delete the volume

This removes the PostgreSQL data volume and therefore deletes all persisted database data.

```bash
docker compose down -v
```

If only the `db` container is running, this still removes the attached named volumes for the compose project.

---

# Restart options

## Restart only the database

```bash
docker compose restart db
```

## Restart only the backend

```bash
docker compose restart backend
```

## Restart the complete application

```bash
docker compose restart
```

---

# Logs

## Show all logs

```bash
docker compose logs -f
```

## Show database logs

```bash
docker compose logs -f db
```

## Show backend logs

```bash
docker compose logs -f backend
```

## Show the last 100 log lines for the backend

```bash
docker compose logs --tail=100 backend
```

## Show the last 100 log lines for the database

```bash
docker compose logs --tail=100 db
```

---

# Status and inspection

## Show running containers

```bash
docker compose ps
```

## Show all Docker containers on the machine

```bash
docker ps -a
```

## Check if PostgreSQL is ready

```bash
docker compose exec db pg_isready -U portfolio -d portfolio
```

## Open a shell inside the backend container

```bash
docker compose exec backend sh
```

## Open a PostgreSQL shell inside the database container

```bash
docker compose exec db psql -U portfolio -d portfolio
```

---

# Build commands

## Build the backend locally

```bash
./mvnw clean package
```

## Rebuild and restart the full Docker setup

```bash
docker compose up -d --build
```

## Rebuild only the backend image

```bash
docker compose build backend
```

---

# Typical development workflows

## Workflow A: local backend + Docker database

1. Start database:

   ```bash
   docker compose up -d db
   ```

2. Start backend locally:

   ```bash
   ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
   ```

3. Stop database when finished:

   ```bash
   docker compose stop db
   ```

## Workflow B: everything in Docker

1. Start everything:

   ```bash
   docker compose up -d --build
   ```

2. Show backend logs:

   ```bash
   docker compose logs -f backend
   ```

3. Stop everything:

   ```bash
   docker compose down
   ```

## Workflow C: full reset of database state

Use this if you want a clean database.

```bash
docker compose down -v
docker compose up -d --build
```

---

# Application URLs

## When backend runs locally

- Application: `http://localhost:8080`
- Health endpoint: `http://localhost:8080/api/health`

## When backend runs in Docker

- Application: `http://localhost:8080`
- Health endpoint: `http://localhost:8080/api/health`

---

# Troubleshooting

## The backend cannot connect to the database

Check:

- database container is running
- port `5432` is free
- correct profile is active
- database credentials match the profile configuration

Useful commands:

```bash
docker compose ps
docker compose logs -f db
```

## Flyway migration fails

Check backend logs:

```bash
docker compose logs -f backend
```

If you want a fresh database:

```bash
docker compose down -v
docker compose up -d --build
```

## Port 8080 or 5432 is already in use

Check which process or container already uses the port and stop it.

---

# Useful command summary

## Start only DB

```bash
docker compose up -d db
```

## Start full application

```bash
docker compose up -d --build
```

## Start full application in foreground

```bash
docker compose up --build
```

## Stop only DB

```bash
docker compose stop db
```

## Stop all

```bash
docker compose down
```

## Stop all and delete DB volume

```bash
docker compose down -v
```

## Show all logs

```bash
docker compose logs -f
```

## Show DB logs

```bash
docker compose logs -f db
```

## Show backend logs

```bash
docker compose logs -f backend
```
