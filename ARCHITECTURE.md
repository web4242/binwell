# Architecture

## Product surfaces

**Public:** marketing, address eligibility, waitlist, signup, plan selection, property setup, contact/payment handoff.

**Customer:** next service, visit history, property/bin/access instructions, vacation skips, notification preferences, support, billing portal.

**Field:** assigned route, stop sequence, directions, only the property information needed to perform the stop, completion, exception reporting.

**Admin/Ops:** real-time operating view, service-event stream, route regeneration, municipal schedules/holiday shifts, CRM, support, staff, territories, and reporting.

## Core domain

The normalized production model separates `customers`, `properties`, `bins`, `pickup_schedules`, `service_events`, `routes`, `route_stops`, `issues`, `cleaning_events`, `subscriptions`, `employees`, `service_zones`, `support_tickets`, `notification_logs`, `holiday_overrides`, and `audit_logs`.

Operational history is never stored only on the mutable customer record. `service_events.history` retains important status transitions. The table-level `audit_logs` table is provided for future generalized administrative auditing.

## Service lifecycle

Primary states are `scheduled → route_assigned → in_progress/completed`, with `exception`, `skipped`, and `cancelled` branches. Exceptions can be resolved back into an assignable state. Route generation never treats bin-out and return as the same stop.

## Municipal scheduling

`PickupSchedule` supports multiple weekdays independently for garbage, recycling, and yard waste. For each distinct pickup date, the scheduler creates a bin-out and bin-return event carrying only the bin types due on that date. Holiday overrides shift every affected event in a zone and detach it from stale routes before regeneration.

The municipal lookup layer is intentionally an adapter (`lib/integrations/pickup-schedule.ts`): use jurisdiction APIs where available, otherwise zone templates/manual verification/bulk import.

## Cleaning

Cleaning customers have a monthly obligation separate from valet visits. The daily generator places obligations into geographic batch days, preventing subscriber-anniversary dates from fragmenting cleaning routes.

## Routing

The initial route engine uses a deterministic nearest-neighbor ordering over customer coordinates, Haversine distance, estimated stop dwell time, zone/work-type grouping, and worker-zone eligibility. It is deliberately behind `lib/domain/routing.ts`, so Mapbox Optimization, Google Routes, HERE, OR-Tools, or a custom VRP solver can replace ordering later without changing routes/stops in the database.

## Security

- Supabase magic-link authentication.
- Role profiles: owner, ops manager, field worker, support, customer.
- Production page/API role checks are server-side.
- RLS restricts browser reads to the customer’s data or the worker’s assigned work.
- Service-role key is server-only.
- Gate codes are encrypted at rest with AES-256-GCM before database persistence.
- Stripe-hosted payment collection keeps raw card data out of BinWell.
- Webhook signatures and cron bearer secrets are validated.

## External boundaries

Credential-dependent providers are isolated in `lib/integrations`. Demo mode keeps the complete application usable before those accounts exist.
