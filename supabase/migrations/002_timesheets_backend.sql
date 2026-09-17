-- FICHE FORMATEUR V2 — schéma backend
-- À exécuter dans Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.correspondents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  role text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.weekly_sheets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  status text not null default 'draft' check (status in ('draft','submitted')),
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, week_start)
);

create table if not exists public.sheet_days (
  id uuid primary key default gen_random_uuid(),
  sheet_id uuid not null references public.weekly_sheets(id) on delete cascade,
  day_date date not null,
  day_type text not null default 'work' check (day_type in ('work','leave','rest')),
  manual_enabled boolean not null default true,
  driver_card_enabled boolean not null default false,
  time_card_enabled boolean not null default false,
  manual_start time,
  manual_end time,
  rest_minutes integer not null default 0 check (rest_minutes >= 0),
  vehicle text,
  teammate text,
  reason text,
  cabin_overnight_place text,
  hotel_name text,
  hotel_location text,
  no_pay_breakfast boolean not null default false,
  no_pay_lunch boolean not null default false,
  no_pay_dinner boolean not null default false,
  no_pay_night boolean not null default false,
  rh_extra boolean not null default false,
  unique(sheet_id, day_date)
);

create table if not exists public.email_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('weekly','monthly','test','reminder')),
  reference_date date,
  recipients text[] not null default '{}',
  sent_at timestamptz not null default now(),
  result text not null,
  details text
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  weekly_enabled boolean not null default false,
  weekly_day integer not null default 2 check (weekly_day between 0 and 6),
  weekly_time time not null default '18:00',
  weekly_correspondent_ids uuid[] not null default '{}',
  monthly_enabled boolean not null default false,
  monthly_day integer not null default 28 check (monthly_day between 1 and 31),
  monthly_time time not null default '18:00',
  monthly_correspondent_ids uuid[] not null default '{}',
  reminder_enabled boolean not null default false,
  reminder_day integer not null default 1 check (reminder_day between 0 and 6),
  reminder_time time not null default '18:00',
  reminder_method text not null default 'email' check (reminder_method in ('email','notification','both')),
  updated_at timestamptz not null default now()
);

alter table public.correspondents enable row level security;
alter table public.weekly_sheets enable row level security;
alter table public.sheet_days enable row level security;
alter table public.email_history enable row level security;
alter table public.user_settings enable row level security;

create policy "own correspondents" on public.correspondents for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own sheets" on public.weekly_sheets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own days" on public.sheet_days for all using (
  exists (select 1 from public.weekly_sheets s where s.id = sheet_id and s.user_id = auth.uid())
) with check (
  exists (select 1 from public.weekly_sheets s where s.id = sheet_id and s.user_id = auth.uid())
);
create policy "own history" on public.email_history for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own settings" on public.user_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists weekly_sheets_touch on public.weekly_sheets;
create trigger weekly_sheets_touch before update on public.weekly_sheets
for each row execute function public.touch_updated_at();

-- Durée calculée uniquement depuis les horaires manuels.
create or replace function public.manual_minutes(p_start time, p_end time, p_rest integer)
returns integer language sql immutable as $$
  select greatest(0,
    (extract(epoch from (p_end - p_start)) / 60)::integer - greatest(coalesce(p_rest,0),0)
  )
$$;
