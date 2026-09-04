import { readFileSync } from 'node:fs';
const sql=readFileSync('supabase/migrations/001_initial_schema.sql','utf8');
for (const marker of ['create table public.organizations','create table public.audit_logs','enable row level security','create policy audit_read','protect_user_role']) if(!sql.includes(marker)) throw new Error(`Missing migration marker: ${marker}`);
console.log('Migration static checks passed: schema, RLS, audit, and authorization guard present.');
