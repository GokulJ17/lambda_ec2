provider "aws" {
  region = "ap-south-1" # Change region as needed
}
resource "aws_iam_role" "lambda_ec2_role" {
  name = "lambda_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ec2_access" {
  role       = aws_iam_role.lambda_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_lambda_function" "start_instance" {
  filename         = "start_instance.zip" # Package your Python code as ZIP
  function_name    = "start_ec2_instance"
  role             = aws_iam_role.lambda_ec2_role.arn
  handler          = "start.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("start_instance.zip")

  environment {
    variables = {
      INSTANCE_ID = "i-0e2155018d48acf2e" # Replace with your EC2 instance ID
      REGION      = "ap-south-1"
    }
  }
}
resource "aws_lambda_function" "stop_instance" {
  filename         = "stop_instance.zip"
  function_name    = "stop_ec2_instance"
  role             = aws_iam_role.lambda_ec2_role.arn
  handler          = "stop.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("stop_instance.zip")

  environment {
    variables = {
      INSTANCE_ID = "i-0e2155018d48acf2e"
      REGION      = "ap-south-1"
    }
  }
}
resource "aws_cloudwatch_event_rule" "start_event" {
  name                = "start_ec2_event"
  schedule_expression = "cron(25 07 * * ? *)"
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_event.name
  target_id = "StartEC2Instance"
  arn       = aws_lambda_function.start_instance.arn
}
resource "aws_cloudwatch_event_rule" "stop_event" {
  name                = "stop_ec2_event"
  schedule_expression = "cron(30 07 * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_event.name
  target_id = "StopEC2Instance"
  arn       = aws_lambda_function.stop_instance.arn
}

resource "aws_lambda_permission" "allow_start_event" {
  statement_id  = "AllowStartEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_event.arn
}

resource "aws_lambda_permission" "allow_stop_event" {
  statement_id  = "AllowStopEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_event.arn
}
  
