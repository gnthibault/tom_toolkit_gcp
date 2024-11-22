# Anyone deployed tom in google cloud platform ?
# I saw django can be configured to serve static files from google cloud storage using [S3 sample](https://tom-toolkit.readthedocs.io/en/stable/deployment/amazons3.html) but with gcs like [here](https://django-storages.readthedocs.io/en/latest/backends/gcloud.html)
#
# pip install django-storages[google]
# and set:
# DEFAULT_FILE_STORAGE = "storages.backends.gcloud.GoogleCloudStorage"
# STATICFILES_STORAGE = "storages.backends.gcloud.GoogleCloudStorage"
# GS_BUCKET_NAME = 'your_bucket_name'
# STATIC_URL = 'https://storage.googleapis.com/<your_bucket_name>/'
# from google.oauth2 import service_account
# GS_CREDENTIALS = service_account.Credentials.from_service_account_file(
#     'path/to/the/downloaded/json/key/credentials.json' # see step 3
# )
#
# Those previous parameters, are actually better to be defined in a google cloud secret manager, and imported at install-time by changing the settings.py see:
# * https://cloud.google.com/python/django/run#understanding-secrets
# * https://cloud.google.com/python/django/run#database_connection
# * https://cloud.google.com/python/django/run#cloud-stored_static
#
# Equivalent cors can be defined from the bucket directly, with an IAC tool like openTOFU or terraform like in here: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
#
# I am still working on GCP deployment, will update if I manage to go through, at the moment, I am reading this overview of the various options from GCP: https://cloud.google.com/python/django
#
# Edit, I am most likely going for a cloudrun deployment, as it can cope with explicit docker images, and can scale to zero instance, which is good in my case: https://cloud.google.com/python/django/run and https://codelabs.developers.google.com/codelabs/cloud-run-django#0
#
# I am also using the manual install guide: https://tom-toolkit.readthedocs.io/en/latest/introduction/manual_installation.html
# and as suggested by @phycodurus the dockerfile from tom_demo:
# https://github.com/LCOGT/tom-demo/blob/57ae7565f8e1f2864a2478ccfe1f11a696e4c067/Dockerfile
# But also the one suggested in the documentation ie dockertom (not maintained either unfortunately)
# https://github.com/TOMToolkit/dockertom/blob/907b98fe826c44ce3ea79148503ef2d7ac8fd4fc/Dockerfile
#
#
# Ok, I also see this advice from https://tom-toolkit.readthedocs.io/en/1.2.6/customization/automation.html that doesn't seems to be in the demo dockerfile:
#
# crontab should be as follows:
# 0 * * * * /path/to/virtualenv/bin/python /path/to/project/manage.py save_data
#
#
#
# EDIT: ok I start to have serious doubt about cloudrun, see the actual [container contract](https://cloud.google.com/run/docs/container-contract):
#
# > For Cloud Run jobs, the container must exit with exit code 0 when the job has successfully completed, and exit with a non-zero exit code when the job has failed.
# >
# > Because jobs should not serve requests, the container should not listen on a port or start a web server.
# >
#
# EDIT2: actually, it seems perfectly fine, see https://cloud.google.com/run/docs/tips/python:
# `CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app`
