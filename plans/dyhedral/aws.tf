variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region                  = var.aws_region
  skip_metadata_api_check = true
}

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    encrypt                 = true
    bucket                  = "dyhedral-prod-terraform-state"
    key                     = "plans/dyhedral"
    dynamodb_table          = "terraform-state-lock"
    region                  = "us-east-1"
    skip_metadata_api_check = true
  }

}