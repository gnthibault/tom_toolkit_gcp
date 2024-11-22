# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
resource "google_artifact_registry_repository" "remote-observatory-tom-repo" {
  project       = module.main_tom_toolkit_project.project_id
  location      = var.bucket_region
  repository_id = "remote-observatory-tom-repo"
  description   = "Docker repository for tom application"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
    # immutable_tags - (Optional) The repository which enabled this flag prevents all tags from being modified, moved or deleted. This does not prevent tags from being created.
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_registry
# resource "google_container_registry" "registry" {
#   project  = module.main_tom_toolkit_project.project_id
#   location = var.bucket_region
# }
#
# resource "google_storage_bucket_iam_member" "viewer" {
#   bucket = google_container_registry.registry.id
#   role = "roles/storage.objectViewer"
#   member = "user:${var.administrator_email}"
# }

# To properly setup artifact registry IAM, please check https://cloud.google.com/artifact-registry/docs/access-control

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam#google_artifact_registry_repository_iam_member
resource "google_artifact_registry_repository_iam_member" "member_runner" {
  project       = google_artifact_registry_repository.remote-observatory-tom-repo.project
  location      = google_artifact_registry_repository.remote-observatory-tom-repo.location
  repository    = google_artifact_registry_repository.remote-observatory-tom-repo.name
  role          = "roles/artifactregistry.reader"
  member        = google_service_account.tom_toolkit_service_account.member
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam#google_artifact_registry_repository_iam_member
resource "google_artifact_registry_repository_iam_member" "member_basic_admin" {
  project       = google_artifact_registry_repository.remote-observatory-tom-repo.project
  location      = google_artifact_registry_repository.remote-observatory-tom-repo.location
  repository    = google_artifact_registry_repository.remote-observatory-tom-repo.name
  role          = "roles/artifactregistry.repoAdmin"
  member = "user:${var.administrator_email}"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam#google_artifact_registry_repository_iam_member
# One might maybe want either "roles/artifactregistry.writer or roles/artifactregistry.createOnPushWriter
# See official doc: https://cloud.google.com/artifact-registry/docs/access-control
# Or https://roger-that-dev.medium.com/push-code-with-github-actions-to-google-clouds-artifact-registry-60d256f8072f
# Note: If the application image already existed in our repository, then roles/artifactregistry.writer would suffice. We’re using roles/artifactregistry.createOnPushWriter instead because on the first push, it needs to be able to create the initial image for our application
resource "google_artifact_registry_repository_iam_member" "member_builder" {
  project       = google_artifact_registry_repository.remote-observatory-tom-repo.project
  location      = google_artifact_registry_repository.remote-observatory-tom-repo.location
  repository    = google_artifact_registry_repository.remote-observatory-tom-repo.name
  role          = "roles/artifactregistry.createOnPushWriter"
  member        = google_service_account.cicd_service_account.member
}
