resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance
resource "google_sql_database_instance" "main_tom_toolkit_db" {
	project          = module.main_tom_toolkit_project.project_id
  region           = var.compute_region
  name             = "tom-toolkit-instance-${var.environment}-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_15"

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }
}
# self_link - The URI of the created resource.
# connection_name - The connection name of the instance to be used in connection strings. For example, when connecting with Cloud SQL Proxy.
# dsn_name - The DNS name of the instance. See Connect to an instance using Private Service Connect for more details.
# service_account_email_address - The service account email address assigned to the instance.
# ip_address.0.ip_address - The IPv4 address assigned.

resource "google_sql_database" "tom_toolkit_database" {
  project  = module.main_tom_toolkit_project.project_id
  name     = var.database_name
  instance = google_sql_database_instance.main_tom_toolkit_db.name
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user
resource "google_sql_user" "users" {
	project  = module.main_tom_toolkit_project.project_id
  name     = var.db_username
  instance = google_sql_database_instance.main_tom_toolkit_db.name
  password = var.db_password
}

# We thought about using roles/cloudsql.client thanks to https://cloud.google.com/python/django/run#setting_minimum_permissions
resource "google_project_iam_member" "app_sa_sql_user_on_project" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.tom_toolkit_service_account.member
}
resource "google_sql_user" "iam_service_account_user" {
	project  = module.main_tom_toolkit_project.project_id
  name     = trimsuffix(google_service_account.tom_toolkit_service_account.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.main_tom_toolkit_db.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}


# Administrator
resource "google_project_iam_member" "project_wide_cloudsql_administration" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/cloudsql.admin"
	member  = "user:${var.administrator_email}"
}
resource "google_sql_user" "administrator_sql_user" {
	project  = module.main_tom_toolkit_project.project_id
  name     = var.administrator_email
  instance = google_sql_database_instance.main_tom_toolkit_db.name
  type     = "CLOUD_IAM_USER"
}
