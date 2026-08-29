# Operations Playbook

## Daily owner/dispatcher flow

1. Daily cron generates upcoming service events and monthly cleaning obligations.
2. Review Admin → Operations for late/at-risk/exception work and Admin → Schedules for any holiday changes.
3. Regenerate routes after schedule, vacation, territory, or major property-instruction changes.
4. Confirm workers/routes in Admin → Routes.
5. During service, watch completion/exception status. Worker actions persist immediately.
6. Resolve operational exceptions; reassigned events return to route-ready state.
7. After municipal pickup, return routes remain independently outstanding until every return is completed/skipped/exceptioned.

## Common exceptions

- **Gate locked / blocked access / pet issue:** worker reports exception; operations contacts customer or reassigns after resolution.
- **Municipality missed pickup:** leave the return event blocked until a verified pickup or explicit reschedule; do not falsely complete the return.
- **Bins already at curb:** report as operational exception/observation if local policy requires proof, then resolve according to service policy.
- **Holiday shift:** enter one zone-level override; the system moves all affected future service events, detaches stale route assignments, then routing can be regenerated.
- **Worker callout / vehicle failure:** regenerate or reassign affected route work to another active worker in the zone.
- **Vacation:** customer can skip future events outside the route-lock window; near-term changes should be handled by operations.
- **Late property instruction change:** customer edits inside 48 hours automatically produce an operations issue.
- **Cleaning blocked because bin is full:** report exception and postpone the cleaning obligation rather than marking it complete.

## Data hygiene

Verify pickup schedules before the first live visit. Keep bin counts and storage/access photos/instructions current. Do not put sensitive customer information into generic notes when a structured field exists. Restrict gate/access codes to personnel who need them to complete service.
