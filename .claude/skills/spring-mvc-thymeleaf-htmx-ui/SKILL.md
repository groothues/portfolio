---
name: spring-mvc-thymeleaf-htmx-ui
description: Use this skill when designing, implementing, reviewing, or refactoring a server-rendered web UI in a Java 21 Spring Boot 4.x application using Spring MVC, Thymeleaf, HTMX, Spring Security, validation, and a relational database. Trigger for requests involving Thymeleaf templates, HTMX fragments, form handling, CSRF, MVC controllers, UI package structure, server-rendered CRUD screens, pagination, search/filter pages, or adding a web UI next to an existing REST API.
---

# Spring MVC + Thymeleaf + HTMX UI Skill

## Goal

Build maintainable, server-rendered web UIs for Spring Boot 4.x applications using:

- Java 21
- Spring Boot 4.x
- Spring MVC
- Thymeleaf
- HTMX
- Spring Security
- Bean Validation
- A relational database such as PostgreSQL
- Existing application/service/domain layers

Prefer simple server-rendered HTML and progressive enhancement over a SPA unless the user explicitly needs complex client-side state.

## Default Architecture

Use two separate HTTP surfaces:

```text
/api/v1/...   JSON REST API for external/system clients
/app/...      HTML web UI for browser users
```

Use separate controller types:

```java
@RestController
@RequestMapping("/api/v1/users")
class UserRestController {
    // JSON API
}
```

```java
@Controller
@RequestMapping("/app/users")
class UserPageController {
    // Thymeleaf pages and HTMX fragments
}
```

Never mix JSON API response contracts and browser-specific HTML behavior in the same controller unless the existing project structure clearly requires it.

## Core Rules

1. Keep REST controllers and UI controllers separate.
2. Return HTML fragments from HTMX endpoints, not JSON.
3. Keep controllers thin.
4. Reuse the domain service layer.
5. Use dedicated web form models and view models.
6. Do not expose JPA entities to Thymeleaf templates or API responses.
7. Keep search, filter, sort, and page state in URLs.
8. Keep CSRF enabled for browser-based UI flows.
9. Use HTMX for small interactions, not complex client-side state.
10. Make pages work without HTMX first, then enhance with HTMX.
11. Test rendered HTML and important HTMX flows with MockMvc.
12. Prefer boring, explicit URL paths and template names.
13. `persistence` must not import from `domain`, `api`, or `ui`.
14. `domain` must not import from `api` or `ui`.
15. Map across layer boundaries using factory methods: `request.toDomainModel()`, `Response.from(domainModel)`, `DomainModel.from(entity)`.

## Recommended Dependencies

For Maven, prefer Spring Boot-managed versions.

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf-test</artifactId>
        <scope>test</scope>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

For HTMX, prefer vendoring a pinned `htmx.min.js` into the application for production reproducibility:

```text
src/main/resources/static/vendor/htmx/htmx.min.js
```

Use a CDN only for prototypes or if the project already has a controlled frontend asset policy that allows CDN dependencies.

## Recommended Package Structure

For a medium-sized application:

```text
de.example.usermanagement
 ├─ api
 │   ├─ controllers
 │   │   └─ UserRestController.java
 │   ├─ model
 │   │   ├─ UserResponse.java
 │   │   └─ CreateUserRequest.java
 │   └─ error
 │       └─ RestExceptionHandler.java
 ├─ ui
 │   ├─ controller
 │   │   └─ UserPageController.java
 │   ├─ models
 │   │   ├─ UserForm.java
 │   │   ├─ UserSearchForm.java
 │   │   ├─ UserRowView.java
 │   │   └─ UserDetailView.java
 │   └─ error
 │       └─ WebExceptionHandler.java
 ├─ domain
 │   ├─ service
 │   │   └─ UserService.java
 │   ├─ model
 │   │   └─ User.java
 │   └─ error
 │       └─  UserNotFoundException.java
 ├─ persistence
 │   ├─ repository
 │   │   └─ JpaUserRepository.java
 │   └─ entity
 │       └─ UserEntity.java
 └─ config
     ├─ WebSecurityConfig.java
     └─ MvcConfig.java
```

Adapt names to the existing codebase, but keep these boundaries:

- `api/controllers`: JSON REST controllers
- `api/model`: REST request and response models
- `api/error`: REST error handling (`@RestControllerAdvice`, `ProblemDetail`)
- `ui/controller`: Thymeleaf page controllers and HTMX fragment endpoints
- `ui/models`: web form models, view models, search models
- `ui/error`: web exception handlers and UI-specific exceptions
- `domain/service`: use cases, transactions, orchestration
- `domain/model`: domain entities, value objects, domain rules
- `persistence/repository`: Spring Data repository interfaces and implementations
- `persistence/entity`: JPA entity classes
- `config`: security, MVC, Jackson, scheduling, caching, etc.

## Layer Isolation and Mapping

### Dependency Direction

```
api / ui  →  domain  →  persistence
```

- `api` and `ui` may import from `domain`. They must not import from `persistence`.
- `domain` may import from `persistence`. It must not import from `api` or `ui`.
- `persistence` must not import from `domain`, `api`, or `ui`.

### Mapping Conventions

Use factory methods directly on the model classes. No separate mapper classes unless the mapping is complex enough to justify it.

**API request → domain input** (`api` calls instance method, `domain` does not know about `api`):

```java
// api/model/UserCreationRequest.java
public record UserCreationRequest(
        @NotBlank String userName,
        @NotBlank @Email String email
) {
    public UserCreationInput toDomainModel() {
        return new UserCreationInput(userName, email);
    }
}
```

**Domain model → API response** (static factory on `api` model, `domain` stays clean):

```java
// api/model/UserResponse.java
public record UserResponse(UUID id, String userName, String email) {

    public static UserResponse from(User user) {
        return new UserResponse(user.id(), user.userName(), user.email());
    }
}
```

**Entity → domain model** (static factory on `domain` model; `persistence` does not know about `domain`):

```java
// domain/model/User.java
public record User(UUID id, String userName, String email) {

    public static User from(UserEntity entity) {
        return new User(entity.getId(), entity.getUserName(), entity.getEmail());
    }

    public UserEntity toEntity() {
        return new UserEntity(id, userName, email);
    }
}
```

**UI form → domain input** (same pattern as API request):

```java
// ui/models/UserForm.java
public class UserForm {

    @NotBlank
    private String userName;

    @NotBlank
    @Email
    private String email;

    public UserCreationInput toDomainModel() {
        return new UserCreationInput(userName, email);
    }

    // getters and setters
}
```

**Domain model → UI view model** (static factory on `ui` model):

```java
// ui/models/UserRowView.java
public record UserRowView(UUID id, String userName, String email, String statusLabel) {

    public static UserRowView from(User user) {
        return new UserRowView(
                user.id(),
                user.userName(),
                user.email(),
                user.active() ? "Active" : "Inactive"
        );
    }
}
```

### Typical Service Call in a Controller

```java
// api/controllers/UserRestController.java
@PostMapping
UserResponse createUser(@Valid @RequestBody UserCreationRequest request) {
    User user = userService.createUser(request.toDomainModel());
    return UserResponse.from(user);
}
```

```java
// domain/service/UserService.java
public User createUser(UserCreationInput input) {
    UserEntity entity = new UserEntity(input.userName(), input.email());
    return User.from(userRepository.save(entity));
}
```

The persistence layer (`UserEntity`, `JpaUserRepository`) never references any class from `domain`, `api`, or `ui`.

### Naming Conventions

| Layer | Suffix convention | Examples |
|-------|------------------|---------|
| `api/model` request | `Request` | `UserCreationRequest`, `UpdateUserRequest` |
| `api/model` response | `Response` | `UserResponse`, `UserListResponse` |
| `domain/model` input | `Input` | `UserCreationInput`, `UpdateUserInput` |
| `domain/model` | (none / noun) | `User`, `Portfolio`, `Transaction` |
| `ui/models` form | `Form` | `UserForm`, `TransactionForm` |
| `ui/models` view | `View` | `UserRowView`, `UserDetailView` |
| `persistence/entity` | `Entity` | `UserEntity`, `TransactionEntity` |

## Template Structure

Use small, reusable pages and fragments:

```text
src/main/resources/templates
 ├─ layout
 │   ├─ main.html
 │   ├─ fragments.html
 │   └─ messages.html
 ├─ users
 │   ├─ list.html
 │   ├─ _table.html
 │   ├─ _form.html
 │   ├─ _detail.html
 │   └─ detail.html
 └─ error
     ├─ 403.html
     ├─ 404.html
     └─ 500.html
```

Conventions:

- Full pages: `list.html`, `detail.html`, `edit.html`
- Partials/fragments: prefix with `_`, for example `_table.html`, `_form.html`
- Layout fragments: keep in `templates/layout`
- Error pages: keep in `templates/error`
- Prefer semantic HTML over div-heavy markup
- Keep fragments cohesive and small

## Page + Fragment Controller Pattern

Prefer one endpoint for the full page and one endpoint for the HTMX fragment.

```java
@Controller
@RequestMapping("/app/users")
class UserPageController {

    private final UserService userService;

    UserPageController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    String listPage(@ModelAttribute("search") UserSearchForm search, Model model) {
        model.addAttribute("users", userService.searchUsers(search));
        return "users/list";
    }

    @GetMapping("/table")
    String usersTable(@ModelAttribute("search") UserSearchForm search, Model model) {
        model.addAttribute("users", userService.searchUsers(search));
        return "users/_table :: usersTable";
    }
}
```

Use `HX-Request` branching only when separate endpoints would add unnecessary duplication:

```java
@GetMapping("/{id}/edit")
String editUser(
        @PathVariable UUID id,
        @RequestHeader(value = "HX-Request", required = false) String hxRequest,
        Model model
) {
    model.addAttribute("userForm", userService.getUserForm(id));

    if ("true".equals(hxRequest)) {
        return "users/_form :: userForm";
    }

    return "users/detail";
}
```

## View Models and Form Models

Do not pass JPA entities into templates.

Prefer immutable view models for output:

```java
public record UserRowView(
        UUID id,
        String userName,
        String email,
        String statusLabel,
        boolean active
) {}
```

Use mutable form models when Spring MVC binding is simpler:

```java
public class UserForm {

    @NotBlank
    private String userName;

    @NotBlank
    @Email
    private String email;

    private boolean active;

    // getters and setters
}
```

Use dedicated search/filter form models:

```java
public class UserSearchForm {

    private String q;
    private Integer page = 0;
    private Integer size = 25;

    // getters and setters
}
```

Keep UI formatting in the web layer or mapper, not in the JPA entity.

## Progressive Enhancement

First create a normal HTML form that works without JavaScript:

```html
<form method="get" th:action="@{/app/users}">
    <input type="search" name="q" th:value="${search.q}">
    <button type="submit">Search</button>
</form>
```

Then add HTMX attributes:

```html
<form
    method="get"
    th:action="@{/app/users}"
    hx-get="/app/users/table"
    hx-target="#users-table"
    hx-swap="outerHTML"
    hx-push-url="true">

    <input type="search" name="q" th:value="${search.q}">
    <button type="submit">Search</button>
</form>
```

Use `hx-push-url="true"` when the interaction represents navigable state such as search, filter, sort, or pagination.

## HTMX Usage Guidelines

Use HTMX for:

- Table filtering/search
- Pagination
- Inline validation
- Dependent dropdowns
- Replacing a form fragment after validation errors
- Replacing a table after create/update/delete
- Opening or replacing modal content
- Deleting a row
- Refreshing a notification/messages area

Avoid HTMX for:

- Complex client-side state
- Offline-capable UI
- Spreadsheet-like editing
- Heavy drag-and-drop interactions
- Complex visualizations
- Large UI flows that are effectively a SPA

When those are required, consider a dedicated frontend framework instead of stretching HTMX.

## Thymeleaf Fragment Example

Full page:

```html
<!doctype html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head th:replace="~{layout/fragments :: head('Users')}"></head>
<body>
<main>
    <h1>Users</h1>

    <form
        method="get"
        th:action="@{/app/users}"
        hx-get="/app/users/table"
        hx-target="#users-table"
        hx-swap="outerHTML"
        hx-push-url="true">

        <input type="search" name="q" th:value="${search.q}">
        <button type="submit">Search</button>
    </form>

    <section id="users-table" th:replace="~{users/_table :: usersTable(${users})}">
        User table fallback
    </section>
</main>

<script th:src="@{/vendor/htmx/htmx.min.js}"></script>
</body>
</html>
```

Fragment:

```html
<table id="users-table" th:fragment="usersTable(users)">
    <thead>
    <tr>
        <th>User name</th>
        <th>Email</th>
        <th>Status</th>
    </tr>
    </thead>
    <tbody>
    <tr th:each="user : ${users}">
        <td>
            <a th:href="@{/app/users/{id}(id=${user.id()})}"
               th:text="${user.userName()}">jdoe</a>
        </td>
        <td th:text="${user.email()}">jdoe@example.com</td>
        <td th:text="${user.statusLabel()}">Active</td>
    </tr>
    </tbody>
</table>
```

## Forms and Validation

Use normal Spring MVC form binding.

```java
@GetMapping("/new")
String newUserForm(Model model) {
    model.addAttribute("userForm", new UserForm());
    return "users/detail";
}

@PostMapping
String createUser(
        @Valid @ModelAttribute("userForm") UserForm form,
        BindingResult bindingResult,
        Model model,
        @RequestHeader(value = "HX-Request", required = false) String hxRequest
) {
    if (bindingResult.hasErrors()) {
        if ("true".equals(hxRequest)) {
            return "users/_form :: userForm";
        }
        return "users/detail";
    }

    userService.createUser(form);

    if ("true".equals(hxRequest)) {
        return "redirect:/app/users";
    }

    return "redirect:/app/users";
}
```

Form fragment:

```html
<form
    id="user-form"
    th:fragment="userForm"
    th:object="${userForm}"
    th:action="@{/app/users}"
    method="post"
    hx-post="/app/users"
    hx-target="#user-form"
    hx-swap="outerHTML">

    <div>
        <label for="userName">User name</label>
        <input id="userName" th:field="*{userName}">
        <p th:if="${#fields.hasErrors('userName')}"
           th:errors="*{userName}">User name error</p>
    </div>

    <div>
        <label for="email">Email</label>
        <input id="email" th:field="*{email}">
        <p th:if="${#fields.hasErrors('email')}"
           th:errors="*{email}">Email error</p>
    </div>

    <button type="submit">Save</button>
</form>
```

Always keep `BindingResult` immediately after the validated model attribute.

## Redirects and HTMX

For normal browser submissions:

```java
return "redirect:/app/users";
```

For HTMX submissions, use `HX-Redirect` when a real browser navigation is intended:

```java
@PostMapping
ResponseEntity<Void> createUserWithHtmx(@Valid @ModelAttribute UserForm form) {
    userService.createUser(form);

    return ResponseEntity
            .noContent()
            .header("HX-Redirect", "/app/users")
            .build();
}
```

Use fragment replacement instead when the user should stay on the same page:

```java
@PostMapping("/{id}")
String updateUser(
        @PathVariable UUID id,
        @Valid @ModelAttribute("userForm") UserForm form,
        BindingResult bindingResult,
        Model model
) {
    if (bindingResult.hasErrors()) {
        return "users/_form :: userForm";
    }

    model.addAttribute("user", userService.updateUser(id, form));
    return "users/_detail :: userDetail";
}
```

## CSRF with Spring Security and HTMX

Keep CSRF enabled for browser UIs.

Normal Thymeleaf forms with `th:action` and `method="post"` can include CSRF automatically when Spring Security and Thymeleaf integration are active.

For HTMX requests that use non-standard form flows or methods such as `hx-delete`, send the CSRF token as a header.

Include this once in the layout:

```html
<meta name="_csrf" th:content="${_csrf.token}">
<meta name="_csrf_header" th:content="${_csrf.headerName}">

<script>
    document.body.addEventListener('htmx:configRequest', function (event) {
        const token = document.querySelector('meta[name="_csrf"]').content;
        const header = document.querySelector('meta[name="_csrf_header"]').content;
        event.detail.headers[header] = token;
    });
</script>
```

Do not disable CSRF for the browser UI. Only consider disabling CSRF for stateless JSON APIs that use bearer-token authentication and do not rely on cookies.

## Security

For the browser UI, prefer:

- Session-based login
- CSRF enabled
- SameSite cookies
- Server-side authorization
- Method security for business operations
- No secrets in HTML
- No authorization decisions only in the UI

Example:

```java
@Configuration
@EnableMethodSecurity
class WebSecurityConfig {

    @Bean
    SecurityFilterChain webSecurity(HttpSecurity http) throws Exception {
        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/css/**", "/js/**", "/vendor/**").permitAll()
                        .requestMatchers("/app/admin/**").hasRole("ADMIN")
                        .requestMatchers("/app/**").authenticated()
                        .anyRequest().permitAll()
                )
                .formLogin(Customizer.withDefaults())
                .logout(Customizer.withDefaults())
                .build();
    }
}
```

If the same application also exposes a REST API, consider separate `SecurityFilterChain` beans scoped by request matcher:

- `/app/**`: session login + CSRF
- `/api/**`: OAuth2 resource server / bearer token; CSRF disabled if stateless

## Pagination, Filtering, and Sorting

Represent navigable UI state in query parameters:

```text
/app/users?q=smith&page=0&size=25&sort=userName,asc
```

HTMX may update only the table, but the URL should still represent the current state.

Good pattern:

```html
<a th:href="@{/app/users/table(q=${search.q},page=${pageNumber},size=${search.size})}"
   hx-get="@{/app/users/table(q=${search.q},page=${pageNumber},size=${search.size})}"
   hx-target="#users-table"
   hx-swap="outerHTML"
   hx-push-url="true">
   Next
</a>
```

Do not expose raw `Page<T>` directly to templates if it leaks persistence concerns. Prefer a simple view model:

```java
public record PageView<T>(
        List<T> items,
        int page,
        int size,
        long totalElements,
        int totalPages,
        boolean hasPrevious,
        boolean hasNext
) {}
```

## Error Handling

Keep UI error handling (`ui/error`) separate from REST API error handling (`api/error`).

REST API (`api/error`):

- Return `ProblemDetail` JSON.
- Use stable error codes.
- Do not return HTML.

Web UI (`ui/error`):

- Return Thymeleaf error pages or fragments.
- Show user-friendly messages.
- Do not leak stack traces or SQL/JPA details.

Example:

```java
// ui/error/WebExceptionHandler.java
@ControllerAdvice(assignableTypes = UserPageController.class)
class WebExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    String handleNotFound(UserNotFoundException ex, Model model) {
        model.addAttribute("message", ex.getMessage());
        return "error/404";
    }
}
```

For HTMX requests, it is often better to return a targeted error fragment or message area than a full error page.

## Static Resources

Use:

```text
src/main/resources/static/css/app.css
src/main/resources/static/js/app.js
src/main/resources/static/vendor/htmx/htmx.min.js
```

Development:

```yaml
spring:
  thymeleaf:
    cache: false
```

Production:

```yaml
spring:
  thymeleaf:
    cache: true
```

Do not rely on disabled template caching in production.

## Accessibility and HTML Quality

Generate semantic, accessible HTML:

- Use real `<form>`, `<button>`, `<label>`, `<table>`, `<nav>`, `<main>` elements.
- Link labels to inputs with `for` and `id`.
- Use buttons for actions and links for navigation.
- Preserve keyboard navigation.
- Avoid replacing large DOM regions unnecessarily.
- Use `aria-live` for dynamically updated status/message areas when helpful.
- Ensure server-side validation messages are visible near the affected field.

HTMX should enhance HTML, not replace HTML fundamentals.

## Testing Strategy

Use tests appropriate for server-rendered HTML:

- `@WebMvcTest` for controller/template behavior
- `@SpringBootTest` for full flows
- Spring Security test support for authenticated/role-specific flows
- MockMvc assertions for important rendered markup
- Testcontainers for database-backed flows
- HTML assertions for key fragments and forms

Example:

```java
@WebMvcTest(UserPageController.class)
class UserPageControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockBean
    UserService userService;

    @Test
    @WithMockUser
    void listUsersReturnsPage() throws Exception {
        when(userService.searchUsers(any()))
                .thenReturn(List.of(new UserRowView(
                        UUID.randomUUID(),
                        "jdoe",
                        "jdoe@example.com",
                        "Active",
                        true
                )));

        mockMvc.perform(get("/app/users"))
                .andExpect(status().isOk())
                .andExpect(view().name("users/list"))
                .andExpect(content().string(containsString("jdoe")));
    }
}
```

Test HTMX fragments explicitly:

```java
@Test
@WithMockUser
void searchReturnsTableFragmentForHtmx() throws Exception {
    mockMvc.perform(get("/app/users/table")
                    .param("q", "doe")
                    .header("HX-Request", "true"))
            .andExpect(status().isOk())
            .andExpect(view().name("users/_table :: usersTable"))
            .andExpect(content().string(containsString("users-table")));
}
```

## Implementation Workflow

When asked to add or modify a web UI feature:

1. Identify whether the feature is a full page, fragment interaction, or both.
2. Check existing URL, package, template, and security conventions.
3. Reuse existing application services where possible.
4. Create or update web form/view models.
5. Add or update the `@Controller` method.
6. Add or update the Thymeleaf page or fragment.
7. Add HTMX attributes only after the non-JavaScript flow is clear.
8. Ensure CSRF works for unsafe requests.
9. Add validation and user-friendly error display.
10. Add MockMvc tests for full page and fragment behavior.
11. Check that no entities or persistence-specific objects are exposed to templates.
12. Check that search/page/filter state remains bookmarkable.

## Code Review Checklist

Before considering the work complete, verify:

- [ ] REST API and web UI controllers are separate.
- [ ] UI URLs live under a clear prefix such as `/app`.
- [ ] HTMX endpoints return HTML fragments.
- [ ] Controllers are thin and delegate to services.
- [ ] Service-layer transactions are preserved.
- [ ] Templates receive view models, not JPA entities or domain models.
- [ ] API responses use dedicated response models, not JPA entities or domain models.
- [ ] Forms use dedicated form models with Bean Validation.
- [ ] `persistence` classes have no imports from `domain`, `api`, or `ui`.
- [ ] `domain` classes have no imports from `api` or `ui`.
- [ ] Cross-layer mapping uses factory methods: `request.toDomainModel()`, `Response.from(model)`, `DomainModel.from(entity)`.
- [ ] Validation errors are rendered next to the relevant fields.
- [ ] CSRF is enabled and works for HTMX unsafe requests.
- [ ] Browser UI uses session/login security unless the project has another explicit model.
- [ ] API security and UI security do not accidentally conflict.
- [ ] Pagination/filter/search state is represented in the URL.
- [ ] Templates are semantic and accessible.
- [ ] Static assets are versioned or vendored appropriately.
- [ ] Thymeleaf caching is disabled only in development.
- [ ] Tests cover full-page rendering and HTMX fragment rendering.
- [ ] No stack traces, SQL errors, or internal exception names are shown to users.
- [ ] No secrets, tokens, internal IDs, or authorization-only data are leaked into HTML.

## Anti-Patterns

Avoid:

- Returning JSON from HTMX endpoints and manually rendering it with JavaScript.
- Passing JPA entities directly to templates or API responses.
- Passing domain models directly to templates or API responses.
- Calling repositories directly from controllers.
- Letting `persistence` classes import from `domain`, `api`, or `ui`.
- Letting `domain` classes import from `api` or `ui`.
- Using a generic mapper class (`UserMapper`, `ModelMapper`) when a factory method on the model is sufficient.
- Bypassing the domain model by mapping entities directly to API or UI models.
- Disabling CSRF for the web UI.
- Using HTMX as an accidental SPA framework.
- Storing important UI state only in hidden client-side JavaScript.
- Creating separate business logic for REST and UI flows.
- Returning full pages for every small HTMX update.
- Returning fragments that are impossible to render or test independently.
- Using `div` and JavaScript where native HTML elements work.
- Building templates that depend on lazy-loaded JPA relationships.
- Hiding authorization failures only by removing buttons from the page.
- Making pagination/search state non-bookmarkable.
- Ignoring accessibility because the UI is "internal only".

## Preferred Answer Style When Using This Skill

When helping with code:

- Start with the recommended structure.
- Show concrete Java and Thymeleaf snippets.
- Keep examples compatible with Java 21 and Spring Boot 4.x.
- Prefer explicit controller methods over clever abstractions.
- Explain where files should be placed.
- Mention security/CSRF implications when forms, `hx-post`, `hx-put`, `hx-patch`, or `hx-delete` are involved.
- Include tests for new UI behavior when feasible.
- Call out trade-offs when HTMX is not the right fit.

## Default Decision Rules

If the user asks for a CRUD web UI:

- Use `/app/<resource>` for pages.
- Use `/app/<resource>/<fragment-name>` for fragments when useful.
- Use Thymeleaf full page + fragment templates.
- Use form/view models.
- Use service-layer methods.
- Add MockMvc tests.

If the user asks for search/filter:

- Use GET.
- Keep parameters in the URL.
- Use `hx-get`.
- Use `hx-target` to replace only the result area.
- Use `hx-push-url="true"`.

If the user asks for create/update/delete:

- Use POST for standard forms.
- Use `hx-post` when replacing a form or table fragment.
- Include CSRF.
- Return validation fragments on validation errors.
- Use `HX-Redirect` only when real navigation is intended.

If the user asks whether to use Thymeleaf/HTMX or a SPA:

- Recommend Thymeleaf/HTMX for CRUD-heavy, form-heavy, server-centric internal or admin UIs.
- Recommend a SPA only for complex client-side state, offline usage, heavy visual interaction, or frontend teams that need independent deployment.
