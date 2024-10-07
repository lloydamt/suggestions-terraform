variable "bucket_name" {
  type        = string
  description = "Name of bucket"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "fe-bucket_policy" {
  type = string
}