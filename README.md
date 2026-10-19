# Compass Console

A macOS app for Google Cloud Platform projects. It answers three
questions: **is anything on fire**, **what exactly is this error**, and **did
my pipelines run**.

It runs on your own Mac and reads Google Cloud with your own credentials. It
only reads your projects - except the **Run** button on a job or workflow page,
which starts a run after you confirm - and your project data is not
used anywhere except the app.

This repository holds macOS app's releases.

## Download

**[CompassConsole.dmg](https://github.com/further-external/compass-console/releases/latest/download/CompassConsole.dmg)** - the latest version, for Macs with Apple Silicon.

## Requirements

- macOS on Apple Silicon
- The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install), signed in
  with `gcloud auth application-default login` - the app can run this for you
  on first launch

## IAM roles

The app reads only what your own account can. The table shows which APIs the app is reading and which IAM roles are required. 

| Role                                                                  | GCP API                                                            |
| --------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `roles/errorreporting.viewer`                                         | Error Reporting API - `clouderrorreporting.googleapis.com`         |
| `roles/logging.viewer`                                                | Cloud Logging API - `logging.googleapis.com`                       |
| `roles/logging.privateLogViewer`                                      | Cloud Logging API - Data Access audit logs                         |
| `roles/run.viewer`                                                    | Cloud Run Admin API - `run.googleapis.com`                         |
| `roles/workflows.viewer`                                              | Workflows API - `workflows.googleapis.com`                         |
| `roles/bigquery.user`                                                 | BigQuery Data Transfer API - `bigquerydatatransfer.googleapis.com` |
| `roles/cloudscheduler.viewer`                                         | Cloud Scheduler API - `cloudscheduler.googleapis.com`              |
| `roles/storage.objectViewer` on the `gs://<project_id>-dbt` bucket | Cloud Storage API - `storage.googleapis.com`                  |
| `roles/aiplatform.user`, with the Vertex AI API enabled               | Vertex AI API (Gemini) - `aiplatform.googleapis.com`               |
| `roles/serviceusage.serviceUsageConsumer`                             | Service Usage - uses the API limits of the project it reads        |

**Run** button, which starts a job or workflow:

| Role                      | Starts                                                      |
| ------------------------- | ----------------------------------------------------------- |
| `roles/run.invoker`       | Cloud Run jobs                                              |
| `roles/workflows.invoker` | Workflows                                                   |
