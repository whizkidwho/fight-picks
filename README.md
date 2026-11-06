# Fight Picks

A weekly UFC pick'em for the crew. Works in any phone browser (iPhone or Android) and can be added to the home screen like an app.
Logins are email + password. Anyone can create a login, but they see nothing until you approve them.

**Cost:** $0. It uses Supabase (database + logins, free plan) and GitHub Pages (free website hosting).
**Time to set up:** about 20 minutes, on a computer.

---


PU=BTz$bkD8kke&a/1V3
uYnw0hRP6IietZ6G


## What's in this folder

| Path | What it is |
|---|---|
| `supabase/1_schema.sql` | Creates the database tables and the security rules |
| `supabase/2_first_card_optional.sql` | Optional: adds the Nov 7, 2026 UFC Fight Night card so you have one ready |
| `supabase/3_make_me_admin.sql` | Makes your login the admin and creates your player (run it after you sign up) |
| `docs/` | The website itself (`index.html`, `config.js`, icons) |
| `.github/workflows/keep-awake.yml` | Pings the database every 3 days so the free plan doesn't pause it |

---

## Setup

### 1. Create the database (Supabase)
1. Go to **supabase.com** and sign up (free). Create a **New project**. Pick any name and a strong database password, and choose a US West region.
2. When it's ready, open **SQL Editor → New query**. Paste all of `supabase/1_schema.sql` and click **Run**. You should see "Success".
3. Optional: open another new query, paste `supabase/2_first_card_optional.sql`, and click **Run** to get a ready-made card. Skip it if you'd rather create cards in the app.

The database starts empty: no players and no history. Everyone, including you, joins by creating a login.

### 2. Turn off confirmation emails
Supabase's built-in email sender is only for testing: it sends about 2 emails an hour, and only to your own team. Your approval step is what protects the league, so you don't need confirmation emails.

- **Authentication → Sign In / Providers → Email**: turn **Confirm email** OFF and save.

(If you want password-reset emails later, add a free email provider under Authentication → SMTP Settings. It's optional.)

### 3. Point the website at your database
1. In Supabase, open **Project Settings → API** (or **API Keys**).
2. Copy the **Project URL** and the **anon public** key. The newer **publishable** key also works.
3. Paste both into `docs/config.js`.

Both values are meant to be public. The security rules in the database decide who can see or change what.

### 4. Put the website online (GitHub Pages)
1. Create a free account at **github.com**, then **New repository** (for example `fight-picks`). Set it to **Public**, since free Pages hosting requires that.
2. Click **uploading an existing file** and drag in everything from this folder: `docs`, `supabase`, `.github` and `README.md`. Commit.
   - The `.github` folder is hidden on Mac and Windows. If it doesn't upload, create it on GitHub with **Add file → Create new file** and name the file `.github/workflows/keep-awake.yml`, then paste in its contents.
3. Go to **Settings → Pages**. Under "Build and deployment", choose **Deploy from a branch**, then branch **main** and folder **/docs**. Save.
4. After a minute your site is live at `https://YOUR-GITHUB-NAME.github.io/fight-picks/`.
5. Back in Supabase, open **Authentication → URL Configuration** and set **Site URL** to that address.

### 5. Make yourself the admin
1. Open your site, tap **New here? Create a login**, and sign up with your name, email and a password. You'll see "Waiting for approval"; that's expected.
2. In Supabase's SQL Editor, open `supabase/3_make_me_admin.sql` and replace `YOUR_EMAIL_HERE` (it appears twice) with your email. Run it.
3. Refresh the site. You'll see the **Admin** tab, and you're the first player in the league.

### 6. Invite the crew
Text them the link. Each person:
1. Taps **Create a login** and enters their name, email and a password.
2. Sees "Waiting for approval".

Then, in **Admin → Join requests**, leave **Add as new player** selected and tap **Approve**. Their screen unlocks within about 20 seconds. Tap **Decline** for anyone you don't know.

**Add to home screen:**
- iPhone: Safari → Share → **Add to Home Screen**
- Android: Chrome → ⋮ → **Add to Home screen**

### 7. Keep it awake
Free Supabase projects pause after 7 days with no activity. The included GitHub Action pings the database every 3 days.

- In your repo, open the **Actions** tab and enable workflows if GitHub asks.
- Run **Keep database awake → Run workflow** once to check it works.
- GitHub turns off scheduled jobs in repos with no commits for 60 days. If you get an email about that, click to re-enable.
- If the site ever stops loading, open the Supabase dashboard and click **Resume project**. Your data is kept.
- If you'd rather not think about this, Supabase Pro ($25/month) never pauses.

---

## Each fight week

1. **Admin → New fight card.** Enter the name and date, then paste the fights with the main event first, one per line:
   ```
   Waldo Cortes-Acosta vs Johnny Walker @ 5:40pm
   Tatiana Suarez vs Virna Jandiroba @ 5:20pm
   ```
   The `@ time` part locks each fight at its own start. Without it, every fight locks at the card's "Picks lock at" time.
2. Everyone makes picks. Making a first pick puts them in the pot. They can tap **Sitting out** to leave.
3. As fights end, tap **[Name] won** or **Draw/NC** under each fight. Scores update on everyone's phone.
4. When the last result is in, the winner shows up and the **Money** tab lists who owes whom. Tap **Mark paid** as people settle up.
5. Bonus points: use the **− / +** buttons in the standings table.

## How the rules are enforced

The database itself enforces these, not just the app screen:
- You can only pick for yourself, and only before that fight starts.
- Nobody, including the admin, can see anyone else's picks for a fight until it locks. Before that, everyone only sees how many fights each person has picked.
- Only the admin can enter results, bonuses, payments and cards. There's a setting to let any player enter results.
- A login that hasn't been approved can't see anything.

## Scoring
Right pick +1 · wrong pick −0.5 · no pick 0 · draw/no contest 0 · plus any bonus.
Highest total takes the pot ($ buy-in × number of people in). A tie splits it.

## Common fixes
- **Someone forgot their password:** in Supabase, go to **Authentication → Users** and delete their login. They sign up again; in Join requests, choose **Link to [their name]** in the dropdown before you tap Approve. Their history stays.
- **Someone's login got linked to the wrong name:** Admin → Players → **Unlink**, then approve them again.
- **You need to fix a pick or a result by hand:** Supabase → **Table Editor** → `picks` or `fights`.

## Money
The app doesn't move money; settle up with cash, Zelle and so on. It only tracks who owes whom. Payment apps such as Venmo prohibit gambling in their terms, and the rules on private betting vary by state.
