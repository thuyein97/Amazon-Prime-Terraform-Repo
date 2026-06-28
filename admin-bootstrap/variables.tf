variable "aws_region" {
  type        = string
  description = "AWS region for bootstrap resources."
  default     = "ap-southeast-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for tagging and IAM role naming."
  default     = "bankapp"
}

variable "github_repository" {
  type        = string
  description = "GitHub repo allowed to assume the CI role (org/repo)."
  default     = "thuyein97/Amazon-Prime-Terraform-Repo"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state."
}

variable "create_github_oidc_provider" {
  type        = bool
  description = "Create the GitHub OIDC provider. Set false if it already exists in the account."
  default     = true
}
