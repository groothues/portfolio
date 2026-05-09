# Plan — Phase 1: Portfolio CRUD

## Group 1 — Migration & persistence

**1.1** Create `src/main/resources/db/migration/V1__create_portfolio.sql`
- Columns:
  - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
  - `name VARCHAR(100) NOT NULL`
  - `base_currency CHAR(3) NOT NULL`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- Constraints:
  - `CONSTRAINT portfolio_name_unique UNIQUE (name)`
  - `CONSTRAINT portfolio_base_currency_format CHECK (base_currency ~ '^[A-Z]{3}$')`
- Note: `gen_random_uuid()` is built into PostgreSQL 13+ (no `uuid-ossp` extension needed); the project runs on PostgreSQL 17.

**1.2** Create `src/main/java/de/groothues/portfolio/persistence/entity/PortfolioEntity.java`
- `@Entity @Table(name = "portfolio")`
- Fields: `UUID id`, `String name`, `String baseCurrency`, `Instant createdAt`, `Instant updatedAt`
- `@Id @GeneratedValue(strategy = GenerationType.UUID)` (Hibernate generates the UUID client-side; the DB column default is a safety net for inserts that bypass JPA)
- `@PrePersist` sets `createdAt = updatedAt = Instant.now()` if null
- `@PreUpdate` sets `updatedAt = Instant.now()`
- Standard JavaBean accessors (no Lombok unless already present in project)

**1.3** Create `src/main/java/de/groothues/portfolio/persistence/repository/PortfolioRepository.java`
- `extends JpaRepository<PortfolioEntity, UUID>`
- `List<PortfolioEntity> findAllByOrderByNameAsc()`

---

## Group 2 — Domain layer

**2.1** Create `src/main/java/de/groothues/portfolio/domain/model/Portfolio.java`
- `public record Portfolio(UUID id, String name, String baseCurrency, Instant createdAt, Instant updatedAt)`
- `public static Portfolio from(PortfolioEntity entity)` — null-safe factory

**2.2** Create `src/main/java/de/groothues/portfolio/domain/service/PortfolioService.java`
- `@Service`, constructor-injected `PortfolioRepository`
- `@Transactional public Portfolio create(String name, String baseCurrency)` — builds entity, saves, returns `Portfolio.from(...)`
- `@Transactional(readOnly = true) public List<Portfolio> listAll()` — uses `findAllByOrderByNameAsc()`
- `@Transactional(readOnly = true) public Optional<Portfolio> findById(UUID id)`

---

## Group 3 — REST API

**3.1** Create `src/main/java/de/groothues/portfolio/api/model/CreatePortfolioRequest.java`
- `public record CreatePortfolioRequest(@NotBlank @Size(max = 100) String name, @NotBlank @Pattern(regexp = "^[A-Z]{3}$") String baseCurrency)`

**3.2** Create `src/main/java/de/groothues/portfolio/api/model/PortfolioResponse.java`
- `public record PortfolioResponse(UUID id, String name, String baseCurrency, Instant createdAt, Instant updatedAt)`
- `public static PortfolioResponse from(Portfolio portfolio)`

**3.3** Create `src/main/java/de/groothues/portfolio/api/controllers/PortfolioRestController.java`
- `@RestController @RequestMapping("/api/portfolios")`
- `GET ""` → `200` + `List<PortfolioResponse>`
- `POST ""` → `201` + `Location: /api/portfolios/{id}` + `PortfolioResponse` body
- `GET "/{id}"` → `200` with body or `404` if absent. `@PathVariable UUID id` — Spring binds the path segment via the built-in `UUID` converter; malformed UUIDs surface as `400`
- Validation errors surface as Spring's default `400` (no custom advice yet)

---

## Group 4 — UI layer (HTMX inline)

**4.1** Create `src/main/java/de/groothues/portfolio/ui/models/PortfolioForm.java`
- Bean (or record) with `String name`, `String baseCurrency`
- Same validation annotations as `CreatePortfolioRequest`

**4.2** Create `src/main/java/de/groothues/portfolio/ui/models/PortfolioRowView.java`
- `public record PortfolioRowView(UUID id, String name, String baseCurrency, String createdAtDisplay)`
- `public static PortfolioRowView from(Portfolio portfolio)` — formats `createdAt` for the table cell

**4.3** Create `src/main/java/de/groothues/portfolio/ui/controller/PortfolioPageController.java`
- `@Controller`, constructor-injected `PortfolioService`
- `GET /portfolios` → `portfolios/list` with `rows` (`List<PortfolioRowView>`) and empty `portfolioForm`
- `POST /portfolios` (consumes `application/x-www-form-urlencoded`)
  - Bind `@Valid PortfolioForm` + `BindingResult`
  - On errors: render `portfolios/_form :: form` (HTTP 422 or 400)
  - On success: call service, return `portfolios/_row :: row` with `row` model attribute
- `GET /portfolios/{id}` → `portfolios/detail` with `portfolio` model attribute, or `ResponseStatusException(NOT_FOUND)` if absent. `@PathVariable UUID id` (Spring's built-in converter parses the path segment)

**4.4** Create `src/main/resources/templates/portfolios/list.html`
- Extends `layout/main`
- Page title "Portfolios"
- `<table>` with `<tbody id="portfolio-rows">` rendering each row via `<th:block th:replace="~{portfolios/_row :: row(row=${row})}">`
- Below the table, the create form via `<th:block th:replace="~{portfolios/_form :: form}">`

**4.5** Create `src/main/resources/templates/portfolios/_row.html`
- `th:fragment="row(row)"` rendering one `<tr>` with id, name (link to detail), currency, created-at

**4.6** Create `src/main/resources/templates/portfolios/_form.html`
- `th:fragment="form"`
- `<form>` with `hx-post="/portfolios"`, `hx-target="#portfolio-rows"`, `hx-swap="beforeend"`, `hx-on::after-request="if(event.detail.successful) this.reset()"`
- Fields for `name`, `baseCurrency` with `th:errors` blocks
- Submit button

**4.7** Create `src/main/resources/templates/portfolios/detail.html`
- Extends `layout/main`
- Heading uses portfolio name
- Description list showing `id`, `baseCurrency`, `createdAt`, `updatedAt`
- "Back to portfolios" link

---

## Group 5 — Tests

**5.1** Create `src/test/java/de/groothues/portfolio/domain/service/PortfolioServiceTest.java`
- Plain JUnit + Mockito on `PortfolioRepository`
- `create_savesEntity_returnsDomainPortfolio()`
- `listAll_returnsPortfoliosOrderedByName()`
- `findById_present_returnsPortfolio()`
- `findById_absent_returnsEmptyOptional()`

**5.2** Create `src/test/java/de/groothues/portfolio/api/controllers/PortfolioRestControllerTest.java`
- `@WebMvcTest(PortfolioRestController.class)`, `@MockBean PortfolioService`
- `getAll_returnsJsonList()`
- `create_validBody_returns201WithLocation()`
- `create_blankName_returns400()`
- `create_invalidCurrency_returns400()`
- `getById_present_returns200()`
- `getById_absent_returns404()`

**5.3** Create `src/test/java/de/groothues/portfolio/ui/controller/PortfolioPageControllerTest.java`
- `@WebMvcTest(PortfolioPageController.class)`, `@MockBean PortfolioService`
- `getList_rendersListTemplate_withRows()`
- `post_validForm_returnsRowFragment()`
- `post_invalidForm_returnsFormFragmentWithErrors()`
- `getDetail_present_rendersDetailTemplate()`
- `getDetail_absent_returns404()`

---

## Group 6 — Smoke test

**6.1** `./mvnw test` — green.

**6.2** `docker compose down -v && docker compose up -d db` — fresh DB so Flyway runs from scratch.

**6.3** `./mvnw spring-boot:run -Dspring-boot.run.profiles=local` — starts cleanly with Flyway applying `V1` and JPA `validate` succeeding.

**6.4** Browser verification at `http://localhost:8080/portfolios`:
- List page renders (empty table + form).
- Submit `name="Demo Portfolio"`, `baseCurrency="EUR"` — row appears at the bottom of the table without full reload, form clears.
- Submit blank name — form fragment with error message renders, no row inserted.
- Click the row's name — detail page opens at `/portfolios/{id}`.
