
# VPC
resource "aws_vpc" "vegan_vpc" {
  cidr_block = "10.0.0.0/16" # This CIDR block could be modified as needed

  tags = {
    Name = "vegan-vpc"
  }
}

# Subnet
resource "aws_subnet" "vegan_subnet" {
  vpc_id            = aws_vpc.vegan_vpc.id
  cidr_block        = "10.0.1.0/24" # This CIDR block could be modified accordingly
  availability_zone = "eu-west-1a"  # This availability zone could be modified as needed

  tags = {
    Name = "vegan-subnet"
  }
}

# Security Group
resource "aws_security_group" "vegan_security_group" {
  vpc_id = aws_vpc.vegan_vpc.id

  #  inbound/outbound rules as needed for the microservice application
  # Allow HTTP/TCP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["your_ip_range"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "vegan-security-group"
  }
}

# RDS MySQL Database
resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  db_name              = "vegan-database"
  username             = "admin"     # In real case senario, this will be placed in a .tfvars file
  password             = "password"  # In real case senario, this also will be place in a .tfvars file
  parameter_group_name = "default.mysql5.7"
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.vegan_security_group.id]

  tags = {
    Name = "vegan-database"
  }
}

# WAF (AWS WAF Rules)
# Define AWS WAF rules to protect the microservice
# Rule Group for AWS WAF
resource "aws_wafv2_rule_group" "vegan_rule_group" {
  name     = "vegan-rule-group"
  capacity = 100
  scope    = "REGIONAL" # or change to "CLOUDFRONT" for CloudFront distributions

  # Define your rules here
  rule {
  name     = "SQLInjectionRule"
  priority = 1

  action {
  allow {} # or block {} based on desired action
  }

  statement {
  rule_group_reference_statement {
  arn = aws_wafv2_rule_group.sql_injection_rule.arn
    }
    }
  }

  visibility_config {
  cloudwatch_metrics_enabled = false
  metric_name                = "VeganWebACLMetric"
  sampled_requests_enabled   = false
  }
}

# Rule for SQL Injection Protection
resource "aws_wafv2_rule_group" "sql_injection_rule" {
  name     = "sql-injection-rule"
  capacity = 100
  scope    = "REGIONAL" # or change to "CLOUDFRONT" for CloudFront distributions

  rule {
    name     = "SQLInjectionMatchRule"
    priority = 0

    action {
      block {}
    }

    statement {
    regex_pattern_set_reference_statement {
    arn = aws_wafv2_regex_pattern_set.sql_injection_patterns.arn
      }
    }
  }

  visibility_config {
  cloudwatch_metrics_enabled = false
  metric_name                = "VeganWebACLMetric"
  sampled_requests_enabled   = false
  }
}

# Regular Expression Set for SQL Injection Patterns
resource "aws_wafv2_regex_pattern_set" "sql_injection_patterns" {
  name  = "sql-injection-patterns"
  scope = "REGIONAL" # or change to "CLOUDFRONT" for CloudFront distributions

  regular_expression {
    regex_string = "(SELECT|INSERT|UPDATE|DELETE|UNION|DROP)"
  }
}

# Attach the Rule Group to an AWS WAF WebACL
resource "aws_wafv2_web_acl" "vegan_web_acl" {
  name        = "vegan-web-acl"
  scope       = "REGIONAL" # or change to "CLOUDFRONT" for CloudFront distributions
  description = "Web ACL for protecting vegan microservice application"

  default_action {
    block {} # or allow{} based on desired action
  }

  rule {
    name     = "VeganRuleGroup"
    priority = 0

    action {
    block {}
    }

    statement {
    rule_group_reference_statement {
      arn = aws_wafv2_rule_group.vegan_rule_group.arn
      }
    }
  }
visibility_config {
  cloudwatch_metrics_enabled = false
  metric_name                = "VeganWebACLMetric"
  sampled_requests_enabled   = false
  }
}


# Application Load Balancer (ALB)
resource "aws_lb" "vegan_alb" {
  name               = "vegan-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.vegan_subnet.id]

  tags = {
    Name = "vegan-alb"
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "vegan_asg" {
  desired_capacity     = 2
  max_size             = 10
  min_size             = 1
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.vegan_lc.id
  vpc_zone_identifier  = [aws_subnet.vegan_subnet.id]

  # Define scaling policies based on traffic metrics
  # ...

}

# Launch Configuration
resource "aws_launch_configuration" "vegan_lc" {
  name            = "vegan-lc"
  image_id        = "ami-12345678" # A desired AMI can be specified here.
  instance_type   = var.aws_instance_type
  key_name        = var.aws_key_name
  security_groups = [aws_security_group.vegan_security_group.id]

  user_data = <<-EOF
#!/bin/bash
# Here, you can add the bash shell script to deploy your Java application via CI/CD
# ...
EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Output
output "alb_dns_name" {
  value = aws_lb.vegan_alb.dns_name
}
