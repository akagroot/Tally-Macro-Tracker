-- Tally — Supabase schema
-- Run this once in the Supabase SQL editor (or via `supabase db push`) before running seed.sql.
--
-- Design notes (read before changing anything):
--
-- 1. NO AUTH YET. Every per-user table carries a `user_id` column defaulted to a fixed constant
--    UUID (APP_USER_ID below) so the schema is ready for real multi-user auth later without a
--    rewrite, even though today there's only ever one user. When you add Supabase Auth, swap the
--    default/RLS policies to `auth.uid()` and backfill this constant to real user ids.
--
-- 2. RLS is enabled everywhere but the policies currently allow the `anon` key full access.
--    That's necessary right now because there's no auth session to check against — but it does
--    mean anyone who extracts your anon key from the compiled app could read/write this data
--    (including weight_log). Acceptable for a personal, undistributed app; MUST be tightened
--    (auth-scoped policies) before this app is ever shared with anyone else or put on TestFlight.
--
-- 3. Calories are never stored — always derive them as `protein_g*4 + carbs_g*4 + fat_g*9`,
--    matching the prototype's `kcal()` helper exactly. Keep this formula identical everywhere
--    (SQL views, Swift) so numbers never drift between layers.
--
-- 4. Macro amounts on `foods`/`food_variants` are "per one native unit" (e.g. per egg, per slice,
--    per oz for oz-native foods) — NOT per gram. Convert through `grams_per_unit` to get per-gram,
--    then multiply by whatever unit you're displaying in. Exception: item_mode foods (Oreos, Chips
--    Ahoy) store macros per labeled serving (items_per_serving cookies), not per single item —
--    divide by items_per_serving to get per-cookie, same as the prototype's quickFoodDef().

create extension if not exists pgcrypto; -- gen_random_uuid()

-- Swap this for auth.uid() everywhere once real accounts exist.
-- (Referenced only in comments/seed below — Postgres has no "constants", so the same literal
-- UUID is repeated in each default and in seed.sql. Keep it in sync if you ever change it.)
-- APP_USER_ID = '00000000-0000-0000-0000-000000000001'

-- ---------- catalog ----------

create table foods (
  id                text primary key,          -- stable slug, e.g. 'chicken', 'egg'
  name              text not null,
  emoji             text not null,
  is_custom         boolean not null default false,

  unit              text,                      -- native unit label ('oz','egg','slice'...); null when item_mode
  pluralize         boolean not null default false,
  step              numeric,
  btn_step          numeric,
  min_qty           numeric,
  max_qty           numeric,
  default_qty       numeric,
  grams_per_unit    numeric,                   -- null when item_mode

  native_is_oz      boolean not null default false,
  pick_required     boolean not null default false,  -- forces explicit cut/variant choice, no silent default

  item_mode         boolean not null default false,
  items_per_serving numeric,
  item_name         text,

  protein_g         numeric not null default 0,  -- per native unit (or per labeled serving if item_mode)
  carbs_g           numeric not null default 0,
  fat_g             numeric not null default 0,

  macro_tag         text not null default 'other' check (macro_tag in ('p','c','f','other')),
  meal_tags         text[] not null default '{}', -- e.g. {breakfast,mains,snack} — filter tags, not a log restriction

  -- Soft reference (no FK) to food_variants.id — avoids a circular FK between the two tables.
  -- The app is responsible for keeping this pointed at a real row in food_variants.
  default_variant_id text,

  last_used_at      timestamptz,               -- maintained by trigger below; drives the "Usual" sort
  created_at        timestamptz not null default now()
);

create table food_variants (
  id             text primary key,             -- e.g. 'chicken-breast'
  food_id        text not null references foods(id) on delete cascade,
  name           text not null,

  protein_g      numeric not null,
  carbs_g        numeric not null,
  fat_g          numeric not null,

  -- Any of these left null means "inherit from the parent food" (matches unitDefFor's pick() fallback).
  unit           text,
  pluralize      boolean,
  step           numeric,
  btn_step       numeric,
  min_qty        numeric,
  max_qty        numeric,
  default_qty    numeric,
  grams_per_unit numeric,

  sort_order     int not null default 0
);

create index idx_food_variants_food on food_variants(food_id);

-- Keep last_used_at current automatically instead of hand-maintaining a fake usage counter
-- (the prototype's lastUsedAt was just seed data — this trigger makes "Usual" sort reflect reality).
create or replace function touch_food_last_used() returns trigger as $$
begin
  update foods set last_used_at = new.created_at where id = new.food_id;
  return new;
end;
$$ language plpgsql;

-- ---------- personal data (all scoped to a single hardcoded user for now) ----------

create table log_entries (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default '00000000-0000-0000-0000-000000000001',
  log_date     date not null,
  meal         text not null check (meal in ('breakfast','lunch','dinner','snack')),
  food_id      text not null references foods(id),
  variant_id   text references food_variants(id),
  qty          numeric not null,
  unit_key     text not null,                  -- 'native' | 'oz' | 'g'
  unit_label   text not null,                  -- display string at log time, e.g. "4 oz", "2 eggs"

  -- Snapshotted at log time so editing a food's macros later never rewrites history.
  protein_g    numeric not null,
  carbs_g      numeric not null,
  fat_g        numeric not null,

  sort_order   int not null default 0,
  created_at   timestamptz not null default now()
);

create index idx_log_entries_day on log_entries(user_id, log_date);

create trigger trg_log_entries_touch_food
  after insert on log_entries
  for each row execute function touch_food_last_used();

create table meal_templates (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default '00000000-0000-0000-0000-000000000001',
  name       text not null,
  -- References, not frozen macros — re-applying a template always uses current food data,
  -- same deliberate choice as the prototype: [{food_id, variant_id, qty, unit_key}, ...]
  items      jsonb not null,
  created_at timestamptz not null default now()
);

create table water_log (
  user_id  uuid not null default '00000000-0000-0000-0000-000000000001',
  log_date date not null,
  oz       numeric not null default 0,
  primary key (user_id, log_date)
);

create table weight_log (
  user_id  uuid not null default '00000000-0000-0000-0000-000000000001',
  log_date date not null,
  lbs      numeric not null,
  primary key (user_id, log_date)
);

create table user_settings (
  user_id           uuid primary key default '00000000-0000-0000-0000-000000000001',
  protein_target_g  numeric not null default 180,
  carbs_target_g    numeric not null default 240,
  fat_target_g      numeric not null default 70,
  calorie_target    numeric not null default 2310,
  water_target_oz   numeric not null default 100
);

insert into user_settings (user_id) values ('00000000-0000-0000-0000-000000000001');

-- ---------- RLS ----------
-- Open to the anon key for now (see note #2 above). Tighten to auth.uid()-scoped policies
-- before this app is ever distributed to anyone but you.

alter table foods           enable row level security;
alter table food_variants   enable row level security;
alter table log_entries     enable row level security;
alter table meal_templates  enable row level security;
alter table water_log       enable row level security;
alter table weight_log      enable row level security;
alter table user_settings   enable row level security;

create policy "anon full access" on foods           for all to anon using (true) with check (true);
create policy "anon full access" on food_variants   for all to anon using (true) with check (true);
create policy "anon full access" on log_entries     for all to anon using (true) with check (true);
create policy "anon full access" on meal_templates  for all to anon using (true) with check (true);
create policy "anon full access" on water_log       for all to anon using (true) with check (true);
create policy "anon full access" on weight_log      for all to anon using (true) with check (true);
create policy "anon full access" on user_settings   for all to anon using (true) with check (true);
