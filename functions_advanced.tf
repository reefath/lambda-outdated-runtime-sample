# Harder Lambda test cases (11+). Each one uses a form from aws-health-td-known-issues.md.
# See README.md for what the TD should find.

locals {
  zips = {
    node   = { path = data.archive_file.node.output_path, hash = data.archive_file.node.output_base64sha256 }
    python = { path = data.archive_file.function.output_path, hash = data.archive_file.function.output_base64sha256 }
  }

  # Case 11: for_each over a map; runtime is each.value.runtime
  workers = {
    "worker-node16" = { runtime = "nodejs16.x", handler = "index.handler", zip = "node" }
    "worker-py38"   = { runtime = "python3.13", handler = "handler.handler", zip = "python" }
  }
}

resource "aws_lambda_function" "workers" {
  for_each         = local.workers
  function_name    = "health-td-foreach-${each.key}"
  role             = var.lambda_role_arn
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = local.zips[each.value.zip].path
  source_code_hash = local.zips[each.value.zip].hash
  tags             = local.tags
}

# Case 12: coalesce() with a fallback literal
resource "aws_lambda_function" "java8_coalesce" {
  function_name    = "health-td-java8-coalesce"
  role             = var.lambda_role_arn
  handler          = "example.Handler::handleRequest"
  runtime          = coalesce(var.java_runtime_override, "java8.al2")
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  tags             = local.tags
}

# Case 13: string interpolation builds the runtime
resource "aws_lambda_function" "node_interpolated" {
  function_name    = "health-td-node-interpolated"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs${var.node_major}.x"
  filename         = data.archive_file.node.output_path
  source_code_hash = data.archive_file.node.output_base64sha256
  tags             = local.tags
}

# Case 14: module input with a prefixed key name (lambda_runtime)
module "legacy_dotnet" {
  source         = "./modules/legacy_fn"
  name           = "health-td-dotnet6-prefixed-key"
  lambda_runtime = "dotnet6"
  handler        = "App::App.Function::Handler"
  role           = var.lambda_role_arn
  filename       = data.archive_file.placeholder.output_path
  hash           = data.archive_file.placeholder.output_base64sha256
  tags           = local.tags
}

# Case 15: provided.al2 custom runtime (known: never matched)
resource "aws_lambda_function" "provided_al2" {
  function_name    = "health-td-provided-al2"
  role             = var.lambda_role_arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  tags             = local.tags
}

# Case 16: DECOY. Real runtime is current; the old version is only in a comment.
# Expected: no finding, and no Health event.
resource "aws_lambda_function" "comment_decoy" {
  function_name    = "health-td-comment-decoy"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12" # was python3.8 before the 2025 upgrade
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  tags             = local.tags
}

# Cases 17-19 are CloudFormation templates in cloudformation/, deployed from here.
resource "aws_cloudformation_stack" "cfn_lambdas" {
  name          = "health-td-cfn-lambdas"
  template_body = file("${path.module}/cloudformation/lambdas.yaml")
  parameters = {
    LambdaRoleArn = var.lambda_role_arn
  }
  tags = local.tags
}
