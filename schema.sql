-- SMAN 15 Bandung - Struktur Organisasi Online
-- Jalankan di Supabase SQL Editor

create table if not exists public.org_members (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null default '',
  role text not null,
  parent_key text,
  group_key text,
  sort_order integer not null default 0,
  photo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists org_members_parent_idx on public.org_members(parent_key);
create index if not exists org_members_group_idx on public.org_members(group_key);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists org_members_updated_at on public.org_members;
create trigger org_members_updated_at before update on public.org_members
for each row execute function public.set_updated_at();

alter table public.org_members enable row level security;

drop policy if exists "public can read active members" on public.org_members;
create policy "public can read active members" on public.org_members
for select using (active = true);

drop policy if exists "authenticated can manage members" on public.org_members;
create policy "authenticated can manage members" on public.org_members
for all to authenticated using (true) with check (true);

insert into public.org_members (key,name,role,parent_key,group_key,sort_order) values
('kepala','Kepala Sekolah','Kepala Sekolah',null,'top',1),
('korlas','Ketua Korlas','Ketua Korlas','kepala','top',2),
('kurikulum','Wakasek Bid. Kurikulum','Wakasek Bid. Kurikulum','kepala','kurikulum',1),
('kesiswaan','Wakasek Bid. Kesiswaan','Wakasek Bid. Kesiswaan','kepala','kesiswaan',2),
('sarpras','Wakasek Bid. Sarpras','Wakasek Bid. Sarpras','kepala','sarpras',3),
('humas','Wakasek Bid. Humas','Wakasek Bid. Humas','kepala','humas',4),
('bk','Koordinator Guru BK','Koordinator Guru BK','kepala','bk',5)
on conflict (key) do update set role=excluded.role, parent_key=excluded.parent_key, group_key=excluded.group_key;

insert into public.org_members (key,name,role,parent_key,group_key,sort_order)
select 'kurikulum-'||i,'','Staf Kurikulum','kurikulum','kurikulum',i from generate_series(1,4) i
on conflict (key) do nothing;
insert into public.org_members (key,name,role,parent_key,group_key,sort_order)
select 'kesiswaan-'||i,'','Staf Kesiswaan','kesiswaan','kesiswaan',i from generate_series(1,4) i
on conflict (key) do nothing;
insert into public.org_members (key,name,role,parent_key,group_key,sort_order)
select 'sarpras-'||i,'','Staf Sarpras','sarpras','sarpras',i from generate_series(1,2) i
on conflict (key) do nothing;
insert into public.org_members (key,name,role,parent_key,group_key,sort_order)
select 'humas-'||i,'','Staf Humas','humas','humas',i from generate_series(1,3) i
on conflict (key) do nothing;
insert into public.org_members (key,name,role,parent_key,group_key,sort_order)
select 'bk-'||i,'','Guru BK','bk','bk',i from generate_series(1,4) i
on conflict (key) do nothing;
insert into public.org_members (key,name,role,parent_key,group_key,sort_order)
select 'wali-'||i,'','Wali Kelas '||i,null,'wali',i from generate_series(1,35) i
on conflict (key) do nothing;

-- Storage: buat bucket bernama org-photos dari Dashboard Storage.
-- Setelah bucket dibuat sebagai Public, policy berikut dapat dipakai:

insert into storage.buckets (id,name,public)
values ('org-photos','org-photos',true)
on conflict (id) do update set public=true;

drop policy if exists "public read org photos" on storage.objects;
create policy "public read org photos" on storage.objects for select using (bucket_id='org-photos');

drop policy if exists "authenticated upload org photos" on storage.objects;
create policy "authenticated upload org photos" on storage.objects for insert to authenticated with check (bucket_id='org-photos');

drop policy if exists "authenticated update org photos" on storage.objects;
create policy "authenticated update org photos" on storage.objects for update to authenticated using (bucket_id='org-photos');

drop policy if exists "authenticated delete org photos" on storage.objects;
create policy "authenticated delete org photos" on storage.objects for delete to authenticated using (bucket_id='org-photos');
