provider "aws" { region = "us-east-1" }

# 1. DYNAMODB TABLE
resource "aws_dynamodb_table" "donuts" {
  name         = "PDC_Donuts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "DonutID"

  attribute {
    name = "DonutID"
    type = "S"
  }
}

# 2. S3 WEBSITE BUCKET
resource "aws_s3_bucket" "site" {
  bucket = "pdc-donut-sticker-bucket"
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
}

# Make S3 Public for hosting
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "read_access" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "s3:GetObject", Effect = "Allow",
      Principal = "*", Resource = "${aws_s3_bucket.site.arn}/*"
    }]
  })
}

# 3. LAMBDA & API GATEWAY 
# --- 3. LAMBDA & API GATEWAY ---

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "pdc_sticker_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Permission for Lambda to read from DynamoDB
resource "aws_iam_role_policy" "lambda_dynamo" {
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["dynamodb:Scan", "dynamodb:GetItem"]
      Effect = "Allow"
      Resource = aws_dynamodb_table.donuts.arn
    }]
  })
}

# The Lambda Function
resource "aws_lambda_function" "get_stickers" {
  filename      = "lambda_function.zip" # Make sure your zip file is in the root!
  function_name = "PDC_GetStickers"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.donuts.name
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name = "PDC_Sticker_API"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "donuts"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_stickers.invoke_arn
}

# Permission for API Gateway to call Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_stickers.function_name
  principal     = "apigateway.amazonaws.com"
}

# Deploy the API to a "prod" stage
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

# THE OUTPUT: This is the link you'll paste into index.html
output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/donuts"
}