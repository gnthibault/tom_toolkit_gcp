# Pretty nice tutorial on how to setup keyless authentication: https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions
# And this one: https://roger-that-dev.medium.com/push-code-with-github-actions-to-google-clouds-artifact-registry-60d256f8072f

data "google_project" "default" {
  project_id = module.main_tom_toolkit_project.project_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool
resource "google_iam_workload_identity_pool" "cicd_identity_pool" {
  project                     = module.main_tom_toolkit_project.project_id
  workload_identity_pool_id 	= "cicd-pool-${var.environment}"
  display_name            		= "cicd-pool-${var.environment}"
  description             		= "${var.environment} Pool"
  disabled                		= false
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider
# In particular for github: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#example-usage---iam-workload-identity-pool-provider-github-actions
# GitHub uses OIDC to authenticate with different cloud providers (see GitHub documentation on it here: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers)
resource "google_iam_workload_identity_pool_provider" "github_identity_pool_provider" {
  project                               = module.main_tom_toolkit_project.project_id
  workload_identity_pool_id           	= google_iam_workload_identity_pool.cicd_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id  	= "github-oidc-${var.environment}"
  display_name                        	= "github-oidc-${var.environment}"
  description                           = "GitHub Actions identity pool provider for automated test"
  disabled                        			= false

  # From https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#example-usage---iam-workload-identity-pool-provider-github-actions
  # The way GCP is supposed to acces github oidc request is described here: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    attribute_condition = <<EOT
      assertion.sub              == "${var.wif_subject}"             &&
      assertion.repository       == "${var.github_repository_name}"  &&
      assertion.repository_owner == "${var.github_repository_owner}" &&
      assertion.environment      == "${var.environment}"
EOT

  # Based on tutorial at https://roger-that-dev.medium.com/push-code-with-github-actions-to-google-clouds-artifact-registry-60d256f8072f
  # Official trust strategy defined here: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#configuring-the-oidc-trust-with-the-cloud
  # All supported claims defined here: https://token.actions.githubusercontent.com/.well-known/openid-configuration
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.environment"      = "assertion.environment"
    "attribute.ref"              = "assertion.ref"
    "attribute.ref_type"         = "assertion.ref_type"
  }

  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#nested_oidc
  oidc {
       issuer_uri        = "https://token.actions.githubusercontent.com"
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam#google_service_account_iam_member-1
# And https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider#argument-reference
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.cicd_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.cicd_identity_pool.name}/subject/${var.wif_subject}"
  # For the subject, please check this documentation:
  # Basically, you need to enable ADMIN_READ cloud audit log on sts.googleapis.com and check protoPayload.authenticationInfo.principalSubject in the logs
  # It can be customized from github with https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#customizing-the-subject-claims-for-an-organization-or-repository
}

# Administrator
resource "google_project_iam_member" "project_wide_worload_identity_administration" {
  project = module.main_tom_toolkit_project.project_id
  role    = "roles/iam.workloadIdentityPoolAdmin" # TODO TN "roles/iam.workloadIdentityPoolViewer" would be safer
	member  = "user:${var.administrator_email}"
}

# You might want to implement what is described here: https://cloud.google.com/iam/docs/audit-logging/examples-workload-identity#exchange-federated

# Identity and Access Management (IAM) API (enable log type "Admin Read")
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam#google_project_iam_audit_config
resource "google_project_iam_audit_config" "audit_log_iam_api" {
  count = var.debug_wif ? 1 : 0
  project = module.main_tom_toolkit_project.project_id
  service = "iam.googleapis.com"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
}

# Security Token Service API (enable log type "Admin Read")
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam#google_project_iam_audit_config
resource "google_project_iam_audit_config" "audit_log_securetoken_api" {
  count = var.debug_wif ? 1 : 0
  project = module.main_tom_toolkit_project.project_id
  service = "sts.googleapis.com"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
}