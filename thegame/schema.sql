-- The shared log behind https://davidwbean.com/thegame
--
-- Run this once: Supabase dashboard -> SQL Editor -> New query -> paste -> Run.
-- It is safe to run again; nothing here drops data.
--
-- The page talks to these tables with the anon key, which is published in the
-- HTML and therefore known to anyone who opens the page. That is the point --
-- anyone with the link can edit -- but it means the guard rails have to live
-- here, in the database, rather than in the page. They are:
--   * only these two tables are reachable, and only these columns
--   * values are bounded, so a bad actor can't park a novel in a note
--   * the log has a ceiling, so it can't be filled until it costs money
--   * every change is copied to game_audit, which the anon key cannot read,
--     write, or erase -- so anything done through the page can be undone

-- ---------------------------------------------------------------- tables --
-- entries.type_id is deliberately NOT a foreign key. The page already copes
-- with an entry whose type was deleted, and a constraint here would instead
-- make the delete fail halfway through a sync.

create table if not exists public.game_types (
  id         text primary key,
  name       text    not null default ''         check (length(name) <= 120),
  kind       text    not null default 'sighting' check (kind in ('sighting', 'deed', 'misconduct', 'activity')),
  points     integer                             check (points between -100000 and 100000),
  scope      text    not null default 'animal'   check (scope in ('animal', 'herd')),
  updated_at timestamptz not null default now()
);

create table if not exists public.game_entries (
  id         text primary key,
  kid        text    not null default ''  check (length(kid) <= 60),
  type_id    text,
  day        integer not null default 1   check (day between 1 and 36500),
  qty        integer not null default 0   check (qty between 0 and 1000000),
  note       text    not null default ''  check (length(note) <= 500),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------ who can act --
alter table public.game_types   enable row level security;
alter table public.game_entries enable row level security;

grant select, insert, update, delete on public.game_types   to anon;
grant select, insert, update, delete on public.game_entries to anon;

do $$
declare t text;
begin
  foreach t in array array['game_types', 'game_entries'] loop
    execute format('drop policy if exists anyone_read   on public.%I', t);
    execute format('drop policy if exists anyone_add    on public.%I', t);
    execute format('drop policy if exists anyone_change on public.%I', t);
    execute format('drop policy if exists anyone_remove on public.%I', t);
    execute format('create policy anyone_read   on public.%I for select to anon using (true)', t);
    execute format('create policy anyone_add    on public.%I for insert to anon with check (true)', t);
    execute format('create policy anyone_change on public.%I for update to anon using (true) with check (true)', t);
    execute format('create policy anyone_remove on public.%I for delete to anon using (true)', t);
  end loop;
end $$;

-- --------------------------------------------------------- when it changed --
create or replace function public.game_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists game_types_touch   on public.game_types;
drop trigger if exists game_entries_touch on public.game_entries;
create trigger game_types_touch   before update on public.game_types   for each row execute function public.game_touch();
create trigger game_entries_touch before update on public.game_entries for each row execute function public.game_touch();

-- ------------------------------------------------------------- a ceiling --
-- A statement-level check, so one enormous insert is caught as cheaply as a
-- thousand small ones.
create or replace function public.game_cap() returns trigger
language plpgsql as $$
declare n bigint;
begin
  execute format('select count(*) from public.%I', tg_table_name) into n;
  if n > tg_argv[0]::bigint then
    raise exception 'the % log is full (% rows)', tg_table_name, n;
  end if;
  return null;
end $$;

drop trigger if exists game_types_cap   on public.game_types;
drop trigger if exists game_entries_cap on public.game_entries;
create trigger game_types_cap   after insert on public.game_types   for each statement execute function public.game_cap('2000');
create trigger game_entries_cap after insert on public.game_entries for each statement execute function public.game_cap('50000');

-- ----------------------------------------------------------- undo history --
-- Written by a security-definer trigger, so rows land here even though anon
-- has no rights on the table. Read it from the SQL editor, never from the page.
create table if not exists public.game_audit (
  seq     bigserial primary key,
  at      timestamptz not null default now(),
  tbl     text not null,
  op      text not null,
  row_id  text,
  before  jsonb,
  after   jsonb
);
alter table public.game_audit enable row level security;   -- and no policy: anon cannot touch it
revoke all on public.game_audit from anon;

create or replace function public.game_watch() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    insert into public.game_audit(tbl, op, row_id, before, after)
      values (tg_table_name, tg_op, old.id, to_jsonb(old), null);
  elsif tg_op = 'UPDATE' then
    insert into public.game_audit(tbl, op, row_id, before, after)
      values (tg_table_name, tg_op, new.id, to_jsonb(old), to_jsonb(new));
  else
    insert into public.game_audit(tbl, op, row_id, before, after)
      values (tg_table_name, tg_op, new.id, null, to_jsonb(new));
  end if;
  return null;
end $$;

drop trigger if exists game_types_audit   on public.game_types;
drop trigger if exists game_entries_audit on public.game_entries;
create trigger game_types_audit   after insert or update or delete on public.game_types   for each row execute function public.game_watch();
create trigger game_entries_audit after insert or update or delete on public.game_entries for each row execute function public.game_watch();

-- ------------------------------------------------------------ putting back --
-- What happened lately:
--     select at, tbl, op, row_id from public.game_audit order by seq desc limit 50;
--
-- Undo the deletions from one afternoon:
--     insert into public.game_entries (id, kid, type_id, day, qty, note)
--     select before ->> 'id', before ->> 'kid', before ->> 'type_id',
--            (before ->> 'day')::int, (before ->> 'qty')::int, before ->> 'note'
--     from public.game_audit
--     where tbl = 'game_entries' and op = 'DELETE'
--       and at > now() - interval '1 day'
--     on conflict (id) do nothing;
--
-- Start over: empty both tables and reopen the page. The first browser to
-- arrive fills them from the written-down game again.
--     delete from public.game_entries;
--     delete from public.game_types;
