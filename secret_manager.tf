# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret.html
resource "google_secret_manager_secret" "secret_tom_toolkit_env_file" {
	project   = module.main_tom_toolkit_project.project_id
  secret_id = "django_settings"
  labels = {
    application = "tom-toolkit"
  }
  replication {
    auto {}
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version
resource "google_secret_manager_secret_version" "secret_version_secret_tom_toolkit_env_file" {
  secret      = google_secret_manager_secret.secret_tom_toolkit_env_file.id
  secret_data = templatefile("${path.module}/tom_toolkit_env_file.env", {
		DB_USERNAME    = var.db_username
		DB_PASSWORD    = var.db_password
		PROJECT_ID     = module.main_tom_toolkit_project.project_id
		REGION         = var.compute_region
		INSTANCE_NAME  = google_sql_database_instance.main_tom_toolkit_db.name
		DATABASE_NAME  = var.database_name
		GS_BUCKET_NAME = google_storage_bucket.tom_toolkit_static_files.name
  })
}

data "google_project" "tom_toolkit_project" {
  project_id = module.main_tom_toolkit_project.project_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam
# We choose member because it is non authoritative
# resource "google_secret_manager_secret_iam_member" "secret_tom_toolkit_env_file_access" {
# 	project   = module.main_tom_toolkit_project.project_id
#   secret_id = google_secret_manager_secret.secret_tom_toolkit_env_file.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = data.google_compute_default_service_account.default.member
# }

# see https://cloud.google.com/python/django/run#setting_minimum_permissions
resource "google_secret_manager_secret_iam_member" "secret_tom_toolkit_env_file_access" {
	project   = module.main_tom_toolkit_project.project_id
  secret_id = google_secret_manager_secret.secret_tom_toolkit_env_file.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.tom_toolkit_service_account.member
}

# Administrator
resource "google_project_iam_member" "project_wide_secretmanager_administrator" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/secretmanager.admin"
	member  = "user:${var.administrator_email}"
}

# CI/CD deployer
resource "google_secret_manager_secret_iam_member" "secret_cicd_env_file_access" {
	project   = module.main_tom_toolkit_project.project_id
  secret_id = google_secret_manager_secret.secret_tom_toolkit_env_file.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.cicd_service_account.member
}