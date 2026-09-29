# Cabbie — Database Model

Supabase (PostgreSQL) data model of a ride-booking platform. Sanitized for public portfolio use.

## Entity-relationship diagram

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

## Design decisions

- **Native auth integration:** `drivers.user_id` and `audit_log` reference `auth.users.id`; access is enforced with Row Level Security (conceptual, policies not published).
- **Booking lifecycle:** `status` and `source` are enums, so invalid states cannot be stored.
- **Pricing by vehicle type:** `pricing_rules` is a logical lookup, not a foreign key, so rates can change without touching past bookings.
- **Geocoding cache:** `geocode_cache` stores hashed queries with expiry and hit counts to cut latency and third-party API cost.
- **Auditability:** `audit_log` keeps before/after diffs of sensitive changes.
- **Standalone tables:** `site_content` (CMS) and `rate_limits` are standalone tables with no FK dependencies.

## Omitted for confidentiality

Customer and driver personal data, plates, licence numbers, IP addresses, RLS policies, keys, endpoints and providers. `[redacted]` markers are intentional (privacy by design, GDPR-aware).
