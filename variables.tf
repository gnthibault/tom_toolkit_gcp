variable environment {
	type = string
}

variable "administrator_email" {
  type        = string
  description = "Email of the platform administrator"
}

variable "tf_sa_email" {
  type        = string
  description = "Email of the terraform SA"
}

variable "organization_id" {
  type        = string
  description = "Id of the organization"
}

variable "bucket_region" {
	type        = string
}

variable "compute_region" {
	type        = string
}

variable "billing_account" {
	type        = string
}

variable "folder_id" {
	type        = string
}

variable "all_user_iam_true_tag_value_id" {
	type        = string
}

variable "db_username" {
	type        = string
}
variable "db_password" {
	type        = string
}
variable "database_name" {
	type        = string
}

variable "public_deployment" {
	type        = bool
	default     = false
}
variable "cloudrun_config" {
	type = object({
		max_concurrency    = number
		timeout            = string
		min_instance_count = number
		max_instance_count = number
		cpu_limits         = number
		memory_limits      = string
		docker_image       = string
		env_variables      = map(string)
	})
}

# CICD Github related info
variable "repo_deploy_ref" {
	type        = string
	default     = "refs/heads/deploy_dev"
}
variable "wif_subject" {
	type        = string
}
variable "github_repository_name" {
	type        = string
}
variable "github_repository_owner" {
	type        = string
}
variable "debug_wif" {
	type        = bool
	default     = true
}
