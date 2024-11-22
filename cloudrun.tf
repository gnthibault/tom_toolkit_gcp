resource "random_id" "cloudrun_suffix" {
  byte_length = 4
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service
# Also samples from https://cloud.google.com/run/docs/samples/cloudrun-connect-cloud-sql-parent-tag
resource "google_cloud_run_v2_service" "tom_toolkit" {
	project             = module.main_tom_toolkit_project.project_id
  location            = var.compute_region
  name                = "tom-toolkit-instance-${var.environment}-${random_id.cloudrun_suffix.hex}"
  deletion_protection = false
  template {
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"
    max_instance_request_concurrency = var.cloudrun_config.max_concurrency
    timeout                          = var.cloudrun_config.timeout
    service_account                  = google_service_account.tom_toolkit_service_account.email # Email address of the IAM service account associated with the revision of the service. The service account represents the identity of the running revision, and determines what permissions the revision has. If not provided, the revision will use the project's default service account.
    scaling {
      min_instance_count = var.cloudrun_config.min_instance_count
      max_instance_count = var.cloudrun_config.max_instance_count
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main_tom_toolkit_db.connection_name]
      }
    }
		# See doc from https://cloud.google.com/run/docs/container-contract
		# The ingress container within an instance must listen for requests on 0.0.0.0 on the port to which requests are sent. By default, requests are sent to 8080, but you can configure Cloud Run to send requests to the port of your choice. Cloud Run injects the PORT environment variable into the ingress container.
    containers {
      image = var.cloudrun_config.docker_image
#       dynamic "env" {
#         for_each = coalesce(var.cloudrun_config.env_variables, tomap({}))
#         content {
#           name  = env.key
#           value = env.value
#         }
#       }
      env {
        name  = "SETTINGS_NAME"
        value = google_secret_manager_secret.secret_tom_toolkit_env_file.secret_id
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = module.main_tom_toolkit_project.project_id
      }
#       env {
#         name = "SECRET_ENV_VAR"
#         value_source {
#           secret_key_ref {
#             secret = google_secret_manager_secret.secret_tom_toolkit_env_file.secret_id
#             version = "latest"
#           }
#         }
#       }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      # For some reasons, we get
      # django.db.utils.OperationalError: connection is bad: connection to server on socket "/cloudsql/tom-toolkit-dev-hxm:europe-west1:tom-toolkit-instance-dev-ae78f371/.s.PGSQL.5432" failed: No such file or directory
      resources {
        limits = {
          cpu    = var.cloudrun_config.cpu_limits
          memory = var.cloudrun_config.memory_limits
        }
        cpu_idle = true # Determines whether CPU is only allocated during requests
      }
    }
  }
  ingress    = "INGRESS_TRAFFIC_ALL"
	depends_on = [
		google_sql_database_instance.main_tom_toolkit_db,
		google_secret_manager_secret_version.secret_version_secret_tom_toolkit_env_file]
}

# Typical issue with user acces through browser, getting 403 error
# https://cloud.google.com/run/docs/troubleshooting#unauthorized-client

# Invoker
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam
resource "google_cloud_run_v2_service_iam_member" "invoker" {
	project  = google_cloud_run_v2_service.tom_toolkit.project
	location = google_cloud_run_v2_service.tom_toolkit.location
	name     = google_cloud_run_v2_service.tom_toolkit.name
	role     = "roles/run.invoker"
	member   = google_service_account.tom_toolkit_service_account.member
}

# Developer
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam
resource "google_cloud_run_v2_service_iam_member" "developer" {
  project  = google_cloud_run_v2_service.tom_toolkit.project
  location = google_cloud_run_v2_service.tom_toolkit.location
  name     = google_cloud_run_v2_service.tom_toolkit.name
  role     = "roles/run.developer"
	member   = "user:${var.administrator_email}"
}

# Administrator
resource "google_project_iam_member" "project_wide_cloudrun_administrator" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/run.admin"
	member  = "user:${var.administrator_email}"
}

# CICD deployer
# Needed authorizations are listed here: https://github.com/google-github-actions/deploy-cloudrun
resource "google_project_iam_member" "project_wide_cicd_cloudrun_administration" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/run.admin"
  member  = google_service_account.cicd_service_account.member
}

# CICD deployer
# Needed authorizations are listed here: https://github.com/google-github-actions/deploy-cloudrun
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam#google_service_account_iam_member-1
resource "google_service_account_iam_member" "cicd_compute_sa_member" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.cicd_service_account.member
}

# CICD deployer
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam#google_service_account_iam_member-1
resource "google_service_account_iam_member" "cicd_cloudrun_attached_sa_member" {
  service_account_id = google_service_account.tom_toolkit_service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.cicd_service_account.member
}

# No authentication
# resource "google_project_iam_member" "project_wide_cloudrun_administration" {
#   project = module.main_tom_toolkit_project.project_id
#   role    = "roles/run.admin"
#   member  = "allUsers"
# }
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count    = var.public_deployment ? 1: 0
	project  = google_cloud_run_v2_service.tom_toolkit.project
	location = google_cloud_run_v2_service.tom_toolkit.location
	name     = google_cloud_run_v2_service.tom_toolkit.name
	role     = "roles/run.invoker"
  member   = "allUsers"
  depends_on = [google_tags_tag_binding.allow_all_ingress_tag_binding]
}

#
provider "google" {
  alias = "regional-endpoint-workaround"
  tags_custom_endpoint = format("https://%s-cloudresourcemanager.googleapis.com/v3/", var.compute_region)
}

# Tag to allow allUsers IAM
# see https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/tags_tag_binding
# And https://cloud.google.com/blog/topics/developers-practitioners/how-create-public-cloud-run-services-when-domain-restricted-sharing-enforced
resource "google_tags_tag_binding" "allow_all_ingress_tag_binding" {
  parent    = "//run.googleapis.com/${google_cloud_run_v2_service.tom_toolkit.id}"
  tag_value = var.all_user_iam_true_tag_value_id
  provider  = google.regional-endpoint-workaround
}
#  --parent=//run.googleapis.com/projects/PROJECT_ID/locations/REGION/services/SERVICE
