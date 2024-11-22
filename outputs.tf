output "tom_toolkit_project_id" {
  description = "GCP project hosting tom toolkit deployment"
  value       = module.main_tom_toolkit_project.project_id
}

output "tom_toolkit_service_account" {
  description = "Id of the service account associated with the tom toolkit cloudrun"
  value       = google_service_account.tom_toolkit_service_account.email
}

output "tom_toolkit_cloudrun_instance_name" {
  description = "Cloudrun instance name for the tom toolkit application"
  value       = google_cloud_run_v2_service.tom_toolkit.name
}

output "tom_toolkit_cloudsql_instance_name" {
  description = "Cloud SQL instance name for the tom toolkit application"
  value       = google_sql_database_instance.main_tom_toolkit_db.name
}

output "tom_toolkit_cloudstorage_instance_name" {
  description = "Cloud storage instance name for the tom toolkit application static data"
  value       = google_storage_bucket.tom_toolkit_static_files.name
}

output "tom_toolkit_artifact_registry_instance_name" {
  description = "Artifact registry instance name for the tom toolkit application docker"
  value       = google_artifact_registry_repository.remote-observatory-tom-repo.name
}
