# HotelSecOps — Phase 1 Foundation

A tenant-scoped foundation for hotel safety and security operations, built with Next.js, TypeScript, Tailwind CSS, PostgreSQL, and Supabase.

## Included
- Phase 1 schema for organizations, department and employee directory, posts, shifts, schedules, leave/absence, replacements, users, and immutable audit events.
- Supabase Auth-compatible `users` profile table; passwords are never stored in application tables.
- RLS tenant isolation and authorization guards. Service-role keys remain server-only.
- Scheduler conflict foundation only; it does **not** generate schedules or invent staffing rules. G2/IS GARCIA handling is surfaced as an explicit conflict rule for configuration/integration.
- Professional dashboard shell; all future navigation is non-functional and labelled as future work.

## Local setup
1. `cp .env.example .env.local` and populate the public Supabase URL and anon key.
2. Create a Supabase project, then apply `supabase/migrations/001_initial_schema.sql` through the Supabase CLI or SQL editor. Apply `supabase/seed.sql` only to development.
3. `npm install`, then run `npm run dev`.

## Verification
Run `npm run typecheck`, `npm run lint`, `npm test`, `npm run verify:migrations`, and `npm run build`.

## Security notes and limitations
RLS is enabled on every Phase 1 table; records are scoped to the authenticated user organization. Audit logs have no client mutation policy. Role modification is guarded in PostgreSQL against self-escalation. Production provisioning of the first super administrator must occur in a secure backend/admin workflow. No video upload, automatic schedule generation, or Phase 2 module behavior is implemented.
