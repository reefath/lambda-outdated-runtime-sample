# Real-code Lambdas (cases 22-24): the code itself breaks on a plain runtime bump.
# The upgrade agent must change the code, not just the runtime line. See README.md.

data "archive_file" "orders_api" {
  type        = "zip"
  source_dir  = "${path.module}/apps/orders-api-node16"
  output_path = "${path.module}/.zips/orders-api.zip"
}

data "archive_file" "report_job" {
  type        = "zip"
  source_dir  = "${path.module}/apps/report-job-py38"
  output_path = "${path.module}/.zips/report-job.zip"
  excludes    = ["tests"]
}

data "archive_file" "billing" {
  type        = "zip"
  source_dir  = "${path.module}/apps/billing-ruby32"
  output_path = "${path.module}/.zips/billing.zip"
}

# Case 22
resource "aws_lambda_function" "orders_api" {
  function_name    = "health-td-app-orders-api"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  filename         = data.archive_file.orders_api.output_path
  source_code_hash = data.archive_file.orders_api.output_base64sha256
  timeout          = 15
  tags             = local.tags
}

# Case 23
resource "aws_lambda_function" "report_job" {
  function_name    = "health-td-app-report-job"
  role             = var.lambda_role_arn
  handler          = "app.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.report_job.output_path
  source_code_hash = data.archive_file.report_job.output_base64sha256
  timeout          = 15
  tags             = local.tags
}

# Case 24
resource "aws_lambda_function" "billing" {
  function_name    = "health-td-app-billing"
  role             = var.lambda_role_arn
  handler          = "lambda_function.handler"
  runtime          = "ruby3.2"
  filename         = data.archive_file.billing.output_path
  source_code_hash = data.archive_file.billing.output_base64sha256
  timeout          = 15
  tags             = local.tags
}
