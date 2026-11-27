# eu-central-1 test resources (names start with health-eu-). Same runtimes and versions as some
# us-east-1 cases, so AWS Health events can be compared across Regions.

provider "aws" {
  alias  = "eu"
  region = "eu-central-1"
}

locals {
  eu_subnets = ["subnet-03a417136b41c62a3", "subnet-07bbb05298d6f0a54"]

  # EU case 4: for_each over a map
  eu_workers = {
    "py39"   = { runtime = "python3.13", handler = "handler.handler", zip = "python" }
    "ruby32" = { runtime = "ruby3.2", handler = "handler.handler", zip = "ruby" }
  }
  eu_zips = {
    python = { path = data.archive_file.function.output_path, hash = data.archive_file.function.output_base64sha256 }
    ruby   = { path = data.archive_file.ruby.output_path, hash = data.archive_file.ruby.output_base64sha256 }
  }
}

# ---------- Lambda ----------

# EU case 1: Node.js 18, literal
resource "aws_lambda_function" "eu_node18" {
  provider         = aws.eu
  function_name    = "health-eu-node18-literal"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.node.output_path
  source_code_hash = data.archive_file.node.output_base64sha256
  tags             = local.tags
}

# EU case 2: Node.js 20, variable default
resource "aws_lambda_function" "eu_node20" {
  provider         = aws.eu
  function_name    = "health-eu-node20-variable"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = var.eu_node_runtime
  filename         = data.archive_file.node.output_path
  source_code_hash = data.archive_file.node.output_base64sha256
  tags             = local.tags
}

# EU case 3: Python 3.13, literal
resource "aws_lambda_function" "eu_py310" {
  provider         = aws.eu
  function_name    = "health-eu-py310-literal"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  tags             = local.tags
}

# EU case 4: for_each map (python3.13, ruby3.2)
resource "aws_lambda_function" "eu_workers" {
  provider         = aws.eu
  for_each         = local.eu_workers
  function_name    = "health-eu-foreach-${each.key}"
  role             = var.lambda_role_arn
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = local.eu_zips[each.value.zip].path
  source_code_hash = local.eu_zips[each.value.zip].hash
  tags             = local.tags
}

# EU case 5: .NET 8, literal
resource "aws_lambda_function" "eu_dotnet8" {
  provider         = aws.eu
  function_name    = "health-eu-dotnet8-literal"
  role             = var.lambda_role_arn
  handler          = "App::App.Function::Handler"
  runtime          = "dotnet8"
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  tags             = local.tags
}

# EU case 6: Java 8 (AL2), literal
resource "aws_lambda_function" "eu_java8al2" {
  provider         = aws.eu
  function_name    = "health-eu-java8al2-literal"
  role             = var.lambda_role_arn
  handler          = "example.Handler::handleRequest"
  runtime          = "java8.al2"
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  tags             = local.tags
}

# EU case 7: provided.al2 (OS-only runtime)
resource "aws_lambda_function" "eu_provided_al2" {
  provider         = aws.eu
  function_name    = "health-eu-provided-al2"
  role             = var.lambda_role_arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  tags             = local.tags
}

# EU case 8: real-code app (same as case 23), Python 3.13
resource "aws_lambda_function" "eu_report_job" {
  provider         = aws.eu
  function_name    = "health-eu-app-report-job"
  role             = var.lambda_role_arn
  handler          = "app.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.report_job.output_path
  source_code_hash = data.archive_file.report_job.output_base64sha256
  timeout          = 15
  tags             = local.tags
}

# ---------- EKS (no worker nodes, private API endpoint) ----------

# EU EKS case A: 1.32 literal, extended support
resource "aws_eks_cluster" "eu_literal" {
  provider = aws.eu
  name     = "health-eu-eks-literal"
  role_arn = var.eks_cluster_role_arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = local.eu_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  upgrade_policy {
    support_type = "EXTENDED"
  }

  tags = local.tags
}

# EU EKS case B: 1.34 from a variable default, standard support
resource "aws_eks_cluster" "eu_variable" {
  provider = aws.eu
  name     = "health-eu-eks-variable"
  role_arn = var.eks_cluster_role_arn
  version  = var.eu_eks_version

  vpc_config {
    subnet_ids              = local.eu_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  tags = local.tags
}
