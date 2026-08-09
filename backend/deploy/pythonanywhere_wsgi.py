"""WSGI entry point for PythonAnywhere.

PythonAnywhere does not run gunicorn or read a Procfile: it imports an
`application` object from a file it owns at

    /var/www/<username>_pythonanywhere_com_wsgi.py

That file is outside the repository, so it cannot be version controlled.
This is the copy to paste into it — replace USERNAME in the two paths below
and delete everything PythonAnywhere put there by default.

Environment variables are read from backend/.env by django-environ, so there
is nothing to set in the web UI.
"""

import os
import sys

# --- edit these two lines ---------------------------------------------------
USERNAME = "USERNAME"
PROJECT = f"/home/{USERNAME}/shohojpath/backend"
# ----------------------------------------------------------------------------

if PROJECT not in sys.path:
    sys.path.insert(0, PROJECT)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

from django.core.wsgi import get_wsgi_application  # noqa: E402

application = get_wsgi_application()
