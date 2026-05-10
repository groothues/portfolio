# Validation — Phase 1: Portfolio CRUD

## Merge criteria

All of the following must be true before this branch is merged to `main`.

---

## 1. Tests pass

```bash
./mvnw test
```

- Exit code 0, zero test failures.
- All three new test classes execute and pass:
  - `PortfolioServiceTest`
  - `PortfolioRestControllerTest`
  - `PortfolioPageControllerTest`
- The pre-existing `PortfolioApplicationTests.contextLoads()` still passes (Spring context wires the new beans).

---

## 2. Migration applies cleanly on a fresh database

```bash
docker compose down -v
docker compose up -d db
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

- [ ] Flyway logs show `V1__create_portfolio` applied.
- [ ] Application starts without `ddl-auto: validate` errors.
- [ ] `psql` against the `db` container shows the `portfolio` table with the columns and unique constraint listed in `plan.md` §1.1.

---

## 3. List + create flow works in the browser

Navigate to `http://localhost:8080/portfolios`.

- [ ] Page renders with the shared layout (nav, footer) and an empty rows table plus a create form.
- [ ] Submit `name = "Demo Portfolio"`, `baseCurrency = "EUR"`.
- [ ] A new row appears at the bottom of the table **without a full page reload**.
- [ ] DevTools → Network → the `POST /portfolios` response body is just the `<tr>` fragment, not a full HTML document.
- [ ] The form inputs are cleared after the successful submit.

---

## 4. Validation feedback is visible without a reload

- [ ] Submitting blank `name` returns the `_form.html` fragment with a field error and inserts no row.
- [ ] Submitting `baseCurrency = "eur"` (lowercase) returns the form fragment with a pattern-mismatch error and inserts no row.
- [ ] Submitting `baseCurrency = "EU"` (too short) likewise fails with a visible error.

---

## 5. Detail page works

- [ ] Clicking a row's name on `/portfolios` navigates to `/portfolios/{uuid}` and renders the detail page (name, base currency, timestamps).
- [ ] `GET /portfolios/00000000-0000-0000-0000-000000000000` (a syntactically valid but non-existent UUID) returns HTTP 404.
- [ ] `GET /portfolios/not-a-uuid` returns HTTP 400 (Spring's UUID converter rejects malformed input).

---

## 6. REST API works

```bash
curl -s http://localhost:8080/api/portfolios
# → JSON array

curl -i -X POST -H "Content-Type: application/json" \
  -d '{"name":"Api Portfolio","baseCurrency":"USD"}' \
  http://localhost:8080/api/portfolios
# → 201, Location: /api/portfolios/{id}, JSON body

curl -i http://localhost:8080/api/portfolios/{uuid}                                 # 200 + body
curl -i http://localhost:8080/api/portfolios/00000000-0000-0000-0000-000000000000   # 404

curl -i -X POST -H "Content-Type: application/json" \
  -d '{"name":"","baseCurrency":"eur"}' \
  http://localhost:8080/api/portfolios
# → 400 with field error details
```

- [ ] Each curl above returns the indicated status code.
- [ ] Duplicate-name POST surfaces a clear error (409 or 400 — implementation choice, but no opaque 500).

---

## 7. Layer rule holds

```bash
grep -R "PortfolioEntity" src/main/java/de/groothues/portfolio/api \
                          src/main/java/de/groothues/portfolio/ui \
                          src/main/resources/templates
```

- [ ] No matches. `PortfolioEntity` is referenced only inside `persistence/` and `domain/`.

---

## Out of scope for this phase

The following are **not** required for merge and must not block it:

- Editing, renaming, or deleting portfolios (deferred).
- `CurrencyCode` enum or currency dropdown (Phase 2).
- Positions, transactions, valuation on the detail page (Phases 3, 4, 7).
- Pagination, search, or sortable columns on the list.
- Custom REST error advice beyond Spring's default validation handling.
