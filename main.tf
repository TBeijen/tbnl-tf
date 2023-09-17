terraform {
  required_version = "~> 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
  }
  # Need to come up with hack to configure remote state based on vars or workspace
  backend "s3" {
    bucket         = "tfstate-tbnl-tf-test"
    key            = "test/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tfstate-tbnl-tf-test"
    encrypt        = true
  }
}

locals {
  state_bucket         = "tfstate-${var.project}-${var.environment}"
  state_dynamodb_table = "tfstate-${var.project}-${var.environment}"
}

provider "aws" {
  region = "eu-west-1"
}

module "remote_state" {
  source = "./modules/aws_s3_remote_state"

  bucket_name    = local.state_bucket
  dynamodb_table = local.state_dynamodb_table
}
