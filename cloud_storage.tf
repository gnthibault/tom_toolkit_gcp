# From https://cloud.google.com/docs/quotas/terraform-support-for-cloud-quotas
# Data source: QuotaInfo of a quota for a project, folder or organizatio see google_cloud_quotas_quota_info: https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_quotas_quota_info
# Data source: QuotaInfos of all quotas for a given project, folder or organization	see google_cloud_quotas_quota_infos: https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_quotas_quota_infos
# Resource: QuotaPreference, see google_cloud_quotas_quota_preference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_quotas_quota_preference

# See https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_quotas_quota_infos
# data "google_cloud_quotas_quota_infos" "overall_gcs_quota" {
#     parent      = "projects/${var.project_id}"
#     service     = "storage.googleapis.com"
# }

# See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_quotas_quota_preference
# and https://cloud.google.com/storage/quotas
# resource "google_cloud_quotas_quota_preference" "gcs_bandwidth_limit" {
#   parent        = "projects/${var.project_id}"
#   name          = "compute_googleapis_com-CPUS-per-project_us-east1"
#   dimensions    = { region = "europe" } # You might need to setup europe-west3
#   service       = "storage.googleapis.com"
#   quota_id      = "MultiRegion-Google-Egress-Bandwidth-per-second-per-region"
#   contact_email = var.administrator_email
#   quota_config  {
#     preferred_value = 1Gb
#   }
# }

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "tom_toolkit_static_files" {
  name          = "tom_toolkit_static_files"
	project       = module.main_tom_toolkit_project.project_id
  location      = var.bucket_region
	storage_class = "STANDARD"
	versioning {
		enabled = false
	}
  force_destroy               = true
	uniform_bucket_level_access = false
  # For uniform bucket level access, we had to remove constraints/storage.uniformBucketLevelAccess org constraint
  # See acl: https://django-storages.readthedocs.io/en/latest/backends/gcloud.html

  # 	website {
#     main_page_suffix = "index.html"
#     not_found_page   = "404.html"
#   }
#   cors {
#     origin          = ["http://image-store.com"]
#     method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
#     response_header = ["*"]
#     max_age_seconds = 3600
#   }
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.tom_toolkit_static_files.name
  role   = "roles/storage.objectAdmin" #"roles/storage.admin"
  member = google_service_account.tom_toolkit_service_account.member

}

# Administrator
resource "google_project_iam_member" "project_wide_cloudstorage_administrator" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/storage.admin"
	member  = "user:${var.administrator_email}"
}
