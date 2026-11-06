-- =====================================================================
-- Run this AFTER you've created your own login in the app.
-- Replace YOUR_EMAIL_HERE (2 places) with the email you signed up with, then Run.
-- It makes you the admin and creates your player, using the name you
-- entered when you signed up.
-- =====================================================================

insert into public.admins (user_id)
select id from auth.users where email = 'YOUR_EMAIL_HERE'
on conflict do nothing;

insert into public.players (name, user_id, sort)
select coalesce(pr.name, split_part(u.email, '@', 1)), u.id, 1
from auth.users u
left join public.profiles pr on pr.id = u.id
where u.email = 'YOUR_EMAIL_HERE'
on conflict (user_id) do nothing;

-- Check: this should return one row with your email and your player name.
select u.email, p.name as player
from public.admins a
join auth.users u on u.id = a.user_id
left join public.players p on p.user_id = u.id;
