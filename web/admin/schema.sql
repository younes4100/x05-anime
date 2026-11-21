-- X05 ANIME website + admin panel schema for Supabase/Postgres.
-- Run in Supabase SQL Editor (or psql) as the project owner.

create extension if not exists pgcrypto;

-- ── Admin allowlist ───────────────────────────────────────────────────────────
create table if not exists public.admin_emails (
  email text primary key,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_emails ae
    where lower(ae.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- ── App content tables ────────────────────────────────────────────────────────
create table if not exists public.app_announcements (
  id uuid primary key default gen_random_uuid(),
  title_ar text,
  title_en text,
  body_ar text,
  body_en text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.app_releases (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  apk_url text not null,
  notes_ar text,
  notes_en text,
  published boolean not null default true,
  published_at timestamptz not null default now()
);

create table if not exists public.app_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  title text not null,
  category text,
  details text,
  status text not null default 'open' check (status in ('open','reviewing','resolved')),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_audit (
  id bigint generated always as identity primary key,
  actor text,
  table_name text not null,
  action text not null,
  row_data jsonb,
  created_at timestamptz not null default now()
);

-- ── RLS policies ──────────────────────────────────────────────────────────────
alter table public.admin_emails enable row level security;
alter table public.app_announcements enable row level security;
alter table public.app_releases enable row level security;
alter table public.app_reports enable row level security;
alter table public.admin_audit enable row level security;

drop policy if exists "admin_all_admin_emails" on public.admin_emails;
create policy "admin_all_admin_emails" on public.admin_emails
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public_read_active_announcements" on public.app_announcements;
create policy "public_read_active_announcements" on public.app_announcements
  for select to anon, authenticated using (active);
drop policy if exists "admin_all_announcements" on public.app_announcements;
create policy "admin_all_announcements" on public.app_announcements
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public_read_published_releases" on public.app_releases;
create policy "public_read_published_releases" on public.app_releases
  for select to anon, authenticated using (published);
drop policy if exists "admin_all_releases" on public.app_releases;
create policy "admin_all_releases" on public.app_releases
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "users_insert_own_reports" on public.app_reports;
create policy "users_insert_own_reports" on public.app_reports
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "users_read_own_reports" on public.app_reports;
create policy "users_read_own_reports" on public.app_reports
  for select to authenticated using (auth.uid() = user_id);
drop policy if exists "admin_all_reports" on public.app_reports;
create policy "admin_all_reports" on public.app_reports
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin_read_audit" on public.admin_audit;
create policy "admin_read_audit" on public.admin_audit
  for select to authenticated using (public.is_admin());

grant usage on schema public to anon, authenticated;
grant select on public.app_announcements, public.app_releases to anon, authenticated;
grant all on public.app_announcements, public.app_releases, public.app_reports,
  public.admin_emails, public.admin_audit to authenticated;

-- ── Admin RPCs ────────────────────────────────────────────────────────────────
create or replace function public.admin_dashboard_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  select jsonb_build_object(
    'users', (select count(*) from auth.users),
    'announcements', (select count(*) from public.app_announcements),
    'releases', (select count(*) from public.app_releases where published),
    'open_reports', (select count(*) from public.app_reports where status = 'open')
  ) into result;
  return result;
end;
$$;

create or replace function public.admin_list_users()
returns table (id uuid, email text, created_at timestamptz, last_sign_in_at timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return query
    select u.id, u.email, u.created_at, u.last_sign_in_at
    from auth.users u order by u.created_at desc limit 500;
end;
$$;

revoke all on function public.admin_dashboard_stats(), public.admin_list_users() from public, anon;
grant execute on function public.admin_dashboard_stats(), public.admin_list_users() to authenticated;

-- ── Audit trigger ─────────────────────────────────────────────────────────────
create or replace function public.admin_audit_log()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_data jsonb;
begin
  if TG_OP = 'DELETE' then
    v_data := to_jsonb(OLD);
  else
    v_data := to_jsonb(NEW);
  end if;
  insert into public.admin_audit(actor, table_name, action, row_data)
  values (auth.jwt() ->> 'email', TG_TABLE_NAME, TG_OP, v_data);
  return coalesce(NEW, OLD);
end;
$$;

drop trigger if exists audit_announcements on public.app_announcements;
create trigger audit_announcements after insert or update or delete on public.app_announcements
  for each row execute function public.admin_audit_log();
drop trigger if exists audit_releases on public.app_releases;
create trigger audit_releases after insert or update or delete on public.app_releases
  for each row execute function public.admin_audit_log();
drop trigger if exists audit_reports on public.app_reports;
create trigger audit_reports after update or delete on public.app_reports
  for each row execute function public.admin_audit_log();
drop trigger if exists audit_admin_emails on public.admin_emails;
create trigger audit_admin_emails after insert or delete on public.admin_emails
  for each row execute function public.admin_audit_log();

-- ── Bootstrap ─────────────────────────────────────────────────────────────────
-- Insert your own email once, then you can add others from the admin panel:
-- insert into public.admin_emails(email) values ('innerhnghto@gmail.com') on conflict do nothing;
