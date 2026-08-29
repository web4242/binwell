# Production Deployment — trybinwell.com

## 1. Create Supabase

Create a Supabase project. Apply `supabase/migrations/001_initial.sql` using the SQL editor or Supabase CLI. Confirm the `postgis` and `pgcrypto` extensions exist and the two plan rows were created.

In Authentication → URL Configuration, set the Site URL to `https://trybinwell.com` and add `https://trybinwell.com/auth/callback` to allowed redirect URLs.

## 2. Create Vercel project

Push this directory to a Git repository and import it into Vercel as a Next.js project. Use the default build command (`npm run build`) and output settings.

Set production environment variables from `.env.example`:

```text
NEXT_PUBLIC_APP_URL=https://trybinwell.com
BINWELL_DEMO_MODE=false
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
BINWELL_GATE_CODE_ENCRYPTION_KEY=<long random secret>
CRON_SECRET=<long random secret>
```

Add Stripe/Mapbox/Resend/Twilio variables as configured below. Redeploy after changing environment variables.

## 3. Create the owner

From a local shell with production environment variables loaded:

```bash
ADMIN_EMAIL=owner@yourdomain.com npm run admin:create
```

Optionally provide `ADMIN_FIRST_NAME`, `ADMIN_LAST_NAME`, and `ADMIN_PASSWORD`. Without a password, Supabase sends an invitation/magic-link path. The callback preserves the owner role and routes the account to Admin.

## 4. Stripe

In Stripe **live mode**, create recurring monthly prices for $25 and $35. Set:

```text
STRIPE_SECRET_KEY=sk_live_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_PRICE_VALET=price_...
STRIPE_PRICE_VALET_CLEAN=price_...
```

Create webhook destination:

```text
https://trybinwell.com/api/stripe/webhook
```

Subscribe to `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`, and `invoice.paid`. Copy the signing secret into `STRIPE_WEBHOOK_SECRET`. Configure Stripe Customer Portal cancellation/payment-method behavior to match BinWell policy.

## 5. Maps/address validation

Create a Mapbox token with only the scopes required for geocoding and set `MAPBOX_ACCESS_TOKEN`. Optionally use a production map style via `NEXT_PUBLIC_MAP_STYLE_URL`.

After deployment, use Admin → Territories to create the live service area. Draw polygon boundaries and/or configure eligible ZIP codes. Address eligibility checks the polygon first.

## 6. Email and SMS

For Resend, verify `trybinwell.com` (SPF/DKIM) and set `RESEND_API_KEY` plus a verified `RESEND_FROM_EMAIL`.

For Twilio, provision a messaging-capable number and set `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_FROM_NUMBER`. Complete any required U.S. messaging registration before production SMS traffic.

## 7. Municipal schedules

Configure actual local schedule data before activating customers. Use Admin → Schedules to manually verify records or import CSV. For a city/county with a stable official endpoint, implement that adapter in `lib/integrations/pickup-schedule.ts` and preserve manual override support.

## 8. Cron

`vercel.json` defines daily jobs for service-event generation and route-health inspection. Vercel can authenticate cron requests using the `CRON_SECRET` bearer value. Verify the cron invocations in Vercel after first deployment.

## 9. Domain

In Vercel → Project → Domains, add `trybinwell.com` and `www.trybinwell.com`. Follow Vercel’s displayed DNS records at your registrar. Choose `trybinwell.com` as canonical and redirect `www` to it. Confirm HTTPS before switching Supabase/Stripe redirect/webhook configuration to the live domain.

## 10. Production smoke test

Before accepting real subscriptions, complete the full checklist in `docs/TESTING.md` with Stripe test mode first, then one controlled live transaction. Verify a customer cannot open another customer’s data, a worker cannot open an unassigned route, holiday shifts detach stale stops, and a completed bin-out does not complete the later return.
