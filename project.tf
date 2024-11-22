# https://github.com/terraform-google-modules/terraform-google-project-factory
module "main_tom_toolkit_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 17.0"

	# Definition
  name               = "tom-toolkit-${var.environment}"
	project_id         = "tom-toolkit-${var.environment}" # The ID to give the project. If not provided, the name will be used.	string	""	no
	random_project_id  = true	                # Adds a suffix of 4 random characters to the project_id.	bool	false	no
	random_project_id_length = 3	            # Sets the length of random_project_id to the provided length, and uses a random_string for a larger collusion domain. Recommended for use with CI.
	folder_id          = var.folder_id
	org_id             = var.organization_id	#The organization ID.	string	null	no
	billing_account	   = var.billing_account # Attach the billing account (billing_account) to the project.
	essential_contacts = {
		(var.administrator_email) = ["ALL"]
	}

	# Service account
	project_sa_name    = "project-service-account"	# Default service account name for the project.	string	"project-service-account"	no
	sa_role            = ""

	# Features apis
	activate_apis      = [
		"artifactregistry.googleapis.com",
		"iamcredentials.googleapis.com",
		"run.googleapis.com",
		"sqladmin.googleapis.com",
		"secretmanager.googleapis.com",
		"securetoken.googleapis.com",
		"storage.googleapis.com"]
# 	activate_api_identities = [{
#     api = "sqladmin.googleapis.com"
#     roles = [
#       "roles/cloudsql.serviceAgent",
#     ]
#   }]

# 	  run.googleapis.com \
#   sql-component.googleapis.com \
#   sqladmin.googleapis.com \
#   compute.googleapis.com \
#   cloudbuild.googleapis.com \
#   secretmanager.googleapis.com \
#   artifactregistry.googleapis.com


	# Bucket for metadata
  #usage_bucket_name    = "pf-test-1-usage-report-bucket" # Name of a GCS bucket to store GCE usage reports in (optional)
  #usage_bucket_prefix  = "pf/test/1/integration"         # Prefix in the GCS bucket to store GCE usage reports in (optional)
	#bucket_name          = ""                              # A name for a GCS bucket to create (in the bucket_project project), useful for Terraform state (optional)
	#bucket_location      = var.bucket_region               # The location for a GCS bucket to create (optional)
	#bucket_pap	          = ""                              # Enable Public Access Prevention. Possible values are "enforced" or "inherited".	string	"inherited"	no
	#bucket_project       = ""                              # A project to create a GCS bucket (bucket_name) in, useful for Terraform state (optional)	string	""	no
	#bucket_ula	Enable    = ""                              # Uniform Bucket Level Access	bool	true	no
	#bucket_versioning	  = ""                              # Enable versioning for a GCS bucket to create (optional)

	# Lifecycle management
	deletion_policy                = "DELETE"
	disable_dependent_services     = true
	disable_services_on_destroy    = true

	# Networking
  #svpc_host_project_id	         = ""        # If a shared VPC is specified, attach the new project to the svpc_host_project_id
  auto_create_network            = false     # Create the default network
	enable_shared_vpc_host_project = false     # If this project is a shared VPC host project. If true, you must not set svpc_host_project_id variable. Default is false.
	shared_vpc_subnets             = []        # List of subnets fully qualified subnet IDs (ie. projects/$project_id/regions/$region/subnetworks/$subnet_id)	list(string)	[]	no
	grant_network_role             = false     # Whether or not to grant networkUser role on the host project/subnets
	grant_services_security_admin_role = false # Whether or not to grant Kubernetes Engine Service Agent the Security Admin role on the host project so it can manage firewall rules

	vpc_service_control_attach_dry_run = false # Whether the project will be attached to a VPC Service Control Perimeter in Dry Run Mode. vpc_service_control_attach_enabled should be false for this to be true	bool	false	no
	vpc_service_control_attach_enabled = false # Whether the project will be attached to a VPC Service Control Perimeter in ENFORCED MODE. vpc_service_control_attach_dry_run should be false for this to be true	bool	false	no
	#vpc_service_control_perimeter_name = var.vpc_service_control_perimeter_name # The name of a VPC Service Control Perimeter to add the created project to	string	null	no
	#vpc_service_control_sleep_duration = 0     # The duration to sleep in seconds before adding the project to a shared VPC after the project is added to the VPC Service Control Perimeter. VPC-SC is eventually consistent.
}

# Outputs
# api_s_account	API service account email
# api_s_account_fmt	API service account email formatted for terraform use
# budget_name	The name of the budget if created
# domain	The organization's domain
# enabled_api_identities	Enabled API identities in the project
# enabled_apis	Enabled APIs in the project
# group_email	The email of the G Suite group with group_name
# project_bucket_self_link	Project's bucket selfLink
# project_bucket_url	Project's bucket url
# project_id	ID of the project
# project_name	Name of the project
# project_number	Numeric identifier for the project
# service_account_display_name	The display name of the default service account
# service_account_email	The email of the default service account
# service_account_id	The id of the default service account
# service_account_name	The fully-qualified name of the default service account
# service_account_unique_id	The unique id of the default service account
# tag_bindings	Tag bindings
# usage_report_export_bucket	GCE usage reports bucket
