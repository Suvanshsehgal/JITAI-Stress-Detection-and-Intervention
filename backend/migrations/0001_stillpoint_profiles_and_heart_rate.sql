-- StillPoint / Stride Probe: database schema for the Flutter app.
-- Run this once in the Supabase dashboard: SQL Editor > New query > Run.
-- Safe to re-run (uses IF NOT EXISTS and DROP POLICY IF EXISTS).

-- ---------------------------------------------------------------------------
-- 1. Profiles: one row per auth user (username, buddy, onboarding status)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id                   uuid primary key references auth.users (id) on delete cascade,
  username             text unique check (char_length(username) between 3 and 32),
  buddy_name           text not null default 'Pip',
  buddy_tone           text not null default 'gentle'
                         check (buddy_tone in ('gentle', 'playful', 'straightTalking')),
  goals                text[] not null default '{}',
  onboarding_completed boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles: insert own" on public.profiles;
create policy "profiles: insert own" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Keep updated_at fresh on every update.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 2. Heart-rate readings from the Fireboltt 124 watch
-- ---------------------------------------------------------------------------
create table if not exists public.heart_rate_readings (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  recorded_at     timestamptz not null,           -- when the phone received the packet
  bpm             smallint not null check (bpm between 30 and 220),
  raw_hex         text not null,                  -- full packet, e.g. "BC 5C 03 01 67 67"
  device_name     text,
  device_address  text,
  source          text not null default 'fireboltt-124',
  created_at      timestamptz not null default now()
);

create index if not exists heart_rate_readings_user_time
  on public.heart_rate_readings (user_id, recorded_at desc);

alter table public.heart_rate_readings enable row level security;

drop policy if exists "hr: read own" on public.heart_rate_readings;
create policy "hr: read own" on public.heart_rate_readings
  for select using (auth.uid() = user_id);

drop policy if exists "hr: insert own" on public.heart_rate_readings;
create policy "hr: insert own" on public.heart_rate_readings
  for insert with check (auth.uid() = user_id);

drop policy if exists "hr: delete own" on public.heart_rate_readings;
create policy "hr: delete own" on public.heart_rate_readings
  for delete using (auth.uid() = user_id);
