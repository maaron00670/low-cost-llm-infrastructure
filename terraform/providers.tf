# Configuración de los requerimientos de Terraform
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor de AWS
provider "aws" {
  region = var.aws_region

  # Tags globales para FinOps y organización
  default_tags {
    tags = {
      Environment = "Dev"
      Project     = "Low-Cost-Secure-LLM"
      ManagedBy   = "Terraform"
    }
  }
}