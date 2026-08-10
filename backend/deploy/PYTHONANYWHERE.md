# Deploying Shohojpath to PythonAnywhere (free tier)

Why this host: free web apps **are not suspended for lack of traffic**, so
there is no cold start between study sessions, and the filesystem is
persistent — SQLite survives restarts and redeploys, which it does not on
Render, Railway or Fly.

Three limits shape everything below.

| Limit | Consequence |
|---|---|
| No MySQL on free accounts created after 2026-01-15 | The database is SQLite. Fine here, because the disk is persistent. |
| Web app expires after **1 month** unless renewed | You get an email with a link. Click it, or the study goes offline mid-run. |
| 100 CPU-seconds/day, 512 MB disk | Enough for a study of this size. Exceeding CPU throttles requests, it does not stop them. |

---

## 1. Create the account

Sign up at pythonanywhere.com — "Create a Beginner account". Your host will be
`USERNAME.pythonanywhere.com`. Substitute your real username everywhere below.

## 2. Clone the repository

**Consoles → Bash**, then:

```bash
git clone https://github.com/Ibrahimkhalill/shohojpath.git ~/shohojpath
mkdir -p ~/shohojpath-data
```

`~/shohojpath-data` holds the database, deliberately outside the repository so
`git pull` can never come between you and the study data.

## 3. Virtualenv and dependencies

```bash
mkvirtualenv --python=/usr/bin/python3.12 shohojpath
pip install -r ~/shohojpath/backend/deploy/requirements-pythonanywhere.txt
```

If `python3.12` is not offered, use the highest 3.11+ that is. Note the exact
path — you need it in step 6.

## 4. Configuration

```bash
cd ~/shohojpath/backend
cp deploy/env.example .env
python -c "from django.core.management.utils import get_random_secret_key as k; print(k())"
nano .env
```

Paste the generated key into `SECRET_KEY` and replace every `USERNAME`. Do not
commit this file — it signs every token the app issues.

## 5. Build the database

```bash
python manage.py migrate
python manage.py collectstatic --no-input
python manage.py createsuperuser
```

The migrations seed the library: **30 passages, 81 pages, 90 comprehension
questions**. You should not need to import anything by hand. Confirm with:

```bash
python manage.py shell -c "from passages.models import *; print(Passage.objects.count(), QuizQuestion.objects.count())"
```

Expect `30 90`. If questions are 0, migration `0005_seed_aesop_questions` did
not run.

Use a real password for the superuser — the local dev credential
(`admin@shohojpath.local`) must not be reused on a host that is on the
internet.

## 6. The web app

**Web tab → Add a new web app → Manual configuration** (*not* the "Django"
option — that scaffolds a new project over yours) → same Python version as
step 3.

Then set, on that same page:

- **Source code**: `/home/USERNAME/shohojpath/backend`
- **Virtualenv**: `/home/USERNAME/.virtualenvs/shohojpath`
- **WSGI configuration file**: click it, delete everything, and paste
  [`pythonanywhere_wsgi.py`](pythonanywhere_wsgi.py) with `USERNAME` replaced.
- **Static files**: URL `/static/` → Directory
  `/home/USERNAME/shohojpath/backend/staticfiles`

  Whitenoise already serves these, but letting PythonAnywhere serve them
  directly skips Python entirely and does not spend your CPU-seconds.
- **Force HTTPS**: on.

Press **Reload**.

## 7. Check it

```
https://USERNAME.pythonanywhere.com/admin/          → admin login, styled
https://USERNAME.pythonanywhere.com/api/passages/   → 401, which is correct
```

A 401 from the passages endpoint means routing and auth both work — it is not
an error.

## 8. Point the app at it

The APK is compiled with its server address, so it must be rebuilt:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://USERNAME.pythonanywhere.com
```

Without this it keeps talking to `10.0.2.2:8002`, the emulator's route to your
laptop.

---

## Updating later

```bash
bash ~/shohojpath/backend/deploy/pythonanywhere_update.sh
```

Then press **Reload** on the Web tab. Code changes are not live until you do —
this catches everyone once.

## Backups

There is no managed backup on a free plan, and this is participant data that
cannot be recreated. From a Bash console:

```bash
cp ~/shohojpath-data/db.sqlite3 ~/backup-$(date +%F).sqlite3
```

Then **Files tab → Download**. Do this after every session day. Keep the copies
somewhere your ethics approval covers.

## Known limits worth planning around

- **CPU throttling.** Past 100 CPU-seconds in a day, requests are queued and
  slow rather than refused. The app is offline-first, so a slow sync is
  invisible to a reader mid-passage.
- **Occasional cold start after maintenance.** PythonAnywhere reboots web
  servers periodically; the next request wakes the app. This is rare and
  unrelated to traffic.
- **SQLite concurrency.** One web worker and a 20-second lock timeout
  (`SQLITE_TIMEOUT`) make this a non-issue at study scale. If you ever run
  many readers at once, move `DATABASE_URL` to a hosted Postgres — the code
  needs no change, only that variable.
- **Ethics.** This puts named children's reading data on a third-party host
  outside Bangladesh, on a free plan with no data-processing agreement. That
  needs your ethics board's sign-off before real participants use it, not
  after.
