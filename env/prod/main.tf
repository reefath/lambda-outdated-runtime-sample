# Case 4: Python runtime set as a literal, inside a folder named env/.

variable "role" { type = string }
variable "filename" { type = string }
variable "hash" { type = string }
variable "tags" { type = map(string) }

resource "aws_lambda_function" "py39" {
  function_name    = "health-td-py39-env-folder"
  role             = var.role
  handler          = "handler.handler"
  runtime          = "python3.13"
  filename         = var.filename
  source_code_hash = var.hash
  tags             = var.tags
}
