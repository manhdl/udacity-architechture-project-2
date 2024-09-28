provider "aws" {
    access_key = "<Your Access Key>"
    secret_key = "<Your Secret Key>"
    region = "us-east-1"
}

data "archive_file" "lambda_zip" {
    type = "zip"
    source_file = "greet_lambda.py"
    output_path = "lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
    name = "/aws/lambda/${var.lambda_function_name}"
    retention_in_days = 3
}

resource "aws_iam_policy" "lambda_logging" {
    name = "lambda_logging"
    path = "/"
    description = "IAM policy for logging from a lambda"

    policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        }]
    }

    EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.policy_for_lambda.name
    policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "policy_for_lambda" {
    name = "policy_for_lambda"

    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }]
    }

    EOF
}

resource "aws_lambda_function" "lambda_greeting" {
    description = "Simple python lambda function"
    role = aws_iam_role.policy_for_lambda.arn
    filename = "lambda.zip"
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    function_name = var.lambda_function_name
    handler = "${var.lambda_function_name}.lambda_handler"
    runtime = "python3.8"

    environment {
        variables = {
            greeting = "Hello terraform with aws!"
        }
    }

    depends_on = [aws_cloudwatch_log_group.lambda_log_group, aws_iam_role_policy_attachment.lambda_logs]
}
