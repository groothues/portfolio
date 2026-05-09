# Validation — Phase 0: Cleanup & Shared Foundation

## Merge criteria

All of the following must be true before this branch is merged to `main`.

---

## 1. Tests pass

```bash
./mvnw test
```

- Exit code 0, zero test failures.
- The existing `PortfolioApplicationTests.contextLoads()` test passes (confirms Spring context wires up with the moved controller).

---

## 2. Home page renders with shared layout

Open `http://localhost:8080` in a browser.

- [ ] Page title is set (not blank).
- [ ] Navigation bar is visible with links: Dashboard, Portfolios, Instruments, Transactions.
- [ ] Pico CSS styles are applied — body has default font, nav has a distinguishable background or border.
- [ ] Content area shows "Portfolio Tracker" heading and welcome text from `home.html`.
- [ ] No Thymeleaf error page (`Whitelabel Error Page` or stack trace) is shown.

---

## 3. No regressions from the package move

- [ ] `HomePageController` compiles from `de.groothues.portfolio.ui.controller` with no errors.
- [ ] No references to `de.groothues.portfolio.api.page` remain anywhere in the source tree.
- [ ] `GET /` returns HTTP 200.

---

## Out of scope for this phase

The following are **not** required for merge and must not block it:

- Navigation links resolve to real pages (they are placeholders).
- Any HTMX interaction works (HTMX is vendored but not yet used).
- Any database-backed feature.
