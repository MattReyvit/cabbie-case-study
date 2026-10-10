# Cabbie — Independent Product & Architecture Case Study

> Status: **in progress** · Sanitized architecture excerpt: no credentials, customer records or production URLs.

A ride-booking platform for a private driver service: public website, booking flow, driver management, fare rules, content management and audit trail.

## Interactive diagrams

[View both interactive diagrams on one page](https://reyvit-cisneros.github.io/cabbie-case-study/)

The page presents the operational flow first and the data model below it.

- [Operational flow — animated](https://reyvit-cisneros.github.io/cabbie-case-study/cabbie-flujo-operativo.html)
- [Data model — animated](https://reyvit-cisneros.github.io/cabbie-case-study/cabbie-modelo-datos.html)

## Operational overview

```mermaid
flowchart LR
    V[Visitor] --> W[Public website and SEO]
    W --> B[Booking flow]
    B --> P[Fare rules]
    B --> G[Geocoding cache]
    B --> D[(Database with row-level security)]
    D --> A[Admin panel]
    A --> C[Site content]
    D --> L[Audit log]
```

[Open the animated operational flow](https://reyvit-cisneros.github.io/cabbie-case-study/cabbie-flujo-operativo.html)

## Data model

Sanitized entity-relationship excerpt. Dashed relationships represent logical associations, not necessarily database foreign-key constraints. Redacted fields indicate omitted information, not actual database types.

```mermaid
erDiagram
    AUTH_USERS ||--o| drivers : "user_id"
    AUTH_USERS ||..o{ audit_log : "performed by"
    drivers ||--o{ vehicles : "operates"
    drivers ||--o{ bookings : "serves"
    vehicles ||--o{ bookings : "assigned to"
    bookings ||--o| service_ratings : "receives"
    drivers ||--o{ service_ratings : "rated in"
    pricing_rules ||..o{ bookings : "prices by vehicle_type"
    geocode_cache ||..o{ bookings : "resolves origin and destination"

    AUTH_USERS {
        uuid id PK "Supabase Auth"
    }
    drivers {
        uuid id PK
        uuid user_id FK
        redacted full_name "[redacted]"
        redacted contact "[redacted]"
        redacted license_number "[redacted]"
        bool is_active
        timestamptz created_at
    }
    vehicles {
        uuid id PK
        uuid driver_id FK
        enum vehicle_type
        int capacity
        redacted plate_number "[redacted]"
        bool is_active
    }
    bookings {
        uuid id PK
        uuid driver_id FK
        uuid vehicle_id FK
        enum service_type
        enum vehicle_type
        enum source "web | chat | manual"
        enum status "booking lifecycle"
        redacted customer_data "[redacted]"
        jsonb stops "origin, destination, stops"
        timestamptz pickup_datetime
        timestamptz actual_start_end
        numeric total_fare
        bool confirmation_pending
    }
    service_ratings {
        uuid id PK
        uuid booking_id FK
        uuid driver_id FK
        int rating
        int driver_rating
        int vehicle_rating
        int punctuality_rating
    }
    pricing_rules {
        uuid id PK
        enum vehicle_type
        numeric base_km_minute_rates
        numeric minimum_fare_and_fees
        numeric surge_multiplier
        text currency
    }
    geocode_cache {
        uuid id PK
        text query_hash
        jsonb results
        int hit_count
        timestamptz expires_at
    }
    audit_log {
        uuid id PK
        text action
        text table_name
        jsonb old_new_data "change diff"
        redacted network_metadata "[redacted]"
        timestamptz created_at
    }
    site_content {
        uuid id PK
        text section
        text content_key
        jsonb value
    }
    rate_limits {
        uuid id PK
        redacted client_key "[redacted] hashed"
        int request_count
        timestamptz window_start
    }
```

[Open the animated data model](https://reyvit-cisneros.github.io/cabbie-case-study/cabbie-modelo-datos.html)

## Problem

Small transport operators lose bookings to slow phone/WhatsApp flows and have no structured record of trips, ratings or pricing.

## Constraints

- Mobile-first, fast on 4G.
- Personal data handled under privacy-by-design principles.
- Content editable without developers.
- Low operating cost.

## Solution

A connected booking workflow combining the public website, fare rules, geocoding cache, database access controls, administration, editable content and audit logging.

## Documents

- [ARCHITECTURE.md](ARCHITECTURE.md) — layers, data flow and security model.
- [DATABASE.md](DATABASE.md) — sanitized entity-relationship model.
- [Interactive diagrams](https://reyvit-cisneros.github.io/cabbie-case-study/) — operational flow and data model on one page.

## My role

Product definition, UX flows, data model, security policies, SEO and delivery — using AI-assisted development with a documented method ([Reyvit Framework](https://github.com/Reyvit-Cisneros/reyvit-framework)).

## Omitted for confidentiality

Client identity, real records, access policies' literal code, API keys, internal endpoints and production URLs.

## License

Documentation and diagrams: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
