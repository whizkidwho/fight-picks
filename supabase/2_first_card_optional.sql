-- =====================================================================
-- OPTIONAL. Run AFTER 1_schema.sql if you want a fight card ready to go.
-- Adds the UFC Fight Night on Nov 7, 2026 (check the bouts before fight night).
-- Skip this file if you'd rather create your first card in the app
-- (Admin → New fight card). No players are created here — everyone joins
-- by creating a login and being approved by you.
-- =====================================================================

do $$
declare c uuid;
begin
  insert into public.cards (title, card_date, buy_in, lock_at)
  values ('UFC Fight Night (Nov 7)','2026-11-07',25,'2026-11-07 21:00+00') returning id into c;
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
