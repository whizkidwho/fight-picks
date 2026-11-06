-- =====================================================================
-- Fight Picks — database setup for Supabase
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Safe to run once on a new project.
-- =====================================================================

-- ---------- Tables ----------------------------------------------------

create table public.players (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 24),
  user_id     uuid unique references auth.users(id) on delete set null,  -- the login linked to this player
  sort        int not null default 99,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);
create unique index players_name_unique on public.players (lower(name));

-- Who can run the league (create cards, enter results, approve people).
create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- Join requests: a new login asks to join; an admin links it to a player.
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 24),
  email       text,
  created_at  timestamptz not null default now()
);

create table public.settings (
  id              int primary key default 1 check (id = 1),
  anyone_results  boolean not null default false   -- let any player enter fight results
);
insert into public.settings default values;

create table public.cards (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  card_date   date not null,
  buy_in      numeric(8,2) not null default 25,
  lock_at     timestamptz,                         -- default lock time for fights with no start time
  status      text not null default 'open' check (status in ('open','final')),
  legacy      boolean not null default false,      -- imported totals only (from the spreadsheet)
  created_at  timestamptz not null default now()
);

create table public.fights (
  id          uuid primary key default gen_random_uuid(),
  card_id     uuid not null references public.cards(id) on delete cascade,
  position    int not null default 0,              -- 0 = main event
  fighter_a   text not null,
  fighter_b   text not null,
  starts_at   timestamptz,                         -- picks lock at this time
  locked      boolean not null default false,      -- manual lock
  winner      text check (winner in ('a','b','nc'))  -- nc = draw / no contest
);
create index fights_card_idx on public.fights(card_id);

-- One row per player per card they joined: pot membership, bonus, paid.
create table public.entries (
  card_id     uuid not null references public.cards(id) on delete cascade,
  player_id   uuid not null references public.players(id) on delete cascade,
  in_pot      boolean not null default true,
  bonus       numeric(4,1) not null default 0,
  paid        boolean not null default false,
  created_at  timestamptz not null default now(),
  primary key (card_id, player_id)
);

create table public.picks (
  fight_id    uuid not null references public.fights(id) on delete cascade,
  player_id   uuid not null references public.players(id) on delete cascade,
  card_id     uuid not null references public.cards(id) on delete cascade,   -- filled in automatically
  side        text not null check (side in ('a','b')),
  updated_at  timestamptz not null default now(),
  primary key (fight_id, player_id)
);
create index picks_card_idx on public.picks(card_id);

-- Totals imported from the old spreadsheet (no fight-by-fight picks).
create table public.legacy_results (
  card_id     uuid not null references public.cards(id) on delete cascade,
  player_id   uuid not null references public.players(id) on delete cascade,
  wins        int not null default 0,
  losses      int not null default 0,
  bonus       numeric(4,1) not null default 0,
  primary key (card_id, player_id)
);

-- ---------- Helper functions -------------------------------------------

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.my_player_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from public.players where user_id = auth.uid();
$$;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists (select 1 from public.players where user_id = auth.uid());
$$;

-- True while a fight still accepts picks. Enforced by the database, so nobody can
-- change a pick after the fight starts, even by calling the API directly.
create or replace function public.fight_open(fid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((
    select f.winner is null and not f.locked and c.status = 'open' and not c.legacy
           and now() < coalesce(f.starts_at, c.lock_at, 'infinity'::timestamptz)
    from public.fights f join public.cards c on c.id = f.card_id
    where f.id = fid), false);
$$;

-- Picks: fill card_id from the fight, stamp the time, and auto-join the pot.
create or replace function public.picks_before() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.card_id := (select card_id from public.fights where id = new.fight_id);
  new.updated_at := now();
  return new;
end $$;
create trigger picks_before before insert or update on public.picks
  for each row execute function public.picks_before();

create or replace function public.picks_after() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.entries (card_id, player_id) values (new.card_id, new.player_id)
  on conflict do nothing;
  return new;
end $$;
create trigger picks_after after insert on public.picks
  for each row execute function public.picks_after();

-- ---------- Actions players can take ------------------------------------

-- Sit out / rejoin the pot for a card (only while the card is open).
create or replace function public.set_in_pot(p_card uuid, p_in boolean) returns void
language plpgsql security definer set search_path = public as $$
declare me uuid := public.my_player_id();
begin
  if me is null then raise exception 'Not a player in this league'; end if;
  if not exists (select 1 from public.cards where id = p_card and status = 'open' and not legacy) then
    raise exception 'This card is closed';
  end if;
  insert into public.entries (card_id, player_id, in_pot) values (p_card, me, p_in)
  on conflict (card_id, player_id) do update set in_pot = excluded.in_pot;
end $$;

-- Enter a fight result. Admins always; players only if the setting allows it.
create or replace function public.set_result(p_fight uuid, p_winner text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not (public.is_admin()
          or ((select anyone_results from public.settings where id = 1) and public.my_player_id() is not null)) then
    raise exception 'Only the admin can enter results';
  end if;
  if p_winner is not null and p_winner = '' then p_winner := null; end if;
  if p_winner is not null and p_winner not in ('a','b','nc') then raise exception 'Bad result'; end if;
  if not public.is_admin() and exists (
      select 1 from public.fights f join public.cards c on c.id = f.card_id
      where f.id = p_fight and c.status = 'final') then
    raise exception 'This card is final';
  end if;
  update public.fights set winner = p_winner where id = p_fight;
end $$;

-- How many fights each player has picked (counts only, so nobody sees picks early).
create or replace function public.pick_counts(p_card uuid)
returns table (player_id uuid, n int)
language sql stable security definer set search_path = public as $$
  select p.player_id, count(*)::int from public.picks p
  where p.card_id = p_card and public.is_member()
  group by p.player_id;
$$;

-- ---------- Scores view -------------------------------------------------
-- Wins/losses per player per card. Uses the caller's permissions, and only
-- decided fights count — those are always locked, so everyone can see them.
create or replace view public.card_scores with (security_invoker = on) as
  select e.card_id, e.player_id, e.in_pot, e.bonus, e.paid, false as legacy,
         count(*) filter (where f.winner in ('a','b') and p.side = f.winner)::int  as wins,
         count(*) filter (where f.winner in ('a','b') and p.side <> f.winner)::int as losses
  from public.entries e
  left join public.picks p  on p.card_id = e.card_id and p.player_id = e.player_id
  left join public.fights f on f.id = p.fight_id
  group by e.card_id, e.player_id, e.in_pot, e.bonus, e.paid
  union all
  select l.card_id, l.player_id, true, l.bonus, true, true, l.wins, l.losses
  from public.legacy_results l;

-- ---------- Row-level security ------------------------------------------

alter table public.players        enable row level security;
alter table public.admins         enable row level security;
alter table public.profiles       enable row level security;
alter table public.settings       enable row level security;
alter table public.cards          enable row level security;
alter table public.fights         enable row level security;
alter table public.entries        enable row level security;
alter table public.picks          enable row level security;
alter table public.legacy_results enable row level security;

-- players: members see everyone; a login can always see its own player; admins edit.
create policy players_read  on public.players for select to authenticated
  using (public.is_member() or user_id = auth.uid());
create policy players_admin on public.players for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- admins: you can see whether you are one. Add admins with SQL only.
create policy admins_read on public.admins for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- profiles (join requests)
create policy profiles_read   on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_delete on public.profiles for delete to authenticated
  using (id = auth.uid() or public.is_admin());

-- settings
create policy settings_read  on public.settings for select to authenticated using (public.is_member());
create policy settings_admin on public.settings for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- cards, fights, imported results: members read, admins write
create policy cards_read   on public.cards for select to authenticated using (public.is_member());
create policy cards_admin  on public.cards for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy fights_read  on public.fights for select to authenticated using (public.is_member());
create policy fights_admin on public.fights for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy legacy_read  on public.legacy_results for select to authenticated using (public.is_member());
create policy legacy_admin on public.legacy_results for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- entries: members read; admins change bonus / paid (players use set_in_pot)
create policy entries_read  on public.entries for select to authenticated using (public.is_member());
create policy entries_admin on public.entries for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- picks: your own picks any time; everyone else's only once that fight locks.
-- You can only add/change/remove your own picks, and only before the fight locks.
create policy picks_read on public.picks for select to authenticated
  using (public.is_member() and (player_id = public.my_player_id() or not public.fight_open(fight_id)));
create policy picks_insert on public.picks for insert to authenticated
  with check (player_id = public.my_player_id() and public.fight_open(fight_id));
create policy picks_update on public.picks for update to authenticated
  using (player_id = public.my_player_id() and public.fight_open(fight_id))
  with check (player_id = public.my_player_id() and public.fight_open(fight_id));
create policy picks_delete on public.picks for delete to authenticated
  using (player_id = public.my_player_id() and public.fight_open(fight_id));

-- Tiny function the keep-awake job calls so the free project doesn't pause.
create or replace function public.ping() returns int language sql stable as $$ select 1 $$;

-- Signed-out visitors get nothing (except ping).
revoke all on all tables in schema public from anon;
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
grant execute on function public.ping() to anon;
grant select on public.card_scores to authenticated;

-- ---------- Live updates ------------------------------------------------
alter publication supabase_realtime add table
  public.players, public.cards, public.fights, public.entries, public.picks,
  public.settings, public.profiles, public.legacy_results;
