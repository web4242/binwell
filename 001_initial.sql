-- BinWell production schema for PostgreSQL / Supabase.
-- Apply with: supabase db push

create extension if not exists pgcrypto;
create extension if not exists postgis;

create type public.binwell_role as enum ('owner','ops_manager','field_worker','support','customer');
create type public.customer_status as enum ('active','paused','cancelled','waitlist');
create type public.payment_status as enum ('current','past_due','trial','cancelled');
create type public.service_task_type as enum ('bin_out','bin_return','cleaning');
create type public.service_status as enum ('scheduled','route_assigned','in_progress','completed','exception','skipped','cancelled');
create type public.route_status as enum ('draft','ready','in_progress','completed','blocked');

create table public.plans (
  code text primary key check (code in ('valet','valet_clean')),
  name text not null,
  monthly_price_cents integer not null check (monthly_price_cents > 0),
  cleaning_per_month integer not null default 0,
  stripe_price_id text,
  active boolean not null default true
);

insert into public.plans(code,name,monthly_price_cents,cleaning_per_month) values
('valet','BinWell Valet',2500,0),('valet_clean','BinWell Valet + Clean',3500,1)
on conflict (code) do nothing;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.binwell_role not null default 'customer',
  first_name text,
  last_name text,
  phone text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.service_zones (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  active boolean not null default true,
  boundary geography(polygon,4326),
  boundary_geojson jsonb,
  serviceable_postal_codes text[] not null default '{}',
  created_at timestamptz not null default now()
);
create index service_zones_boundary_gix on public.service_zones using gist(boundary);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id) on delete set null,
  first_name text not null,
  last_name text not null,
  email text not null,
  phone text not null,
  status public.customer_status not null default 'active',
  plan_code text not null references public.plans(code),
  payment_status public.payment_status not null default 'trial',
  stripe_customer_id text unique,
  notification_sms boolean not null default true,
  notification_email boolean not null default true,
  signed_up_at timestamptz not null default now(),
  cancelled_at timestamptz
);
create index customers_status_idx on public.customers(status);
create index customers_plan_idx on public.customers(plan_code);
create index customers_email_idx on public.customers(lower(email));

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  address1 text not null,
  city text not null,
  state text not null,
  postal_code text not null,
  lat double precision not null,
  lng double precision not null,
  location geography(point,4326),
  zone_id uuid references public.service_zones(id),
  storage_locations text[] not null default '{}',
  access_instructions text,
  gate_code_ciphertext text,
  pet_warning boolean not null default false,
  curb_instructions text,
  photo_url text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index properties_customer_idx on public.properties(customer_id);
create index properties_zone_idx on public.properties(zone_id);
create index properties_location_gix on public.properties using gist(location);
create index properties_postal_idx on public.properties(postal_code);

create table public.bins (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  bin_type text not null check (bin_type in ('trash','recycling','yard','other')),
  label text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index bins_property_idx on public.bins(property_id);

create table public.pickup_schedules (
  id uuid primary key default gen_random_uuid(),
  property_id uuid unique not null references public.properties(id) on delete cascade,
  garbage_weekdays smallint[] not null default '{}',
  recycling_weekdays smallint[] not null default '{}',
  yard_weekdays smallint[] not null default '{}',
  timezone text not null default 'America/New_York',
  source text not null check (source in ('municipal','zone_template','bulk_import','manual')),
  verified boolean not null default false,
  external_ref text,
  updated_at timestamptz not null default now()
);

create table public.holiday_overrides (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references public.service_zones(id) on delete cascade,
  original_pickup_date date not null,
  shifted_pickup_date date not null,
  note text not null,
  created_at timestamptz not null default now(),
  unique(zone_id, original_pickup_date)
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid unique not null references public.customers(id) on delete cascade,
  plan_code text not null references public.plans(code),
  stripe_subscription_id text unique,
  status text not null,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.employees (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  first_name text not null,
  last_name text not null,
  phone text,
  role public.binwell_role not null check (role in ('owner','ops_manager','field_worker','support')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.employee_zones (
  employee_id uuid not null references public.employees(id) on delete cascade,
  zone_id uuid not null references public.service_zones(id) on delete cascade,
  primary key(employee_id,zone_id)
);

create table public.service_events (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  task_type public.service_task_type not null,
  bin_types text[] not null default '{}',
  scheduled_for timestamptz not null,
  due_by timestamptz,
  related_pickup_date date,
  status public.service_status not null default 'scheduled',
  route_id uuid,
  worker_id uuid references public.employees(id),
  completed_at timestamptz,
  completion_photo_url text,
  notes text,
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index service_events_schedule_idx on public.service_events(scheduled_for,status);
create index service_events_property_idx on public.service_events(property_id,scheduled_for desc);
create index service_events_customer_idx on public.service_events(customer_id,scheduled_for desc);
create index service_events_worker_idx on public.service_events(worker_id,status);

create table public.routes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  service_date date not null,
  task_type public.service_task_type not null,
  zone_id uuid not null references public.service_zones(id),
  worker_id uuid references public.employees(id),
  status public.route_status not null default 'draft',
  planned_miles numeric(8,2) not null default 0,
  estimated_minutes integer not null default 0,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index routes_service_date_idx on public.routes(service_date,task_type,status);
create index routes_worker_date_idx on public.routes(worker_id,service_date);

alter table public.service_events add constraint service_events_route_fk foreign key(route_id) references public.routes(id) on delete set null;

create table public.route_stops (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.routes(id) on delete cascade,
  service_event_id uuid unique not null references public.service_events(id) on delete cascade,
  sequence integer not null check (sequence > 0),
  status text not null check (status in ('pending','completed','exception','skipped')) default 'pending',
  arrived_at timestamptz,
  completed_at timestamptz,
  unique(route_id,sequence)
);
create index route_stops_route_idx on public.route_stops(route_id,sequence);

create table public.issues (
  id uuid primary key default gen_random_uuid(),
  service_event_id uuid not null references public.service_events(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  code text not null,
  severity text not null check (severity in ('low','medium','high')),
  status text not null check (status in ('open','resolved')) default 'open',
  note text,
  photo_url text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
create index issues_open_idx on public.issues(status,created_at desc);

create table public.cleaning_events (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  due_month date not null,
  scheduled_for date,
  completed_at timestamptz,
  service_event_id uuid references public.service_events(id),
  unique(customer_id,due_month)
);
create index cleaning_due_idx on public.cleaning_events(due_month,completed_at);

create table public.photos (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references public.properties(id) on delete cascade,
  service_event_id uuid references public.service_events(id) on delete cascade,
  kind text not null,
  storage_path text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.notification_logs (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  service_event_id uuid references public.service_events(id) on delete set null,
  channel text not null check (channel in ('email','sms')),
  template text not null,
  provider_message_id text,
  status text not null,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  service_event_id uuid references public.service_events(id) on delete set null,
  category text not null,
  status text not null default 'open',
  subject text,
  body text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table public.waitlist_leads (
  id uuid primary key default gen_random_uuid(),
  address text not null,
  email text,
  phone text,
  location geography(point,4326),
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id),
  entity_type text not null,
  entity_id text not null,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);
create index audit_entity_idx on public.audit_logs(entity_type,entity_id,created_at desc);

-- RLS -----------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.properties enable row level security;
alter table public.bins enable row level security;
alter table public.pickup_schedules enable row level security;
alter table public.subscriptions enable row level security;
alter table public.service_events enable row level security;
alter table public.routes enable row level security;
alter table public.route_stops enable row level security;
alter table public.issues enable row level security;
alter table public.cleaning_events enable row level security;
alter table public.notification_logs enable row level security;
alter table public.support_tickets enable row level security;

create or replace function public.current_binwell_role() returns public.binwell_role language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create policy "profile self read" on public.profiles for select using (id = auth.uid());
create policy "admin profiles read" on public.profiles for select using (public.current_binwell_role() in ('owner','ops_manager'));

create policy "customer own customer row" on public.customers for select using (auth_user_id = auth.uid() or public.current_binwell_role() in ('owner','ops_manager','support'));
create policy "customer own property" on public.properties for select using (
  customer_id in (select id from public.customers where auth_user_id = auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support','field_worker')
);
create policy "customer own bins" on public.bins for select using (
  property_id in (select p.id from public.properties p join public.customers c on c.id=p.customer_id where c.auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support','field_worker')
);
create policy "customer own schedule" on public.pickup_schedules for select using (
  property_id in (select p.id from public.properties p join public.customers c on c.id=p.customer_id where c.auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support','field_worker')
);
create policy "customer own subscription" on public.subscriptions for select using (
  customer_id in (select id from public.customers where auth_user_id=auth.uid()) or public.current_binwell_role() in ('owner','ops_manager','support')
);
create policy "customer own service history" on public.service_events for select using (
  customer_id in (select id from public.customers where auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support')
  or worker_id in (select id from public.employees where auth_user_id=auth.uid())
);
create policy "workers assigned routes" on public.routes for select using (
  public.current_binwell_role() in ('owner','ops_manager','support')
  or worker_id in (select id from public.employees where auth_user_id=auth.uid())
);
create policy "workers assigned stops" on public.route_stops for select using (
  route_id in (select id from public.routes where public.current_binwell_role() in ('owner','ops_manager','support') or worker_id in (select id from public.employees where auth_user_id=auth.uid()))
);
create policy "customer own issues" on public.issues for select using (
  customer_id in (select id from public.customers where auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support')
  or service_event_id in (select id from public.service_events where worker_id in (select id from public.employees where auth_user_id=auth.uid()))
);

create policy "customer own cleaning" on public.cleaning_events for select using (
  customer_id in (select id from public.customers where auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support')
);
create policy "customer own notification history" on public.notification_logs for select using (
  customer_id in (select id from public.customers where auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support')
);
create policy "customer own support tickets" on public.support_tickets for select using (
  customer_id in (select id from public.customers where auth_user_id=auth.uid())
  or public.current_binwell_role() in ('owner','ops_manager','support')
);

-- Service-role server APIs bypass RLS. Browser clients never receive service-role keys.
