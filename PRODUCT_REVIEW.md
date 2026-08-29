# Product Review

## Customer

The path starts with one address field, then plan, minimal property setup, contact, and billing. Property setup uses structured storage-location choices instead of relying on free text. Customers can correct operational information, skip future service, control notifications, view visit status/history, contact support, and reach billing without calling the owner.

Remaining launch work is provider configuration and real jurisdiction schedule sourcing for the territories actually served; the platform deliberately does not pretend a universal municipal lookup exists.

## Field worker

The worker surface is separate from admin and optimized for a phone. It prioritizes next stop, navigation, relevant bin types/counts, storage/access instructions, and a single completion action. Exceptions are one-tap categories and immediately become operational issues. The PWA can be installed to a home screen.

For very large crews, add offline write queuing and background sync after observing actual cellular dead zones; the current service-worker shell is intentionally conservative rather than risking stale operational writes.

## Operations manager

The system distinguishes scheduled, assigned, completed, exception, skipped, late, and at-risk work and keeps bin-out/return separate. Holiday changes can be shifted across a zone. Routes can be regenerated around current work, and customer changes near service create a visible issue instead of silently altering the route.

## Owner

The owner gets one operating system for revenue/customer status, routes, workers, support, territories, waitlist demand, municipal schedules, and performance. The data model supports expansion without rewriting customer/service history. The largest future optimization is moving high-volume state mutations from the launch repository abstraction into targeted SQL/RPC commands as volume grows; this is an implementation optimization, not a product/schema rebuild.
