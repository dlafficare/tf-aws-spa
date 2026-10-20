output "url" {
  description = "The public HTTPS URL of the SPA."
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "bucket_id" {
  description = "The name of the bucket hosting the SPA files."
  value       = aws_s3_bucket.main.id
}

output "distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.main.id
}
