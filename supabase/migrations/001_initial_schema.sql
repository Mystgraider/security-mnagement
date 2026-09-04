-- HotelSecOps Phase 1: tenant-scoped, auditable operational foundation.
create extension if not exists pgcrypto;
create type public.app_role as enum ('SUPER_ADMIN','MANAGEMENT','SECURITY_MANAGER','SECURITY_OFFICER','SECURITY_SUPERVISOR','SECURITY_GUARD','DEPARTMENT_HEAD','HR','VIEWER');
create type public.request_status as enum ('PENDING','APPROVED','REJECTED','CANCELLED');
create type public.schedule_status as enum ('DRAFT','PUBLISHED','ARCHIVED');
create type public.absence_type as enum ('EMERGENCY','NO_SHOW','OTHER');

create table public.organizations (id uuid primary key default gen_random_uuid(), name text not null check (char_length(trim(name)) between 2 and 160), code text not null unique check (code ~ '^[A-Z0-9_-]+$'), is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.departments (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), name text not null check (char_length(trim(name)) between 2 and 120), code text not null check (code ~ '^[A-Z0-9_-]+$'), is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(organization_id,code));
create table public.users (id uuid primary key references auth.users(id) on delete cascade, organization_id uuid references public.organizations(id), role public.app_role not null default 'VIEWER', employee_id uuid unique, is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.employees (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), department_id uuid references public.departments(id), employee_number text not null, first_name text not null check(char_length(trim(first_name))>0), last_name text not null check(char_length(trim(last_name))>0), job_title text, is_active boolean not null default true, archived_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(organization_id,employee_number));
alter table public.users add constraint users_employee_fk foreign key(employee_id) references public.employees(id) on delete set null;
create table public.posts (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), code text not null, name text not null, location text, is_required boolean not null default false, is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(organization_id,code));
create table public.shifts (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), code text not null, name text not null, starts_at time not null, ends_at time not null, is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(organization_id,code), check(starts_at <> ends_at));
create table public.duty_schedules (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), employee_id uuid not null references public.employees(id), post_id uuid not null references public.posts(id), shift_id uuid not null references public.shifts(id), duty_date date not null, status public.schedule_status not null default 'DRAFT', published_at timestamptz, published_by uuid references public.users(id), notes text check(char_length(coalesce(notes,'')) <= 2000), archived_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(employee_id,duty_date), unique(post_id,shift_id,duty_date));
create table public.leave_requests (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), employee_id uuid not null references public.employees(id), start_date date not null, end_date date not null, reason text not null check(char_length(trim(reason)) between 1 and 1000), status public.request_status not null default 'PENDING', reviewed_by uuid references public.users(id), reviewed_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(end_date >= start_date));
create table public.absence_records (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), employee_id uuid not null references public.employees(id), absence_date date not null, type public.absence_type not null, notes text check(char_length(coalesce(notes,'')) <= 2000), recorded_by uuid references public.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(employee_id,absence_date));
create table public.shift_replacements (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), duty_schedule_id uuid not null references public.duty_schedules(id), original_employee_id uuid not null references public.employees(id), replacement_employee_id uuid not null references public.employees(id), status public.request_status not null default 'PENDING', approved_by uuid references public.users(id), approved_at timestamptz, reason text not null check(char_length(trim(reason)) between 1 and 1000), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(original_employee_id <> replacement_employee_id));
create table public.audit_logs (id uuid primary key default gen_random_uuid(), organization_id uuid references public.organizations(id), actor_id uuid references public.users(id), action text not null, table_name text not null, record_id uuid, old_data jsonb, new_data jsonb, created_at timestamptz not null default now());
create index idx_employees_org_department on public.employees(organization_id,department_id) where archived_at is null;
create index idx_duty_schedules_org_date on public.duty_schedules(organization_id,duty_date);
create index idx_leave_requests_employee_dates on public.leave_requests(employee_id,start_date,end_date);
create index idx_audit_logs_org_created on public.audit_logs(organization_id,created_at desc);

create function public.current_org_id() returns uuid language sql stable security definer set search_path=public as $$select organization_id from public.users where id=auth.uid()$$;
create function public.current_role() returns public.app_role language sql stable security definer set search_path=public as $$select role from public.users where id=auth.uid()$$;
create function public.is_manager() returns boolean language sql stable security definer set search_path=public as $$select public.current_role() in ('SUPER_ADMIN','MANAGEMENT','SECURITY_MANAGER','HR')$$;
create function public.touch_updated_at() returns trigger language plpgsql as $$begin new.updated_at=now(); return new; end$$;
create function public.audit_row() returns trigger language plpgsql security definer set search_path=public as $$begin insert into public.audit_logs(organization_id,actor_id,action,table_name,record_id,old_data,new_data) values (coalesce(new.organization_id,old.organization_id),auth.uid(),tg_op,tg_table_name,coalesce(new.id,old.id),case when tg_op='INSERT' then null else to_jsonb(old) end,case when tg_op='DELETE' then null else to_jsonb(new) end); return coalesce(new,old); end$$;

create or replace function public.protect_user_role() returns trigger language plpgsql as $$
begin
  if new.id = auth.uid() then
    if new.role is distinct from old.role or new.organization_id is distinct from old.organization_id or (old.is_active and not new.is_active) then
      raise exception 'Users cannot modify their own authorization profile';
    end if;
  end if;
  if new.role is distinct from old.role or new.organization_id is distinct from old.organization_id or new.is_active is distinct from old.is_active then
    if public.current_role() <> 'SUPER_ADMIN' then raise exception 'Authorization changes require SUPER_ADMIN'; end if;
    if new.role = 'SUPER_ADMIN' and old.role <> 'SUPER_ADMIN' then raise exception 'SUPER_ADMIN provisioning requires secure backend administration'; end if;
  end if;
  return new;
end $$;

-- All tenant tables are protected; no policy grants anonymous access.
alter table public.organizations enable row level security;
alter table public.departments enable row level security;
alter table public.users enable row level security;
alter table public.employees enable row level security;
alter table public.posts enable row level security;
alter table public.shifts enable row level security;
alter table public.duty_schedules enable row level security;
alter table public.leave_requests enable row level security;
alter table public.absence_records enable row level security;
alter table public.shift_replacements enable row level security;
alter table public.audit_logs enable row level security;
create policy organization_read on public.organizations for select using (id=public.current_org_id());
create policy organization_manage on public.organizations for update using (id=public.current_org_id() and public.current_role()='SUPER_ADMIN') with check (id=public.current_org_id());
create policy user_read on public.users for select using (id=auth.uid() or (organization_id=public.current_org_id() and public.current_role()='SUPER_ADMIN'));
create policy user_admin_update on public.users for update using (organization_id=public.current_org_id() and public.current_role()='SUPER_ADMIN') with check (organization_id=public.current_org_id());
create policy departments_read on public.departments for select using (organization_id=public.current_org_id());
create policy departments_manage on public.departments for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy employees_read on public.employees for select using (organization_id=public.current_org_id());
create policy employees_manage on public.employees for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy posts_read on public.posts for select using (organization_id=public.current_org_id());
create policy posts_manage on public.posts for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy shifts_read on public.shifts for select using (organization_id=public.current_org_id());
create policy shifts_manage on public.shifts for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy schedules_read on public.duty_schedules for select using (organization_id=public.current_org_id());
create policy schedules_manage on public.duty_schedules for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy leave_read on public.leave_requests for select using (organization_id=public.current_org_id());
create policy leave_create on public.leave_requests for insert with check (organization_id=public.current_org_id());
create policy leave_manage on public.leave_requests for update using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy absence_read on public.absence_records for select using (organization_id=public.current_org_id());
create policy absence_manage on public.absence_records for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy replacement_read on public.shift_replacements for select using (organization_id=public.current_org_id());
create policy replacement_manage on public.shift_replacements for all using (organization_id=public.current_org_id() and public.is_manager()) with check (organization_id=public.current_org_id() and public.is_manager());
create policy audit_read on public.audit_logs for select using (organization_id=public.current_org_id() and public.is_manager());

create trigger departments_touch before update on public.departments for each row execute function public.touch_updated_at();
create trigger employees_touch before update on public.employees for each row execute function public.touch_updated_at();
create trigger posts_touch before update on public.posts for each row execute function public.touch_updated_at();
create trigger shifts_touch before update on public.shifts for each row execute function public.touch_updated_at();
create trigger schedules_touch before update on public.duty_schedules for each row execute function public.touch_updated_at();
create trigger leave_touch before update on public.leave_requests for each row execute function public.touch_updated_at();
create trigger absence_touch before update on public.absence_records for each row execute function public.touch_updated_at();
create trigger replacements_touch before update on public.shift_replacements for each row execute function public.touch_updated_at();
create trigger users_authorization_guard before update on public.users for each row execute function public.protect_user_role();
create trigger employees_audit after insert or update or delete on public.employees for each row execute function public.audit_row();
create trigger schedules_audit after insert or update or delete on public.duty_schedules for each row execute function public.audit_row();
create trigger leave_audit after insert or update or delete on public.leave_requests for each row execute function public.audit_row();
create trigger replacements_audit after insert or update or delete on public.shift_replacements for each row execute function public.audit_row();

-- No DELETE policy is deliberately defined for Phase 1 operational records; archive fields retain history.
