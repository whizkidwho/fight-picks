-- =====================================================================
-- Fight Picks — starting data. Run AFTER 1_schema.sql.
-- Players and past cards come from the spreadsheet screenshot;
-- the Nov 7, 2026 card is the next UFC Fight Night (check the bouts before Saturday).
-- =====================================================================

insert into public.players (name, sort) values
  ('Danny',1),('Javi',2),('Rob',3),('Jordan',4),('Julio',5),
  ('Joey',6),('Jojo',7),('Josh',8),('Chris',9),('Fatal',10);

-- Past cards (totals only)
do $$
declare c uuid;
begin
  insert into public.cards (title, card_date, status, legacy) values ('UFC Fight Night','2021-10-02','final',true) returning id into c;
  insert into public.legacy_results (card_id, player_id, wins, losses, bonus)
  select c, p.id, v.w, v.l, v.b from (values
    ('Danny',7,5,0),('Javi',4,3,1),('Rob',8,4,1),('Jordan',7,5,1),('Julio',9,3,0),
    ('Joey',7,5,0),('Jojo',8,4,0),('Josh',4,4,0),('Chris',8,4,0)) v(n,w,l,b)
  join public.players p on p.name = v.n;

  insert into public.cards (title, card_date, status, legacy) values ('UFC Fight Night','2021-10-09','final',true) returning id into c;
  insert into public.legacy_results (card_id, player_id, wins, losses, bonus)
  select c, p.id, v.w, v.l, v.b from (values
    ('Danny',7,2,0),('Javi',4,5,0),('Rob',8,1,0),('Jordan',4,5,0),('Julio',5,4,0),
    ('Joey',6,3,0),('Jojo',4,5,1),('Josh',3,6,0)) v(n,w,l,b)
  join public.players p on p.name = v.n;

  insert into public.cards (title, card_date, status, legacy) values ('UFC 292','2023-08-19','final',true) returning id into c;
  insert into public.legacy_results (card_id, player_id, wins, losses, bonus)
  select c, p.id, v.w, v.l, v.b from (values
    ('Danny',7,5,1),('Javi',9,3,0),('Julio',10,2,0),('Fatal',7,5,0),('Rob',8,4,1)) v(n,w,l,b)
  join public.players p on p.name = v.n;

  insert into public.cards (title, card_date, status, legacy) values ('UFC Noche','2023-09-16','final',true) returning id into c;
  insert into public.legacy_results (card_id, player_id, wins, losses, bonus)
  select c, p.id, v.w, v.l, v.b from (values
    ('Danny',7,3,0),('Javi',7,3,0),('Julio',6,4,1),('Fatal',6,4,0)) v(n,w,l,b)
  join public.players p on p.name = v.n;

  -- Next card. Times are scheduled start times (UTC); each fight locks then.
  insert into public.cards (title, card_date, buy_in, lock_at) values ('UFC Fight Night (Nov 7)','2026-11-07',25,'2026-11-07 21:00+00') returning id into c;
  insert into public.fights (card_id, position, fighter_a, fighter_b, starts_at) values
    (c, 0,'Waldo Cortes-Acosta','Johnny Walker','2026-11-08 01:40+00'),
    (c, 1,'Tatiana Suarez','Virna Jandiroba','2026-11-08 01:20+00'),
    (c, 2,'Davey Grant','Elijah Smith','2026-11-08 01:00+00'),
    (c, 3,'Seok Hyun Ko','Wellington Turman','2026-11-08 00:40+00'),
    (c, 4,'Billy Elekana','Lucas Fernando','2026-11-08 00:20+00'),
    (c, 5,'Mantas Kondratavicius','Andre Petroski','2026-11-08 00:00+00'),
    (c, 6,'Gabriel Lorenco','Thomas Petersen','2026-11-07 23:20+00'),
    (c, 7,'Karine Silva','Gabriella Fernandes','2026-11-07 23:00+00'),
    (c, 8,'Mitch Raposo','Marcos Degli','2026-11-07 22:40+00'),
    (c, 9,'Jose Delano','Murtazali Magomedov','2026-11-07 22:20+00'),
    (c,10,'Keiichiro Nakamura','Ollie Schmid','2026-11-07 22:00+00'),
    (c,11,'Austin Bashi','Lucas Brennan','2026-11-07 21:40+00'),
    (c,12,'Priscila Cachoeira','Nina Milosevic','2026-11-07 21:20+00'),
    (c,13,'Jonny Parsons','Jose Henrique Nascimento De Souza','2026-11-07 21:00+00');
end $$;
