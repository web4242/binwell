# BinWell Operating Platform

Production-oriented web operating system for **BinWell**, a recurring residential trash-bin valet business. The application combines customer acquisition, subscription signup, municipal schedule management, route generation, field-worker execution, customer self-service, support, territory management, reporting, and billing into one Next.js application.

## What is included

- Public landing page and low-friction address-first signup.
- $25 **BinWell Valet** and $35 **BinWell Valet + Clean** subscription paths.
- Address geocoding, service-zone eligibility, editable map polygons, ZIP fallback, and waitlist capture.
- Separate bin-out, municipal-pickup/return, and cleaning service events with persisted status history.
- Multiple garbage/recycling pickup days, holiday overrides, schedule bulk import, and route regeneration.
- Geographic route ordering, distance/time estimates, manual operational control, and worker assignment by zone.
- Phone-first worker PWA with navigation, access instructions, gate-code display for authorized workers, one-tap completion, and exception reporting.
- Admin command center, operations stream, CRM, support queue, staff, territories, schedules, routes, and reports.
- Customer portal for property instructions, bins, vacation skips, notification preferences, support, service history, and Stripe billing portal.
- Stripe Checkout/webhooks, Supabase Auth/Postgres/RLS, MapLibre/Mapbox boundary, Resend/Twilio adapters, and gate-code encryption.
- Zero-credential demo mode with realistic seeded customers, routes, workers, schedules, issues, and cleaning obligations.

## Stack

- Next.js 16 / React 19 / TypeScript
- Tailwind CSS 4 + custom application CSS
- PostgreSQL + Supabase Auth/RLS for production
- Stripe subscriptions and Customer Portal
- MapLibre GL; Mapbox geocoding when configured
- Resend email and Twilio SMS adapters
- Vercel-ready deployment and cron configuration

## Run locally in demo mode

Requirements: Node.js 22+ and npm.

```bash
cp .env.example .env.local
npm install
npm run dev
```

Leave `BINWELL_DEMO_MODE=true`. Open `http://localhost:3000`. Demo mode does not require Supabase, Stripe, Mapbox, Resend, or Twilio credentials. State changes persist to `data/demo-state.local.json` and can be reset through the demo reset endpoint.

Useful checks:

```bash
npm run test:domain
npm run typecheck
npm run build
```

## Production setup

1. Create a Supabase project and apply `supabase/migrations/001_initial.sql` (or run `supabase db push` from a linked Supabase CLI project).
2. Set `BINWELL_DEMO_MODE=false` and provide the Supabase URL, anon key, and **server-only** service-role key.
3. Create the first owner account:

```bash
ADMIN_EMAIL=you@example.com npm run admin:create
```

Set `ADMIN_PASSWORD` too if you want to create a confirmed password user instead of sending an invite. The normal application login uses magic links.
4. Create two recurring monthly Stripe prices: $25 and $35. Put their price IDs in `STRIPE_PRICE_VALET` and `STRIPE_PRICE_VALET_CLEAN`.
5. Configure Stripe webhook delivery to `/api/stripe/webhook` and set `STRIPE_WEBHOOK_SECRET`.
6. Add Mapbox, Resend, and Twilio credentials as desired. The map itself can use any MapLibre-compatible style URL.
7. Set a long random `BINWELL_GATE_CODE_ENCRYPTION_KEY` and `CRON_SECRET`.
8. Deploy to Vercel and add `trybinwell.com`; see `docs/DEPLOYMENT.md` for exact steps.
9. In Admin → Territories, create your first operating zone, draw the service polygon and/or add eligible ZIP codes. In Admin → Schedules, import or verify municipal pickup rules.

## Environment variables

Copy `.env.example`. Important variables:

| Variable | Required in production | Purpose |
| --- | --- | --- |
| `NEXT_PUBLIC_APP_URL` | yes | canonical app origin, e.g. `https://trybinwell.com` |
| `BINWELL_DEMO_MODE` | yes | `false` in production |
| `NEXT_PUBLIC_SUPABASE_URL` | yes | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | yes | browser/server session auth |
| `SUPABASE_SERVICE_ROLE_KEY` | yes | server repository + admin operations; never expose client-side |
| `STRIPE_SECRET_KEY` | billing | Stripe server API |
| `STRIPE_WEBHOOK_SECRET` | billing | signed webhook validation |
| `STRIPE_PRICE_VALET` | billing | $25 monthly price ID |
| `STRIPE_PRICE_VALET_CLEAN` | billing | $35 monthly price ID |
| `MAPBOX_ACCESS_TOKEN` | recommended | address geocoding |
| `NEXT_PUBLIC_MAP_STYLE_URL` | no | MapLibre style URL |
| `RESEND_API_KEY` | email | transactional email |
| `TWILIO_*` | SMS | transactional SMS |
| `BINWELL_GATE_CODE_ENCRYPTION_KEY` | yes | AES-256-GCM key material for access codes |
| `CRON_SECRET` | yes | protects scheduled automation endpoints |

## Operational model

A municipal pickup is not represented as one generic job. It produces independent operational work:

1. **Bin out** — storage location → curb, evening before pickup.
2. **Municipal pickup** — external event; BinWell waits for the municipality.
3. **Bin return** — curb → storage location, after pickup.
4. **Cleaning** — separately batched monthly for Valet + Clean customers.

This lets a return stay outstanding even after bin-out is complete, makes municipal missed-pickup exceptions explicit, and gives routing/worker state a reliable audit trail.

## Repository modes

`lib/repo/index.ts` selects one of two repositories:

- **Demo:** file-backed state with realistic seed data and no credentials.
- **Production:** normalized Supabase/Postgres tables with paginated reads, RLS for browser access, and server-only writes using the service role.

The normalized SQL schema is the source of truth for production. The current server repository intentionally uses a whole-operating-state abstraction to keep business rules and demo/production behavior identical during the initial launch. At larger fleet sizes, hot mutation endpoints can be moved to targeted SQL/RPC commands without changing the domain model or UI contracts; see `docs/SCALING.md`.

## Documentation

- `docs/ARCHITECTURE.md` — domain/data architecture and service lifecycle.
- `docs/DEPLOYMENT.md` — exact production launch steps for `trybinwell.com`.
- `docs/INTEGRATIONS.md` — Stripe, Supabase, mapping, email, SMS, municipal schedule adapters.
- `docs/OPERATIONS.md` — owner/dispatcher/field workflows and exception playbook.
- `docs/TESTING.md` — test matrix and validation commands.
- `docs/PRODUCT_REVIEW.md` — customer, worker, operations-manager, and owner review.
- `docs/SCALING.md` — path from tens to 20,000 customers without a schema rebuild.
