#!/usr/bin/env bash
# Pull the latest code and bring the server up to date.
#
# Run from a PythonAnywhere Bash console:
#     bash ~/shohojpath/backend/deploy/pythonanywhere_update.sh
#
# Then press Reload on the Web tab — this script cannot do that for you.
set -o errexit

USERNAME="${USER}"
PROJECT="/home/${USERNAME}/shohojpath"

cd "${PROJECT}"
git pull --ff-only

source "/home/${USERNAME}/.virtualenvs/shohojpath/bin/activate"
cd "${PROJECT}/backend"

pip install -r deploy/requirements-pythonanywhere.txt

# Order matters: migrate before collectstatic so a failed migration stops the
# run before static files are half-replaced.
python manage.py migrate --no-input
python manage.py collectstatic --no-input

# A misconfigured .env is the likeliest way to end up serving with DEBUG on or
# a published SECRET_KEY, so fail loudly here rather than quietly in the wild.
python manage.py check --deploy --fail-level WARNING

echo
echo "Done. Now press Reload on the Web tab — code changes are not live until you do."
