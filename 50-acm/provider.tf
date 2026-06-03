terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.48.0"
        }
    }

    backend "s3" {
        bucket = "banckend-remote"
        key = "expense-dev-acm"
        region = "us-east-1"
        dynamodb_table = "remote-locking" 
    }
}

provider "aws" {
    region = "us-east-1"
} 