terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "6.37.0"
        }
    }

    backend "s3" {
        bucket = "banckend-remote"
        key = "expense-dev-bastion"
        region = "us-east-1"
        dynamodb_table = "remote-locking" 
    }
}

provider "aws" {
    region = "us-east-1"
} 