terraform {
  required_version = "~> 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}


module "remote_state" {
  source = "./modules/aws_s3_remote_state"

  project     = var.project
  environment = var.environment
}
