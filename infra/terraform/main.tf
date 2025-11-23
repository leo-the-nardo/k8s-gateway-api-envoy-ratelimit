terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket         = "tfstates-data-lab"
    key            = "infra-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-data-lab"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

}

provider "aws" {
  region = var.aws_region
}

