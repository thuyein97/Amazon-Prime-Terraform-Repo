output "role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM role ARN for GitHub Actions (set as AWS_ROLE_TO_ASSUME secret)."
}

output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "S3 bucket for Terraform remote state (set as TF_STATE_BUCKET secret)."
}

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS account ID where bootstrap resources were created."
}
