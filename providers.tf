terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "terraform-state-marcelo-menezes"
    key            = "webio/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "webio"
      ManagedBy = "Terraform"
    }
  }
}

provider "random" {}
