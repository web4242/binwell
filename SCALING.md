# Scaling Plan: 20 → 20,000 Customers

## 20–200 customers

Use the included production architecture directly. Prioritize pickup-schedule verification, clean territory boundaries, exception discipline, and route-density learning. The nearest-neighbor optimizer is sufficient for early dense routes.

## 200–2,000 customers

- Move route optimization to a matrix/VRP provider while preserving `routes` and `route_stops`.
- Add provider rate-limit/cost monitoring and geocode caching.
- Add a queue for outbound notifications and photo processing.
- Separate cleaning vehicle capacity from valet route capacity.
- Add explicit route templates/depots/shifts once actual operating patterns are known.
- Begin targeted database queries for large admin lists rather than loading broad state where unnecessary.

## 2,000–20,000 customers

The schema does not need replacement. Change the server repository hot paths from whole-state read/upsert to targeted Postgres RPC/transactions for signup, stop completion, exception creation, holiday shifts, and route generation. Use database constraints/idempotency keys so webhooks and job runners are safe to retry.

Add:

- queue-backed scheduled jobs and notification delivery,
- optimized VRP with route capacities/time windows/depots,
- partitioning or archival policy for high-volume service/notification history if query plans justify it,
- object storage/CDN for service photos,
- real-time route telemetry with explicit worker consent and retention controls,
- observability/Sentry/log aggregation,
- read-optimized reporting/materialized views,
- multi-city municipal schedule adapter registry.

## Guardrails

Do not price individual customers based on protected traits or inferred personal wealth. Route-density/revenue-per-mile can inform territory expansion and operational planning. Keep geographic pricing rules transparent and configured at the service/territory level if pricing ever varies.
