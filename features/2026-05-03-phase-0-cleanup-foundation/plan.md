# Plan — Phase 0: Cleanup & Shared Foundation

## Group 1 — Code cleanup

**1.1** Move `HomePageController.java`
- From: `src/main/java/de/groothues/portfolio/api/page/HomePageController.java`
- To: `src/main/java/de/groothues/portfolio/ui/controller/HomePageController.java`
- Update package declaration to `de.groothues.portfolio.ui.controller`
- Delete the now-empty `api/page/` directory

**1.2** Update `CLAUDE.md` package layout section
- Replace old layout (`api/page/`, `api/rest/`, `application/`) with the SKILL.md structure:
  `ui/controller`, `api/controllers`, `api/model`, `api/error`, `domain/service`, `domain/model`,
  `persistence/repository`, `persistence/entity`, `config`, `support`

---

## Group 2 — Shared layout & static assets

**2.1** Create `src/main/resources/templates/layout/main.html`
- Full HTML5 skeleton using `th:replace` for `head` and `nav` fragments
- `<main>` content slot via `th:replace` or layout dialect
- Footer with app name placeholder

**2.2** Create `src/main/resources/templates/layout/fragments.html`
- `head` fragment: charset, viewport, Pico CSS `<link>`, `app.css` `<link>`, title slot
- `nav` fragment: application name + links for Dashboard, Portfolios, Instruments, Transactions (placeholders)
- `flash-messages` fragment: renders `successMessage` and `errorMessage` model attributes if present

**2.3** Download and vendor HTMX
- Download `htmx.min.js` (latest stable 2.x) to `src/main/resources/static/vendor/htmx/htmx.min.js`
- Reference it in the `head` fragment via `th:src="@{/vendor/htmx/htmx.min.js}"`

**2.4** Add `src/main/resources/static/css/app.css`
- Import or link Pico CSS (vendored or via `<link>` in fragment — CDN acceptable at this stage since Pico is a dev convenience, not an API key)
- Minimal custom properties: primary color, nav height, max content width

**2.5** Update `src/main/resources/templates/home.html`
- Replace bare HTML with a page that extends `layout/main.html`
- Body content: heading "Portfolio Tracker" and a short welcome message

---

## Group 3 — Smoke test

**3.1** Start the database
```bash
docker compose up -d db
```

**3.2** Start the application
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

**3.3** Run the test suite
```bash
./mvnw test
```

**3.4** Verify in browser
- Open `http://localhost:8080`
- Confirm: page renders with nav bar, Pico CSS styles visible, no console errors
- Confirm: browser DevTools Network shows `htmx.min.js` loaded from `/vendor/htmx/` (not a CDN)
