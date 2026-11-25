-- Task Tracker: схема для Supabase (PostgreSQL).
-- Выполнить целиком: Supabase → SQL Editor → New query → вставить → Run. Скрипт можно запускать повторно.

create or replace function public.tt_touch() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

-- Основные сущности. Структура строки одинакова: id, владелец, проект, данные (jsonb), время изменения.
do $$
declare t text;
begin
  foreach t in array array['projects','tasks','diary','comments','notifications','history','attachments'] loop
    execute format('create table if not exists public.%I (
      id text primary key,
      owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
      project_id text,
      data jsonb not null,
      updated_at timestamptz not null default now())', t);
    execute format('create index if not exists %I on public.%I (owner_id, project_id)', t || '_owner_project_idx', t);
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists tt_owner_all on public.%I', t);
    -- Доступ только к своим строкам и только авторизованным пользователям.
    execute format('create policy tt_owner_all on public.%I for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid())', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('drop trigger if exists %I on public.%I', t || '_touch', t);
    execute format('create trigger %I before update on public.%I for each row execute function public.tt_touch()', t || '_touch', t);
  end loop;
end $$;

-- Настройки пользователя (одна строка на пользователя).
create table if not exists public.settings (
  owner_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now());
alter table public.settings enable row level security;
drop policy if exists tt_owner_all on public.settings;
create policy tt_owner_all on public.settings for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
revoke all on public.settings from anon;
grant select, insert, update, delete on public.settings to authenticated;
drop trigger if exists settings_touch on public.settings;
create trigger settings_touch before update on public.settings for each row execute function public.tt_touch();

-- Realtime: изменения сразу приходят на другие устройства.
do $$
declare t text;
begin
  foreach t in array array['projects','tasks','diary','comments','notifications','history','attachments','settings'] loop
    begin execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null; end;
  end loop;
end $$;
