-- Development-only, non-personal demo data. Create a development organization first.
insert into public.organizations (id,name,code) values ('00000000-0000-0000-0000-000000000001','Demo Hotel','DEMO') on conflict (code) do nothing;
insert into public.departments (organization_id,name,code) values ('00000000-0000-0000-0000-000000000001','Security','SEC') on conflict do nothing;
insert into public.posts (organization_id,code,name,is_required) values
('00000000-0000-0000-0000-000000000001','G1','Gate 1',true),('00000000-0000-0000-0000-000000000001','G2','Gate 2',true),('00000000-0000-0000-0000-000000000001','G3','Gate 3',true),('00000000-0000-0000-0000-000000000001','B1','Building 1',true),('00000000-0000-0000-0000-000000000001','ISLAND_INN','Island Inn',true),('00000000-0000-0000-0000-000000000001','RELIEVER','Reliever',true) on conflict do nothing;
insert into public.shifts (organization_id,code,name,starts_at,ends_at) values ('00000000-0000-0000-0000-000000000001','MORNING','Morning','06:00','14:00'),('00000000-0000-0000-0000-000000000001','NIGHT','Night','22:00','06:00') on conflict do nothing;
