# Portfolio-Tracker MVP – Gesamtarchitektur

## 1. Ziel

Ziel ist eine **private, web-basierte Portfolio-Tracker-Anwendung** für **genau einen Benutzer**, die **mehrere, aber wenige Portfolios** verwalten kann. Die Anwendung unterstützt im MVP insbesondere:

- Verwaltung mehrerer Portfolios
- Verwaltung internationaler Aktien und ETFs
- Erfassung von Transaktionen
- Berechnung von Beständen und Einstandswerten
- Abruf von Marktpreisen über frei verfügbare Finanz-APIs
- Bewertung der Portfolios in einer Basiswährung
- Speicherung der Daten in einer **relationalen Datenbank**
- Betrieb der Gesamtlösung über **Docker Compose**

Die Architektur soll bewusst so aufgebaut sein, dass sie später um zusätzliche Datenprovider, weitere Analysefunktionen und komplexere Importmechanismen und gegebenenfalls mit einem anderen Frontend (z.B. Single-Page Frontend) erweitert werden kann.

---

## 2. Architekturüberblick

Die Anwendung besteht im MVP aus drei technischen Hauptbausteinen:

1. **Web-Frontend**
   - Browser-basierte Benutzeroberfläche
   - Anzeige und Pflege von Portfolios, Instrumenten und Transaktionen
   - Darstellung von Kennzahlen und Portfolio-Übersichten

2. **Spring-Boot-Backend**
   - Fachlogik
   - REST-API für das Frontend
   - Persistenzzugriff auf relationale Datenbank
   - Anbindung an externe Finanzdaten-APIs
   - Caching und zeitgesteuerte Kursaktualisierung

3. **Relationale Datenbank im Docker-Container**
   - Speicherung von Stammdaten, Portfolios, Transaktionen, Kursen und Wechselkursen

Die Anwendung wird als Docker-basierte Gesamtlösung betrieben:

- `backend` Container
- `db` Container
- Start über `docker-compose.yaml`

---

## 3. Zielarchitektur auf hoher Ebene

```text
Browser
   |
   v
Web Frontend
   |
   v
Spring Boot Backend
   |         \
   |          \--> Externe Finanz-API(s)
   |
   +--> Relationale Datenbank
```

### Architekturprinzipien

- **Single user**: keine Mandantenfähigkeit im MVP
- **Backend-zentrierte Integrationen**: nur das Backend spricht mit externen APIs
- **Klare Schichten**: API, Fachlogik, Persistenz, Integrationen
- **Erweiterbarkeit**: Provider-Abstraktion für Finanzdaten
- **Containerisierung**: alle zentralen Laufzeitkomponenten containerisiert

---

## 4. Empfohlener Technologie-Stack

### Frontend

Für den MVP wird die einfachere Variante A implementiert.

#### Variante A – für MVP
- **Spring Boot + Thymeleaf + HTMX**
- Vorteile:
  - einfachere Gesamtarchitektur
  - kein separates komplexes SPA-Frontend nötig
  - schnelle Umsetzung für einen privaten Tracker
  - direkte Integration mit Spring Boot

#### Variante B – optional später
- **separates SPA-Frontend**, z. B. React oder Vue
- Vorteile:
  - modernere UI-Architektur
  - stärkere Trennung zwischen Frontend und Backend
- Nachteile:
  - höherer Implementierungsaufwand
  - mehr Build- und Deployment-Komplexität

### Backend
- Java 21+
- Spring Boot
- Spring Web
- Spring Data JPA
- Flyway für Datenbankmigrationen
- Caffeine Cache
- optional später: Resilience4j

### Datenbank
- PostgreSQL

Für den MVP wird **PostgreSQL** verwendet, weil sie für relationale Anwendungen, Docker-Betrieb und SQL-basierte Auswertungen robust und unkompliziert ist.

---

## 5. Container-Architektur

### Container 1 – `frontend`
Nur erforderlich, wenn ein separates Frontend verwendet wird. Wird für den MVP nicht verwendet.

Bei Nutzung von Thymeleaf/HTMX im Backend kann dieser Container im MVP entfallen.

### Container 2 – `backend`
Enthält:
- Spring-Boot-Anwendung
- REST-API und/oder serverseitige HTML-Auslieferung
- Scheduler für Kursabfragen
- Fachlogik

### Container 3 – `db`
Enthält:
- relationale Datenbank
- persistentes Volume für Datenhaltung

---

## 6. Empfohlene MVP-Entscheidung für das UI

Für den MVP wird **kein separates Frontend-Deployment** gebaut, sondern:

- UI mit **Thymeleaf + HTMX**
- Backend liefert HTML-Seiten und JSON-Endpunkte
- nur ein Applikationscontainer (`backend`) plus Datenbankcontainer (`db`)


Damit ist die MVP-Gesamtlösung besonders einfach:

- `backend`
- `db`

Optional kann später ein separates `frontend` ergänzt werden.

---

## 7. Fachliche Hauptfunktionen des MVP

### 7.1 Portfolio-Verwaltung
- mehrere Portfolios anlegen
- Portfolio umbenennen
- Portfolio-Basiswährung definieren
- Portfolio löschen

### 7.2 Instrument-Verwaltung
- Aktien und ETFs anlegen
- Zuordnung von:
  - ISIN
  - Ticker
  - Name
  - Börse
  - Währung
  - Asset-Typ
  - Provider-Symbol

### 7.3 Transaktionsverwaltung
- Kauf erfassen
- Verkauf erfassen
- Dividende erfassen
- Einbuchnung/Ausbuchung erfassen

### 7.4 Bestands- und Bewertungslogik
- aktuelle Stückzahl je Position berechnen
- durchschnittlichen Einstandspreis berechnen
- investierten Betrag berechnen
- Marktwert berechnen
- Gewinn/Verlust berechnen

### 7.5 Marktpreisversorgung
- aktuelle Preise abrufen
- historische Tagespreise speichern
- Basiswährungs-Umrechnung vorbereiten

### 7.6 Dashboard / Übersicht
- Gesamtwert aller Portfolios
- Marktwert je Portfolio
- Top-Positionen
- Tagesveränderung (optional im MVP vereinfacht)
- Gesamtgewinn/-verlust

---

## 8. Schichtenmodell des Backends

Das Backend wird in folgende Schichten unterteilt:

### 8.1 Web/API-Schicht
Verantwortlich für:
- HTTP-Endpunkte
- Entgegennahme von Formularen
- Bereitstellung von JSON
- Seiten-Navigation

Typische Klassen:
- `PortfolioPageController`
- `PortfolioRestController`
- `TransactionPageController`
- `DashboardController`

### 8.2 Fachlogik-Schicht
Verantwortlich für:
- Portfolio-Berechnung
- Transaktionsverarbeitung
- Bewertung
- Aggregation

Typische Klassen:
- `PortfolioService`
- `TransactionService`
- `ValuationService`
- `DashboardService`
- `InstrumentService`

### 8.3 Integrationsschicht
Verantwortlich für:
- externe Finanz-APIs
- Provider-Auswahl
- Symbolauflösung
- Preisimporte

Typische Klassen:
- `MarketDataClient`
- `TwelveDataClient`
- `RoutingMarketDataService`
- `PriceImportService`
- `ExchangeRateClient`

### 8.4 Persistenzschicht
Verantwortlich für:
- JPA-Entities
- Repositories
- DB-Zugriff

Typische Klassen:
- `PortfolioEntity`
- `TransactionEntity`
- `InstrumentEntity`
- `PriceHistoryEntity`
- `PortfolioRepository`
- `TransactionRepository`

---

## 9. Empfohlene Package-Struktur

```text
de.groothues.portfolio
├── api
│   ├── page
│   │   ├── DashboardController
│   │   ├── PortfolioPageController
│   │   └── TransactionPageController
│   └── rest
│       ├── PortfolioRestController
│       ├── InstrumentRestController
│       └── ValuationRestController
├── application
│   ├── PortfolioService
│   ├── TransactionService
│   ├── InstrumentService
│   ├── ValuationService
│   ├── DashboardService
│   └── PriceImportService
├── domain
│   ├── model
│   │   ├── AssetType
│   │   ├── TransactionType
│   │   ├── CurrencyCode
│   │   └── PriceSource
│   └── calculation
│       ├── PositionCalculator
│       ├── PortfolioCalculator
│       └── GainLossCalculator
├── integration
│   └── marketdata
│       ├── MarketDataClient
│       ├── RoutingMarketDataService
│       ├── twelve
│       │   ├── TwelveDataClient
│       │   ├── TwelveDataQuoteResponse
│       │   └── TwelveDataTimeSeriesResponse
│       └── fx
│           └── ExchangeRateClient
├── persistence
│   ├── entity
│   │   ├── PortfolioEntity
│   │   ├── InstrumentEntity
│   │   ├── TransactionEntity
│   │   ├── PositionSnapshotEntity
│   │   ├── PriceHistoryEntity
│   │   └── ExchangeRateEntity
│   └── repository
│       ├── PortfolioRepository
│       ├── InstrumentRepository
│       ├── TransactionRepository
│       ├── PriceHistoryRepository
│       └── ExchangeRateRepository
├── config
│   ├── MarketDataProperties
│   ├── DatabaseConfig
│   ├── CacheConfig
│   └── SchedulerConfig
└── support
    ├── ClockProvider
    ├── MoneyUtils
    └── SymbolNormalizer
```

---

## 10. Zentrale fachliche Datenobjekte

### 10.1 Portfolio
Repräsentiert ein Depot oder ein logisches Anlageportfolio.

Wichtige Attribute:
- `id`
- `name`
- `baseCurrency`
- `createdAt`
- `updatedAt`

### 10.2 Instrument
Repräsentiert ein handelbares Wertpapier.

Wichtige Attribute:
- `id`
- `isin`
- `ticker`
- `name`
- `assetType` (`STOCK`, `ETF`)
- `exchange`
- `currency`
- `provider`
- `providerSymbol`
- `active`

### 10.3 Transaction
Repräsentiert eine Buchung innerhalb eines Portfolios.

Wichtige Attribute:
- `id`
- `portfolioId`
- `instrumentId` (optional bei Ein-/Auszahlung)
- `transactionType`
- `tradeDate`
- `quantity`
- `pricePerUnit`
- `fees`
- `taxes`
- `grossAmount`
- `currency`
- `notes`

### 10.4 PriceHistory
Historische Marktpreise pro Instrument.

Wichtige Attribute:
- `id`
- `instrumentId`
- `priceDate`
- `closePrice`
- `currency`
- `source`

### 10.5 ExchangeRate
Wechselkurse zur Umrechnung in Portfolio-Basiswährungen.

Wichtige Attribute:
- `id`
- `baseCurrency`
- `quoteCurrency`
- `rateDate`
- `rate`
- `source`

### 10.6 PositionSnapshot (optional im MVP)
Vorberechneter Tages-Snapshot pro Position.

Im MVP optional. Kann später für Performanceverbesserungen ergänzt werden.

---

## 11. Kern-Entities für die relationale Datenbank

### Tabelle `portfolio`
- `id`
- `name`
- `base_currency`
- `created_at`
- `updated_at`

### Tabelle `instrument`
- `id`
- `isin`
- `ticker`
- `name`
- `asset_type`
- `exchange_code`
- `currency`
- `provider`
- `provider_symbol`
- `active`
- `created_at`
- `updated_at`

### Tabelle `transaction`
- `id`
- `portfolio_id`
- `instrument_id`
- `type`
- `trade_date`
- `quantity`
- `price_per_unit`
- `fees`
- `taxes`
- `gross_amount`
- `currency`
- `notes`
- `created_at`

### Tabelle `price_history`
- `id`
- `instrument_id`
- `price_date`
- `close_price`
- `currency`
- `source`
- `created_at`

### Tabelle `exchange_rate`
- `id`
- `base_currency`
- `quote_currency`
- `rate_date`
- `rate`
- `source`
- `created_at`

---

## 12. Zentrale Service-Klassen

### `PortfolioService`
Verantwortung:
- Portfolios anlegen, lesen, ändern, löschen
- Basisinformationen bereitstellen

### `InstrumentService`
Verantwortung:
- Instrumente anlegen und pflegen
- Suche nach bestehenden Instrumenten
- Provider-Symbol und Stammdaten verwalten

### `TransactionService`
Verantwortung:
- Validierung und Speicherung von Transaktionen
- Löschung oder Korrektur einzelner Buchungen
- Triggern von Neuberechnungen

### `ValuationService`
Verantwortung:
- aktuelle Bewertung eines Portfolios
- Ermittlung von Marktwert, Einstandswert, Gewinn/Verlust
- Aggregation auf Position- und Portfolioebene

### `DashboardService`
Verantwortung:
- Verdichtung der Daten für Übersichtsseiten
- Kennzahlen für Dashboard und Startseite

### `PriceImportService`
Verantwortung:
- Abruf von Kursdaten über externe APIs
- Speichern der Preise in `price_history`
- Aktualisierung relevanter Instrumente

### `ExchangeRateService`
Verantwortung:
- Verwaltung und Bereitstellung von Wechselkursen
- Umrechnung von Instrument- und Portfolio-Werten

---

## 13. Berechnungslogik

Die Berechnungslogik sollte von den Services teilweise in dedizierte Rechenkomponenten ausgelagert werden.

### `PositionCalculator`
Berechnet je Instrument und Portfolio:
- aktuelle Stückzahl
- durchschnittlicher Einstandspreis
- investierter Betrag

### `GainLossCalculator`
Berechnet:
- unrealisierten Gewinn/Verlust
- realisierten Gewinn/Verlust (später erweiterbar)

### `PortfolioCalculator`
Aggregiert:
- Marktwert aller Positionen
- Cash-Anteile
- Gesamtwert pro Portfolio
- Gewinn/Verlust pro Portfolio

---

## 14. Marktpreis-Integration

## 14.1 Grundprinzip

- Externe Finanzdaten werden **nur über das Backend** abgefragt
- API-Keys werden ausschließlich serverseitig verwendet
- Das Frontend kennt keine Drittanbieter-APIs

## 14.2 Provider-Abstraktion

### Interface `MarketDataClient`
Definiert z. B. folgende Methoden:
- `QuoteData getQuote(String providerSymbol)`
- `List<HistoricalPriceData> getDailyHistory(String providerSymbol, int outputSize)`
- `boolean supports(PriceSource source)`

### Implementierungen
- `TwelveDataClient`
- später optional `FinnhubClient`

### `RoutingMarketDataService`
Wählt die passende Implementierung anhand des konfigurierten Providers oder des Instruments.

## 14.3 Preisimport

`PriceImportService` lädt für alle aktiven Instrumente regelmäßig Preise und speichert sie in der Datenbank.

Typische Modi:
- manueller Import
- geplanter täglicher Import
- Einzelaktualisierung eines Instruments

---

## 15. Wechselkurse

Da internationale Aktien und ETFs unterstützt werden sollen, ist Mehrwährungsfähigkeit zentral.

### MVP-Ansatz
- Jedes Portfolio hat eine `baseCurrency`
- Jedes Instrument hat eine Handelswährung
- Für die Bewertung wird bei Bedarf ein Wechselkurs geladen

### Zentrale Klassen
- `ExchangeRateService`
- `ExchangeRateClient`
- `ExchangeRateRepository`

### Empfehlung
Wechselkurse im MVP zunächst **täglich** speichern, nicht intraday.

---

## 16. REST-Endpunkte und Seiten

### HTML-Seiten (bei Thymeleaf/HTMX)
- `GET /dashboard`
- `GET /portfolios`
- `GET /portfolios/{id}`
- `GET /transactions`
- `GET /instruments`

### REST-Endpunkte
- `GET /api/portfolios`
- `POST /api/portfolios`
- `GET /api/portfolios/{id}`
- `POST /api/transactions`
- `GET /api/portfolios/{id}/valuation`
- `GET /api/instruments/search`
- `POST /api/instruments`
- `POST /api/prices/import`

---

## 17. Scheduler / Hintergrundjobs

Auch für einen privaten Tracker ist ein einfacher Scheduler sinnvoll.

### `DailyPriceImportJob`
Aufgabe:
- lädt einmal täglich Kurse für alle aktiven Instrumente
- speichert Preise in `price_history`

### `DailyExchangeRateImportJob`
Aufgabe:
- lädt tägliche Wechselkurse

### `PortfolioRefreshJob` (optional)
Aufgabe:
- erstellt vorberechnete Bewertungsdaten oder Snapshots

---

## 18. Caching

Caching ist sinnvoll, um externe API-Aufrufe zu reduzieren.

### Einsatzbereiche
- Instrument-Suche
- aktuelle Quotes
- Wechselkurse des Tages

### Zentrale Klasse
- `CacheConfig`

### Typische Cache-Namen
- `quotes`
- `instrumentSearch`
- `exchangeRates`

---

## 19. Datenbankmigrationen

Flyway sollte von Anfang an eingesetzt werden.

### Strukturbeispiel
```text
src/main/resources/db/migration
├── V1__create_portfolio_table.sql
├── V2__create_instrument_table.sql
├── V3__create_transaction_table.sql
├── V4__create_price_history_table.sql
└── V5__create_exchange_rate_table.sql
```

Vorteile:
- reproduzierbarer DB-Aufbau
- einfacher Start via Docker Compose
- saubere Versionskontrolle

---

## 20. Build- und Deployment-Architektur

## 20.1 Backend Docker Image

Das Backend wird als Docker Image gebaut.

### Inhalt des Images
- Spring-Boot-Anwendung als JAR
- Laufzeitkonfiguration über Environment Variables

Typische Variablen:
- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `TWELVE_DATA_API_KEY`

## 20.2 Datenbankcontainer

Der Datenbankcontainer wird über offizielles DB-Image bereitgestellt.

### Anforderungen
- Volume für persistente Daten
- Initialisierung per Flyway beim Backend-Start

## 20.3 Docker Compose

Docker Compose startet die Gesamtlösung und vernetzt die Container.

### Erwartete Services
- `backend`
- `db`

Optional später:
- `frontend`

---

## 21. Beispielhafte Docker-Compose-Struktur

```yaml
services:
  db:
    image: postgres:17
    container_name: portfolio-db
    environment:
      POSTGRES_DB: portfolio
      POSTGRES_USER: portfolio
      POSTGRES_PASSWORD: portfolio
    ports:
      - "5432:5432"
    volumes:
      - portfolio_db_data:/var/lib/postgresql/data

  backend:
    build:
      context: ./backend
    container_name: portfolio-backend
    depends_on:
      - db
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/portfolio
      SPRING_DATASOURCE_USERNAME: portfolio
      SPRING_DATASOURCE_PASSWORD: portfolio
      TWELVE_DATA_API_KEY: ${TWELVE_DATA_API_KEY}
    ports:
      - "8080:8080"

volumes:
  portfolio_db_data:
```

Dies ist nur eine Strukturvorgabe, keine finale Produktionskonfiguration.

---

## 22. Repository-Struktur des Projekts

### Empfehlung für den MVP

```text
portfolio-tracker/
├── src/
├── Dockerfile
├── pom.xml
├── docker-compose.yaml
├── architecture.md
├── claude.md
└── README.md
```

---

## 23. Sicherheitsaspekte im MVP

Da es sich um einen privaten Einbenutzer-Tracker handelt, kann die Sicherheit im MVP bewusst einfach gehalten werden.

### MVP-Ansatz
- Anwendung nur lokal oder im privaten Netz betreiben
- keine Mehrbenutzerverwaltung
- optional einfacher Login später
- API-Keys nur serverseitig über Umgebungsvariablen

### Später erweiterbar
- Spring Security
- Benutzer-Login
- Rollenmodell
- CSRF-/Session-Konzept

---

## 24. Nicht-Ziele des MVP

Die folgenden Funktionen sind bewusst **nicht** Teil des MVP:

- Broker-Importe mit vielen Formaten
- automatische PDF-Abrechnungserkennung
- Steuerberichte
- Rebalancing-Empfehlungen
- Benchmark-Vergleiche
- Echtzeit-Streamingkurse
- Mandantenfähigkeit
- Mobile App

---

## 25. Empfohlene Umsetzungsreihenfolge

### Phase 1 – Grundgerüst
- Spring-Boot-Projekt anlegen
- PostgreSQL per Docker Compose bereitstellen
- Flyway einrichten
- Grundtabellen anlegen

### Phase 2 – Stammdaten und Portfolios
- Portfolio-Verwaltung
- Instrument-Verwaltung
- erste HTML-Seiten

### Phase 3 – Transaktionen
- Kauf/Verkauf/Dividende/Gebühren
- Bestandsberechnung

### Phase 4 – Marktpreise
- `MarketDataClient`
- `TwelveDataClient`
- Preisimport und Speicherung

### Phase 5 – Bewertung und Dashboard
- `ValuationService`
- Dashboard
- Kennzahlen und Übersichten

### Phase 6 – Containerisierung
- Dockerfile für Backend
- Docker Compose für Gesamtsystem
- Konfigurationsbereinigung

---

## 26. Zusammenfassung der zentralen Klassen

### Controller
- `DashboardController`
- `PortfolioPageController`
- `TransactionPageController`
- `PortfolioRestController`
- `InstrumentRestController`
- `ValuationRestController`

### Application Services
- `PortfolioService`
- `InstrumentService`
- `TransactionService`
- `ValuationService`
- `DashboardService`
- `PriceImportService`
- `ExchangeRateService`

### Domain / Calculation
- `PositionCalculator`
- `PortfolioCalculator`
- `GainLossCalculator`

### Integration
- `MarketDataClient`
- `TwelveDataClient`
- `RoutingMarketDataService`
- `ExchangeRateClient`

### Persistence
- `PortfolioEntity`
- `InstrumentEntity`
- `TransactionEntity`
- `PriceHistoryEntity`
- `ExchangeRateEntity`
- `PortfolioRepository`
- `InstrumentRepository`
- `TransactionRepository`
- `PriceHistoryRepository`
- `ExchangeRateRepository`

---

## 27. Architektur-Fazit

Folgende MVP-Architektur wird verwendet:

- **Web-basierte Anwendung**
- **Spring Boot Backend**
- **Thymeleaf + HTMX** für die UI im MVP
- **PostgreSQL** als relationale Datenbank im Docker-Container
- **Marktdatenintegration über ein Provider-Interface**
- **Docker Image für das Backend**
- **Start der Gesamtlösung per Docker Compose**

