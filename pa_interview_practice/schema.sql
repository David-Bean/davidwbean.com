-- The shared log behind https://davidwbean.com/pa_interview_practice
--
-- Run this once: Supabase dashboard -> SQL Editor -> New query -> paste -> Run.
-- It is safe to run again; nothing here drops data.
--
-- The page talks to this table with the publishable key, which is in the HTML
-- and therefore known to anyone who opens the page. That is the point -- anyone
-- with the link can grade -- but it means the guard rails have to live here
-- rather than in the page. They are:
--   * only this table is reachable, and only these columns
--   * scores are 1 to 5 or nothing at all, and notes have a ceiling
--   * an answer can't be a day long or carry ten thousand filler words
--   * the log has a row limit, so it can't be filled until it costs money
--   * every change is copied to pa_audit, which the publishable key cannot
--     read, write or erase, so anything done through the page can be undone

-- ---------------------------------------------------------------- table --
-- One row per pass at a question. Nothing is ever overwritten by a second
-- attempt: scoring the same question again adds a row, which is what makes it
-- possible to see whether an answer improved.
--
-- qid is a hash of the question's own text, computed in the page. It is
-- deliberately not a foreign key -- the questions live in the HTML and in
-- mock.json, not in this database, so there is nothing here to point at.
--
-- at is epoch milliseconds rather than a timestamptz, so the value the page
-- sends is the exact value it reads back and a poll can't mistake the server
-- reformatting a date for somebody else's edit. To read it:
--     select to_timestamp(at / 1000.0) at time zone 'America/Denver', * from public.pa_attempts;

create table if not exists public.pa_attempts (
  id              text primary key,
  qid             text    not null default ''    check (length(qid) <= 40),
  at              bigint  not null default 0     check (at between 0 and 4102444800000),
  grader          text    not null default ''    check (length(grader) <= 60),
  mode            text    not null default 'new' check (mode in ('new', 'review', 'mock')),

  -- how long she talked, and how many filler words landed in it. The rate the
  -- page shows is one over the other, worked out where it is read rather than
  -- stored, so a corrected count is a corrected rate.
  fillers         integer not null default 0
                  constraint pa_fillers_sane check (fillers between 0 and 10000),
  seconds         integer not null default 0
                  constraint pa_seconds_sane check (seconds between 0 and 86400),

  clarity         integer                        check (clarity    between 1 and 5),
  clarity_note    text    not null default ''    check (length(clarity_note)    <= 1000),
  motivation      integer                        check (motivation between 1 and 5),
  motivation_note text    not null default ''    check (length(motivation_note) <= 1000),
  judgement       integer                        check (judgement  between 1 and 5),
  judgement_note  text    not null default ''    check (length(judgement_note)  <= 1000),
  maturity        integer                        check (maturity   between 1 and 5),
  maturity_note   text    not null default ''    check (length(maturity_note)   <= 1000),

  updated_at      timestamptz not null default now()
);

create index if not exists pa_attempts_qid on public.pa_attempts (qid);

-- fillers and seconds arrived after the first version of this file. Running it
-- again is how a table that predates them catches up.
alter table public.pa_attempts add column if not exists fillers integer not null default 0;
alter table public.pa_attempts add column if not exists seconds integer not null default 0;
do $$ begin
  alter table public.pa_attempts
    add constraint pa_fillers_sane check (fillers between 0 and 10000);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.pa_attempts
    add constraint pa_seconds_sane check (seconds between 0 and 86400);
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------ who can act --
alter table public.pa_attempts enable row level security;
grant select, insert, update, delete on public.pa_attempts to anon;

drop policy if exists anyone_read   on public.pa_attempts;
drop policy if exists anyone_add    on public.pa_attempts;
drop policy if exists anyone_change on public.pa_attempts;
drop policy if exists anyone_remove on public.pa_attempts;
create policy anyone_read   on public.pa_attempts for select to anon using (true);
create policy anyone_add    on public.pa_attempts for insert to anon with check (true);
create policy anyone_change on public.pa_attempts for update to anon using (true) with check (true);
create policy anyone_remove on public.pa_attempts for delete to anon using (true);

-- --------------------------------------------------------- when it changed --
create or replace function public.pa_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists pa_attempts_touch on public.pa_attempts;
create trigger pa_attempts_touch before update on public.pa_attempts
  for each row execute function public.pa_touch();

-- -------------------------------------------------------------- a ceiling --
-- Statement level, so one enormous insert costs the same to catch as a small one.
create or replace function public.pa_cap() returns trigger
language plpgsql as $$
declare n bigint;
begin
  execute format('select count(*) from public.%I', tg_table_name) into n;
  if n > tg_argv[0]::bigint then
    raise exception 'the % log is full (% rows)', tg_table_name, n;
  end if;
  return null;
end $$;

drop trigger if exists pa_attempts_cap on public.pa_attempts;
create trigger pa_attempts_cap after insert on public.pa_attempts
  for each statement execute function public.pa_cap('20000');

-- ----------------------------------------------------------- undo history --
-- Written by a security-definer trigger, so rows land here even though anon has
-- no rights on the table. Read it from the SQL editor, never from the page.
create table if not exists public.pa_audit (
  seq    bigserial primary key,
  at     timestamptz not null default now(),
  op     text not null,
  row_id text,
  before jsonb,
  after  jsonb
);
alter table public.pa_audit enable row level security;   -- and no policy: anon cannot touch it
revoke all on public.pa_audit from anon;

create or replace function public.pa_watch() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    insert into public.pa_audit(op, row_id, before, after) values (tg_op, old.id, to_jsonb(old), null);
  elsif tg_op = 'UPDATE' then
    insert into public.pa_audit(op, row_id, before, after) values (tg_op, new.id, to_jsonb(old), to_jsonb(new));
  else
    insert into public.pa_audit(op, row_id, before, after) values (tg_op, new.id, null, to_jsonb(new));
  end if;
  return null;
end $$;

drop trigger if exists pa_attempts_audit on public.pa_attempts;
create trigger pa_attempts_audit after insert or update or delete on public.pa_attempts
  for each row execute function public.pa_watch();

-- ------------------------------------------------------------- reading it --
-- How she is doing, worst first:
--     select qid, count(*) as attempts,
--            round(avg((clarity + motivation + judgement + maturity) / 4.0), 2) as avg_all,
--            round(sum(fillers) * 60.0 / nullif(sum(seconds), 0), 2) as filler_per_min,
--            round(avg(clarity), 2) as clarity, round(avg(motivation), 2) as motivation,
--            round(avg(judgement), 2) as judgement, round(avg(maturity), 2) as maturity
--     from public.pa_attempts group by qid order by avg_all nulls first limit 20;
--
-- Every note one grader left:
--     select to_timestamp(at/1000.0)::date as day, qid,
--            clarity_note, motivation_note, judgement_note, maturity_note
--     from public.pa_attempts where grader = 'David' order by at desc;
--
-- Put back what was deleted this afternoon:
--     insert into public.pa_attempts
--     select (jsonb_populate_record(null::public.pa_attempts, before)).*
--     from public.pa_audit
--     where op = 'DELETE' and at > now() - interval '1 day'
--     on conflict (id) do nothing;
--
-- Start over. Unlike the game there is no seed to refill from: an empty table
-- means nobody has been graded yet, and every open page will adopt that.
--     delete from public.pa_attempts;
