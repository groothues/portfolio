# Requirements — Phase 1: Portfolio CRUD

## Context

Phase 0 left the project with the SKILL.md package layout, a shared Thymeleaf layout (`templates/layout/main.html` + `fragments.html`), vendored HTMX, and Pico CSS — but no domain features yet. There are **no Flyway migrations** and **no JPA entities**, while `spring.jpa.hibernate.ddl-auto = validate` is in effect, so the application currently has nothing to validate against.

Phase 1 is the first vertical feature slice. It introduces the **Portfolio** aggregate end-to-end: Flyway migration → JPA entity → domain model → service → REST + page controllers → Thymeleaf templates → tests. Once merged, the user can create portfolios in the browser via an HTMX-driven form, list them, and open a detail page for each.

## Scope

### In scope

- **Flyway migration** `V1__create_portfolio.sql` creating the `portfolio` table.
- **Persistence**: `PortfolioEntity`, `PortfolioRepository` (`findAllByOrderByNameAsc`).
- **Domain model**: `Portfolio` record with `Portfolio.from(PortfolioEntity)`.
- **Service**: `PortfolioService` exposing `create(name, baseCurrency)`, `listAll()`, `findById(id)`.
- **REST API**: `PortfolioRestController` with `GET /api/portfolios`, `POST /api/portfolios`, `GET /api/portfolios/{id}`. DTOs: `CreatePortfolioRequest`, `PortfolioResponse`.
- **UI**: `PortfolioPageController` with `GET /portfolios`, `POST /portfolios`, `GET /portfolios/{id}`. View models: `PortfolioForm`, `PortfolioRowView`. Templates: `list.html`, `_row.html`, `_form.html`, `detail.html` under `templates/portfolios/`.
- **HTMX inline create**: form posts return only the new `_row.html` fragment; on validation error the controller returns the `_form.html` fragment with field errors. No full page reload on success.
- **Tests**: `PortfolioServiceTest`, `PortfolioRestControllerTest` (`@WebMvcTest`), `PortfolioPageControllerTest` (`@WebMvcTest`).

### Out of scope

- **Rename / edit / delete** portfolios — deferred (architecture §7.1 lists them, but the roadmap explicitly scopes Phase 1 to "create, view, list").
- **`CurrencyCode` enum** — arrives with instruments in Phase 2. `baseCurrency` is stored as a 3-character string for now.
- **Positions, transactions, valuation** on the detail page — Phases 3, 4, 7.
- **Pagination, search, sort UI** on the list — single-user app with few portfolios.
- **REST error advice (`@RestControllerAdvice`)** beyond Spring's default validation handling — adopted in a later phase if needed.
- **Authentication / multi-user** — out of MVP per architecture §23.

## Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| CRUD operations in this phase | Create + List + Detail only | Matches roadmap heading and file list; rename/delete deferred to keep the slice tight |
| Base-currency input | Free 3-letter string, regex `^[A-Z]{3}$` | Avoids pulling Phase 2's `CurrencyCode` enum forward; column can be reinterpreted as enum-backed string later |
| HTMX integration style | Inline — `POST /portfolios` returns `_row.html`, swapped `beforeend` into `#portfolio-rows` | Establishes the HTMX pattern from day one without a full-page redirect |
| Validation-error UX | On 400 in HTMX POST, return `_form.html` fragment with field errors targeting the form container | Single round-trip; user sees errors next to fields without losing context |
| Form reset after success | `hx-on::after-request="if(event.detail.successful) this.reset()"` on the form | No server-side gymnastics; client clears inputs only on success |
| ID type | `UUID` (Postgres `uuid` column, default `gen_random_uuid()`; Java `java.util.UUID`) | Opaque, non-guessable IDs; safe to expose in URLs and APIs without leaking row counts. Establishes the convention for every entity to come |
| Name uniqueness | `UNIQUE` constraint on `portfolio.name` | Single-user app — duplicate names are almost certainly a mistake. Service surfaces `DataIntegrityViolationException` as a 409/flash error |
| Timestamp handling | `created_at`, `updated_at` as `TIMESTAMPTZ NOT NULL DEFAULT NOW()`; entity sets them via `@PrePersist` / `@PreUpdate` | Matches architecture §10.1; avoids relying on DB defaults alone for round-trip consistency |
| Validation constraints | `name`: `@NotBlank @Size(max=100)`. `baseCurrency`: `@NotBlank @Pattern("^[A-Z]{3}$")` | Same constraints on `CreatePortfolioRequest` (REST) and `PortfolioForm` (UI) so behaviour matches across surfaces |
| Mapping convention | `Portfolio.from(PortfolioEntity)`; `PortfolioResponse.from(Portfolio)`; `PortfolioRowView.from(Portfolio)`; `CreatePortfolioRequest.toDomainModel()` (or pass fields straight to `service.create(...)`) | Per CLAUDE.md cross-layer mapping rule |
| Layer rule | No `PortfolioEntity` reference in `api/`, `ui/`, or any template | Per CLAUDE.md; verified by grep in validation step 7 |

## Reference

- `roadmap.md` — Phase 1 file list (lines 25–47).
- `architecture.md` §7.1 — portfolio management scope.
- `architecture.md` §10.1 — portfolio domain attributes.
- `architecture.md` §11 — `portfolio` table columns.
- `CLAUDE.md` — package layout, layer rule, profiles, `ddl-auto: validate` policy.
- `features/2026-05-03-phase-0-cleanup-foundation/` — structural template for these spec docs and the layout/fragment hooks new templates plug into.
