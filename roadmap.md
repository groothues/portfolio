# Portfolio Application — Implementation Roadmap

Each phase is a vertical feature slice: Flyway migration → JPA entity → domain model → service → controller → template → tests. No phase ends without passing tests and a working browser flow.

**Package layout:** follows the SKILL.md standard (`ui/controller`, `api/controllers`, `domain/service`, `domain/model`, `persistence/repository`, `persistence/entity`).

**Layer rule enforced throughout:** `api / ui → domain → persistence`. No entity reaches a template or API response; no persistence class imports from domain.

---

## Phase 0 — Cleanup & Shared Foundation

> One-time alignment before feature work starts.

- [ ] Move `HomePageController` from `api/page/` → `ui/controller/`
- [ ] Update `CLAUDE.md` package layout section to match SKILL.md
- [ ] Create `templates/layout/main.html` (base page layout)
- [ ] Create `templates/layout/fragments.html` (head, nav, flash messages)
- [ ] Vendor `htmx.min.js` → `static/vendor/htmx/htmx.min.js`
- [ ] Add `static/css/app.css` (minimal skeleton styles)
- [ ] Verify: `docker compose up -d db` + `./mvnw spring-boot:run` starts cleanly

---

## Phase 1 — Portfolio CRUD

> Create, view, and list portfolios.

**New files**
- `db/migration/V1__create_portfolio.sql`
- `persistence/entity/PortfolioEntity.java`
- `persistence/repository/PortfolioRepository.java`
- `domain/model/Portfolio.java` — `Portfolio.from(PortfolioEntity)`
- `domain/service/PortfolioService.java`
- `api/model/CreatePortfolioRequest.java` — `toDomainModel()`
- `api/model/PortfolioResponse.java` — `PortfolioResponse.from(Portfolio)`
- `api/controllers/PortfolioRestController.java`
- `ui/models/PortfolioForm.java` — `toDomainModel()`
- `ui/models/PortfolioRowView.java` — `PortfolioRowView.from(Portfolio)`
- `ui/controller/PortfolioPageController.java`
- `templates/portfolios/list.html`, `detail.html`, `_form.html`

**Tests**
- `PortfolioServiceTest` — create, list, get by id
- `PortfolioPageControllerTest` — `@WebMvcTest` list and detail pages
- `PortfolioRestControllerTest` — `@WebMvcTest` REST endpoints

---

## Phase 2 — Instrument Master Data

> Register stocks and ETFs that can appear in a portfolio.

**New files**
- `domain/model/AssetType.java` (STOCK, ETF, CRYPTO, BOND)
- `domain/model/CurrencyCode.java` (EUR, USD, GBP, …)
- `db/migration/V2__create_instrument.sql`
- `persistence/entity/InstrumentEntity.java`
- `persistence/repository/InstrumentRepository.java`
- `domain/model/Instrument.java` — `Instrument.from(InstrumentEntity)`
- `domain/service/InstrumentService.java`
- `api/model/CreateInstrumentRequest.java`, `InstrumentResponse.java`
- `api/controllers/InstrumentRestController.java` (search by ticker/ISIN, create)
- `ui/models/InstrumentForm.java`, `InstrumentRowView.java`
- `ui/controller/InstrumentPageController.java`
- `templates/instruments/list.html`, `_row.html`, `_form.html`

**Tests**
- `InstrumentServiceTest`
- `InstrumentRestControllerTest`
- `InstrumentPageControllerTest`

---

## Phase 3 — Transaction Recording

> Record buy, sell, and dividend transactions against a portfolio position.

**New files**
- `domain/model/TransactionType.java` (BUY, SELL, DIVIDEND, SPLIT)
- `db/migration/V3__create_transaction.sql`
- `persistence/entity/TransactionEntity.java`
- `persistence/repository/TransactionRepository.java`
- `domain/model/Transaction.java` — `Transaction.from(TransactionEntity)`
- `domain/service/TransactionService.java`
- `api/model/CreateTransactionRequest.java`, `TransactionResponse.java`
- `api/controllers/TransactionRestController.java`
- `ui/models/TransactionForm.java`, `TransactionRowView.java`
- `ui/controller/TransactionPageController.java`
- `templates/transactions/list.html`, `_table.html`, `_form.html`

**Tests**
- `TransactionServiceTest`
- `TransactionRestControllerTest`
- `TransactionPageControllerTest`

---

## Phase 4 — Position & Gain/Loss Calculation

> Pure domain logic — derive open positions and cost basis from transaction history.

**New files**
- `domain/model/Position.java` (value type: instrument, quantity, average cost)
- `domain/calculation/PositionCalculator.java`
- `domain/calculation/GainLossCalculator.java`

**Changes**
- `PortfolioService` — add position computation from transactions
- `templates/portfolios/detail.html` — add positions table

**Tests**
- `PositionCalculatorTest` — average cost, open quantity edge cases
- `GainLossCalculatorTest` — realised and unrealised gain/loss
- Update `PortfolioPageControllerTest` for positions in detail view

---

## Phase 5 — Market Price Import

> Fetch and store daily closing prices via TwelveData.

**New files**
- `pom.xml` — add HTTP client dependency (Spring `RestClient`)
- `domain/model/PriceSource.java` (TWELVE_DATA, MANUAL)
- `db/migration/V4__create_price_history.sql`
- `persistence/entity/PriceHistoryEntity.java`
- `persistence/repository/PriceHistoryRepository.java`
- `domain/model/PriceHistory.java` — `PriceHistory.from(PriceHistoryEntity)`
- `config/MarketDataProperties.java` (API key, base URL, timeout)
- `integration/marketdata/MarketDataClient.java` (interface)
- `integration/marketdata/TwelveDataClient.java`
- `domain/service/PriceImportService.java`
- `api/controllers/PriceImportRestController.java` (manual trigger)

**Tests**
- `TwelveDataClientTest` — mock HTTP responses
- `PriceImportServiceTest` — unit test with mock client

---

## Phase 6 — Exchange Rates

> Fetch and store daily FX rates to support multi-currency portfolios.

**New files**
- `db/migration/V5__create_exchange_rate.sql`
- `persistence/entity/ExchangeRateEntity.java`
- `persistence/repository/ExchangeRateRepository.java`
- `domain/model/ExchangeRate.java` — `ExchangeRate.from(ExchangeRateEntity)`
- `integration/marketdata/ExchangeRateClient.java`
- `domain/service/ExchangeRateService.java`
- `support/MoneyUtils.java` (currency conversion helpers)

**Tests**
- `ExchangeRateClientTest`
- `ExchangeRateServiceTest`
- `MoneyUtilsTest`

---

## Phase 7 — Valuation & Dashboard

> Show current market value, unrealised P&L, and a top-level dashboard.

**New files**
- `domain/service/ValuationService.java`
- `api/model/ValuationResponse.java` — `ValuationResponse.from(…)`
- `api/controllers/ValuationRestController.java`
- `ui/models/PortfolioValuationView.java`
- `domain/service/DashboardService.java`
- `ui/models/DashboardView.java`
- `ui/controller/DashboardPageController.java`
- `templates/dashboard/index.html`

**Changes**
- `templates/portfolios/detail.html` — add current value + P&L columns

**Tests**
- `ValuationServiceTest` — mocked prices and rates
- `DashboardServiceTest`
- `DashboardPageControllerTest` — `@WebMvcTest`

---

## Phase 8 — Scheduled Jobs

> Automate daily price and exchange-rate imports.

**New files**
- `config/SchedulerConfig.java`
- `integration/marketdata/DailyPriceImportJob.java`
- `integration/marketdata/DailyExchangeRateImportJob.java`

**Changes**
- `application-docker.yaml` — set `app.scheduling.enabled: true`

**Tests**
- Integration test: trigger job bean directly, assert rows inserted (Testcontainers)

---

## Phase 9 — Containerization & Production Polish

> Package and ship the full application as a Docker Compose stack.

**New files**
- `Dockerfile` (multi-stage: Maven build → JRE runtime)
- `docker-compose.yml` — backend + db services
- `.env.example` — `TWELVE_DATA_API_KEY`, DB credentials

**Changes**
- `application-docker.yaml` — `spring.thymeleaf.cache: true`, production log levels

**Verification**
```bash
docker compose up -d --build
curl http://localhost:8080/api/health
# open http://localhost:8080 — dashboard renders with live data
```

---

## Completion criteria (every phase)

1. `./mvnw test` passes with no failures.
2. `./mvnw spring-boot:run` starts and the feature is reachable in the browser.
3. No JPA entity or persistence class is visible in any template or API response.
