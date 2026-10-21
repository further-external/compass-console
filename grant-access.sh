#!/usr/bin/env bash
#
# Sets up a Google Cloud project for Compass Console: enables the APIs the app
# reads and, given an email, grants that person the IAM roles it needs.
#
#   bash grant-access.sh <project_id> [email]
#
# Without an email it only enables the APIs - for a project being set up
# before anyone is given access.
#
# Run it as someone who can change the project's IAM and enable its APIs - an
# Owner, or Project IAM Admin plus Service Usage Admin. Safe to run again: every
# step leaves what is already in place as it is.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
	echo "Usage: bash grant-access.sh <project_id> [email]" >&2
	exit 1
fi

PROJECT="$1"
EMAIL="${2:-}"

# A service account is granted as one; anyone else as a user
if [ -z "$EMAIL" ]; then
	MEMBER=""
elif [[ "$EMAIL" == *.gserviceaccount.com ]]; then
	MEMBER="serviceAccount:$EMAIL"
else
	MEMBER="user:$EMAIL"
fi

# What the app reads, one API per page or section
APIS=(
	clouderrorreporting.googleapis.com  # Errors: error groups
	logging.googleapis.com              # Errors and run pages: log lines
	run.googleapis.com                  # Runs: Cloud Run jobs and services
	workflows.googleapis.com            # Runs: workflows
	workflowexecutions.googleapis.com   # Runs: workflow executions
	bigquerydatatransfer.googleapis.com # Runs: data transfers
	cloudscheduler.googleapis.com       # Runs: schedules
	storage.googleapis.com              # dbt: run results in a bucket
	aiplatform.googleapis.com           # Overview and run pages: Summarise (Gemini)
	cloudresourcemanager.googleapis.com # The project picker
	serviceusage.googleapis.com         # Each project pays for its own reads
)

# Read roles - every page
READ_ROLES=(
	roles/errorreporting.viewer
	roles/logging.viewer
	roles/logging.privateLogViewer
	roles/run.viewer
	roles/workflows.viewer
	roles/bigquery.user
	roles/cloudscheduler.viewer
	roles/aiplatform.user
	roles/serviceusage.serviceUsageConsumer
)

# The Run button - starts a job or workflow
RUN_ROLES=(
	roles/run.invoker
	roles/workflows.invoker
)

echo "Project: $PROJECT"
echo "Member:  ${MEMBER:-none - APIs only}"
echo

# From the terminal, not stdin: under `curl ... | bash` stdin is this script.
# No terminal to ask - so no answer - means no changes.
if ! { exec 3< /dev/tty; } 2> /dev/null; then
	echo "No terminal to confirm from - nothing changed." >&2
	exit 1
fi
if [ -n "$MEMBER" ]; then
	question="Enable the APIs and grant these roles? [y/N] "
else
	question="Enable the APIs? [y/N] "
fi
read -r -u 3 -p "$question" answer
exec 3<&-
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
	echo "Cancelled - nothing changed."
	exit 0
fi
echo

echo "Enabling APIs..."
gcloud services enable "${APIS[@]}" --project="$PROJECT"
echo "  done"

if [ -z "$MEMBER" ]; then
	echo
	echo "Done. Changes can take a minute or two to apply - then Refresh in the app."
	exit 0
fi

echo
echo "Granting project roles..."
for role in "${READ_ROLES[@]}" "${RUN_ROLES[@]}"; do
	gcloud projects add-iam-policy-binding "$PROJECT" \
		--member="$MEMBER" --role="$role" --condition=None --quiet > /dev/null
	echo "  $role"
done

# dbt run results: <project>-dbt, or <project>-config where the pegasus dbt job writes
echo "Granting read on the dbt results bucket..."
granted_bucket=false
for bucket in "$PROJECT-dbt" "$PROJECT-config"; do
	if gcloud storage buckets describe "gs://$bucket" --project="$PROJECT" > /dev/null 2>&1; then
		gcloud storage buckets add-iam-policy-binding "gs://$bucket" \
			--member="$MEMBER" --role=roles/storage.objectViewer > /dev/null
		echo "  roles/storage.objectViewer on gs://$bucket"
		granted_bucket=true
	fi
done
if [ "$granted_bucket" = false ]; then
	echo "  no gs://$PROJECT-dbt or gs://$PROJECT-config bucket - skipped; the dbt page shows how to set one up"
fi

echo
echo "Done. Changes can take a minute or two to apply - then Refresh in the app."
