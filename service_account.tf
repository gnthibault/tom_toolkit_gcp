data "google_compute_default_service_account" "default" {
  project = module.main_tom_toolkit_project.project_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "tom_toolkit_service_account" {
	project      = module.main_tom_toolkit_project.project_id
  account_id   = "tom-toolkit-sa"
  display_name = "Tom toolkit SA"
  description  = "Service Account used by Cloud run tom toolkit instance"
}
# id - an identifier for the resource with format projects/{{project}}/serviceAccounts/{{email}}
# email - The e-mail address of the service account. This value should be referenced from any google_iam_policy data sources that would grant the service account privileges.
# name - The fully-qualified name of the service account.
# unique_id - The unique id of the service account.
# member - The Identity of the service account in the form serviceAccount:{email}. This value is often used to refer to the service account in order to grant IAM permissions.

resource "google_service_account" "cicd_service_account" {
	project      = module.main_tom_toolkit_project.project_id
  account_id   = "cicd-tom-sa"
  display_name = "cicd-tom-sa"
  description  = "Service Account used by CI/CD to build and deploy tom toolkit"
}

# Administrator if it needs to run gcloud run deploy
resource "google_service_account_iam_member" "administrator_compute_sa_member" {
  service_account_id = google_service_account.tom_toolkit_service_account.name
  role               = "roles/iam.serviceAccountUser"
	member             = "user:${var.administrator_email}"
}
