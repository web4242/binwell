# Testing and Validation

## Automated checks

```bash
npm run test:domain
npm run typecheck
npm run build
```

`tests/domain.test.ts` verifies distance/order behavior, route construction, holiday scheduling, cleaning batching, multi-bin-type municipal event generation, and service-state transitions.

## Critical manual test matrix

Before launch, verify in a local/staging project with sandbox provider credentials:

1. Eligible address → both plan choices → property/contact → Stripe Checkout → webhook activation.
2. Ineligible address → waitlist capture.
3. Customer magic-link login and ownership isolation.
4. Property/bin/access edit and the <48-hour operations warning.
5. Vacation skip outside the 12-hour lock.
6. Manual pickup schedule edit and CSV import.
7. Two garbage days plus a separate recycling day.
8. Holiday zone shift and route regeneration.
9. Route generation, worker assignment, phone PWA, navigation, stop completion.
10. Gate/unsafe/municipal-pickup exception and operations resolution.
11. Return stop remains outstanding after bin-out completion.
12. Monthly cleaning event generation and route.
13. Failed Stripe invoice → past-due state; paid invoice → recovery.
14. Customer billing portal and cancellation.
15. Staff invite; invited field worker lands on worker surface, not customer surface.
16. Territory polygon drawing and address eligibility near polygon edges.
17. RLS using separate owner, worker, and customer test identities.
18. Responsive layouts at narrow phone and tablet widths.

## Validation performed in this artifact build

The project was validated with the executable domain test suite and a TypeScript parser/transpilation pass across all `.ts/.tsx` source files. A full dependency install/Next.js production build could not be executed in the artifact environment because the package registry was unreachable; run `npm install && npm run typecheck && npm run build` in a networked development/CI environment before production deployment.
