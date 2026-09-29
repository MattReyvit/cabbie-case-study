-- Cabbie — schema excerpt (sanitized for public case study)
-- Real structure, anonymized values. No credentials, no production URLs, no client data.
-- Full diagram: ../diagrams/database.mmd

-- Core entity: a registered driver (1:1 with auth.users)
create table public.drivers (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  full_name   text not null,
  phone       text not null,
  status      text not null default 'pending'
              check (status in ('pending', 'active', 'suspended')),
  created_at  timestamptz not null default now()
);

-- A driver can own several vehicles (1:N)
create table public.vehicles (
  id          uuid primary key default gen_random_uuid(),
  driver_id   uuid not null references public.drivers (id) on delete cascade,
  plate       text not null unique,
  brand       text not null,
  model       text not null,
  seats       smallint not null check (seats between 1 and 8),
  created_at  timestamptz not null default now()
);

-- Bookings link a passenger request to a driver (N:1)
create table public.bookings (
  id            uuid primary key default gen_random_uuid(),
  driver_id     uuid references public.drivers (id) on delete set null,
  passenger_name text not null,
  origin        text not null,
  destination   text not null,
  scheduled_at  timestamptz not null,
  status        text not null default 'requested'
                check (status in ('requested', 'assigned', 'in_progress', 'completed', 'cancelled')),
  price         numeric(10, 2) check (price >= 0),
  created_at    timestamptz not null default now()
);

-- Row Level Security: drivers only see their own rows
alter table public.drivers enable row level security;
alter table public.vehicles enable row level security;
alter table public.bookings enable row level security;

create policy "drivers read own profile"
  on public.drivers for select
  using (auth.uid() = user_id);

create policy "drivers manage own vehicles"
  on public.vehicles for all
  using (driver_id in (select id from public.drivers where user_id = auth.uid()));

create policy "drivers read assigned bookings"
  on public.bookings for select
  using (driver_id in (select id from public.drivers where user_id = auth.uid()));

-- Audit trail: every status change is appended by a trigger (details omitted)
create table public.audit_log (
  id          bigint generated always as identity primary key,
  table_name  text not null,
  row_id      uuid not null,
  action      text not null,
  changed_by  uuid,
  changed_at  timestamptz not null default now()
);
