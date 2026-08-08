# Shohojpath backend

Django + DRF API for the সহজপাঠ research prototype: accounts, the reader
directory, therapist–reader ownership, notifications, admin-managed passages,
and session sync.

## Run it locally

```bash
cd backend
cp .env.example .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Admin: http://127.0.0.1:8000/admin/ · Health: `/api/health/`

The Android emulator reaches the host at **`http://10.0.2.2:8000`**, not
`localhost`. On a physical device use your machine's LAN IP and make sure both
are on the same network.

## Design decisions worth knowing

**The device is the source of truth.** Sessions are written to sqflite as they
happen and uploaded afterwards, so the study runs whether or not the server is
awake. This matters because every free host sleeps after a few idle minutes and
takes ~50 s to wake — unacceptable with a child sitting in front of the device.
Sync is idempotent on `session_id`, so a dropped response is safe to retry.

**Claiming a reader is a conditional UPDATE, not read-then-write.** Two
therapists tapping the same reader at the same moment must not both succeed;
the loser updates zero rows and gets a `409`.

**Role checks are server-side.** A reader holding a valid token must not be
able to call `/api/readers/available/` and read every other child's name and
school. `IsTherapist` enforces that, not the app's navigation.

**Passages live in the database.** Study material can be changed without
shipping a new APK — Passages → *Upload passages* in the admin takes a JSON
file, or edit pages inline. Re-uploading a slug replaces its pages completely.

## API

| Method | Path | Who | Purpose |
| --- | --- | --- | --- |
| POST | `/api/auth/signup/` | anyone | Create reader or therapist, returns JWT |
| POST | `/api/auth/login/` | anyone | Email + password → JWT, role, participant_id |
| POST | `/api/auth/refresh/` | anyone | Refresh access token |
| GET | `/api/auth/me/` | any | Current user |
| POST | `/api/auth/password/` | any | Change password |
| GET | `/api/readers/available/?search=` | therapist | **Unclaimed readers only** |
| GET/POST | `/api/readers/mine/` | therapist | Own roster / register a child |
| POST | `/api/readers/{pid}/claim/` | therapist | Add reader → notifies them |
| POST | `/api/readers/{pid}/release/` | therapist | Undo a claim |
| GET/POST | `/api/readers/{pid}/notes/` | therapist | Observations |
| GET | `/api/notifications/?unread=true` | any | Own messages |
| POST | `/api/notifications/{id}/read/` | any | Mark read |
| GET | `/api/passages/` | any | Library (filters: search, category, difficulty) |
| GET | `/api/passages/{slug}/` | any | Full text for caching |
| GET/POST | `/api/bookmarks/` | reader | Bookmarks |
| GET/POST | `/api/readers/{pid}/assignments/` | therapist | Assign a passage → notifies |
| GET | `/api/assignments/mine/` | reader | What was assigned to me |
| GET/PATCH | `/api/me/profile/` | reader | Own profile (participant_id immutable) |
| GET/PUT | `/api/me/settings/` | reader | Reading config, mirrored from device |
| GET | `/api/readers/{pid}/settings/` | therapist | Condition that reader reads under |
| GET | `/api/readers/{pid}/progress/` | therapist | Same figures the reader sees |
| GET | `/api/readers/{pid}/statistics/` | therapist | Same figures the reader sees |
| GET | `/api/therapist/readers-summary/` | therapist | One row per reader for the dashboard |
| GET | `/api/content/` | anyone | Help features, FAQs, About, notices |
| POST | `/api/sync/sessions/` | any | Batch session upload (idempotent) |
| GET | `/api/sessions/mine/` | reader | History screen |
| GET | `/api/me/progress/` | reader | Progress screen (minutes today, week, %) |
| GET | `/api/me/statistics/` | reader | Statistics screen (wpm, comprehension) |
| GET | `/api/therapist/overview/` | therapist | Dashboard tiles |

Every list endpoint is paginated (`count`, `next`, `results`), page size 50.

## Passage upload format

```json
[
  {
    "slug": "bristir_dine_mitu",
    "title": "বৃষ্টির দিনে মিতু",
    "category": "Children Stories",
    "difficulty": "easy",
    "estimated_minutes": 3,
    "pages": [
      ["একদিন সকালে ছোট্ট মেয়ে মিতু...", "হঠাৎ মিতু দেখল..."],
      ["পাখিটার ডানা দুটো ভিজে..."]
    ],
    "questions": [
      {
        "kind": "multiple_choice",
        "prompt": "মিতু জানালার পাশে বসে কী দেখেছিল?",
        "options": ["একটা ভেজা পাখি", "একটা রঙিন ছাতা", "একটা নৌকা"],
        "correct_index": 0
      }
    ]
  }
]
```

`questions` is optional. When present it replaces that passage's question set
completely, the same way `pages` does.

An invalid entry rolls the whole file back — no half-imported passage sets.

## Deploying free (Render + Neon)

1. Create a free Postgres on **Neon**, copy the connection string.
2. New **Web Service** on Render from this repo, root directory `backend`.
   - Build: `bash build.sh`
   - Start: `gunicorn config.wsgi:application`
3. Environment variables:

```
SECRET_KEY=<a long random string>
DEBUG=False
ALLOWED_HOSTS=your-app.onrender.com
DATABASE_URL=<the Neon connection string>
CSRF_TRUSTED_ORIGINS=https://your-app.onrender.com
CORS_ALLOW_ALL=False
```

4. `python manage.py createsuperuser` from the Render shell.

**Never deploy with the default `SECRET_KEY`** — it signs the JWTs, and it is
published in this repo.

Free instances sleep. Hit `/api/health/` from an uptime pinger to keep one warm
on a session day, or simply accept a slow first login — the offline-first design
means nothing else depends on it.

## Before real participants

- Confirm with your supervisor's ethics board that children's names, schools and
  performance data may be stored on a third-party host. Some boards require the
  data stay on-device or in-country; the offline-first design supports that.
- Rotate `SECRET_KEY` and use a real database backup.

## Tests

```bash
python manage.py test
```

77 tests. The ones that matter most: the claim race returns `409` rather than
silently reassigning; sync is genuinely idempotent (asserted on status, not just
row counts); a reader cannot read the directory or another reader's data; and a
therapist sees exactly the same progress figures their reader sees.
