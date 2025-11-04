terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
  
  # Optional: Configure remote state backend
  # Uncomment and configure when ready to use remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "kubernetes/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

