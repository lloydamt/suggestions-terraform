terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
  }

  cloud {
    organization = "lloydamt_solutions-org"

    workspaces {
      name = "screen-stash"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_s3_bucket" "frontend-bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "fe-bucket-public_access_block" {
  bucket = aws_s3_bucket.frontend-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "fe-bucket-ownership" {
  bucket = aws_s3_bucket.frontend-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "fe-bucket-policy" {
  bucket = aws_s3_bucket.frontend-bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject"
        "Resource" : "arn:aws:s3:::${var.bucket_name}/**"
      }
    ]
  })

  depends_on = [ aws_s3_bucket_ownership_controls.fe-bucket-ownership, aws_s3_bucket_public_access_block.fe-bucket-public_access_block ]
}

resource "aws_s3_bucket_acl" "fe-bucket-public-acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.fe-bucket-ownership,
    aws_s3_bucket_public_access_block.fe-bucket-public_access_block,
  ]

  bucket = aws_s3_bucket.frontend-bucket.id
  acl    = "public-read"
}

# Upload index.html
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.frontend-bucket.bucket
  key    = "index.html"
  source = "dist/index.html"
  content_type = "text/html"
  depends_on = [ aws_s3_bucket_public_access_block.fe-bucket-public_access_block ]
}

# # Upload favicon.jpg
resource "aws_s3_object" "favicon" {
  bucket = aws_s3_bucket.frontend-bucket.bucket
  key    = "favicon.ico"
  source = "dist/favicon.ico"
  depends_on = [ aws_s3_bucket_public_access_block.fe-bucket-public_access_block ]
}

# Upload all files from the css directory
resource "aws_s3_object" "css_files" {
  for_each = fileset("dist/css", "**")
  bucket = aws_s3_bucket.frontend-bucket.bucket
  key    = "css/${each.value}"
  source = "dist/css/${each.value}"
  content_type = "text/css"
  depends_on = [ aws_s3_bucket_public_access_block.fe-bucket-public_access_block ]
}

# # Upload all files from the js directory
resource "aws_s3_object" "js_files" {
  for_each = fileset("dist/js", "**")

  bucket = aws_s3_bucket.frontend-bucket.bucket
  key    = "js/${each.value}"
  source = "dist/js/${each.value}"
  content_type = "application/javascript"
  depends_on = [ aws_s3_bucket_public_access_block.fe-bucket-public_access_block ]
}

resource "aws_s3_bucket_website_configuration" "website-config" {
  bucket = aws_s3_bucket.frontend-bucket.id

  index_document {
    suffix = "index.html"
  }
}

output "website_url" {
    value = aws_s3_bucket_website_configuration.website-config.website_endpoint
}