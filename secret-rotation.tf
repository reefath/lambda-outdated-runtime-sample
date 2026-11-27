# Case 20: file name contains "secret" (known: the TD never scans these files).
resource "aws_lambda_function" "secret_rotation" {
  function_name    = "health-td-secret-rotation-py310"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  tags             = local.tags
}
