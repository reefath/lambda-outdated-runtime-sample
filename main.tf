terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/function.zip"
}

# Sample Lambda on a supported Python runtime.
resource "aws_lambda_function" "sample" {
  function_name    = var.function_name
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256

  timeout     = 10
  memory_size = 128
}
