# Map performance profiles to CDN configurations
locals {
  spa_config = {
    sandbox = {
      price_class     = "PriceClass_100"
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    }
    development = {
      price_class     = "PriceClass_100"
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    }
    production = {
      price_class     = "PriceClass_All"
      cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    }
  }

  # Content comes either inline from the Console form or from the artifacts bucket
  inline       = var.index_html != ""
  build_prefix = "${var.deployed_service}/latest/"

  tags = merge(
    {
      environment = var.performance_profile
      managed_by  = "terraform"
      service     = var.service_name
    },
    var.additional_tags
  )
}

# Private bucket hosting the SPA files, readable only by CloudFront
resource "aws_s3_bucket" "main" {
  bucket = var.service_name

  # Demo-friendly: allow bucket to be destroyed even if not empty
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = var.service_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = var.service_name
  default_root_object = "index.html"
  price_class         = local.spa_config[var.performance_profile].price_class

  origin {
    domain_name              = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id                = "s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  default_cache_behavior {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = local.spa_config[var.performance_profile].cache_policy_id
    compress               = true
  }

  # SPA routing: unknown paths fall back to index.html
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.main.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.main.arn }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# Publish the latest build uploaded by the microservice pipeline
data "aws_s3_objects" "build" {
  count = local.inline ? 0 : 1

  bucket = var.artifacts_bucket
  prefix = local.build_prefix
}

data "aws_s3_object" "build" {
  for_each = toset(local.inline ? [] : data.aws_s3_objects.build[0].keys)

  bucket = var.artifacts_bucket
  key    = each.value
}

resource "aws_s3_object_copy" "build" {
  for_each = data.aws_s3_object.build

  bucket = aws_s3_bucket.main.id
  key    = trimprefix(each.key, local.build_prefix)
  source = "${var.artifacts_bucket}/${each.key}"

  # A new upload changes the etag, which forces a new copy
  metadata_directive = "REPLACE"
  content_type       = each.value.content_type
  metadata = {
    source-etag = each.value.etag
  }
}

# Inline page written in the Console form
resource "aws_s3_object" "index" {
  count = local.inline ? 1 : 0

  bucket       = aws_s3_bucket.main.id
  key          = "index.html"
  content      = var.index_html
  content_type = "text/html; charset=utf-8"
}

# Runtime configuration read by the SPA at startup
resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.main.id
  key          = "config.json"
  content      = jsonencode(var.runtime_config)
  content_type = "application/json"
}
