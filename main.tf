terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.48.0"
    }
  }
}
provider "aws" {
  profile = "bill66"
  region = "us-west-2"  
}
# resource "aws_vpc" "bill_vpc" {
#   cidr_block = "192.168.100.0/24"
#   enable_dns_hostnames = true
  
#   tags = {
#     Name = "bill_vpc"
#   }
# }
resource "aws_subnet" "bill_subnet" {
  vpc_id            = "vpc-08283a2f3454394f5"
  cidr_block        = "192.168.100.0/27"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "bill-subnet"
  }
  }
resource "aws_internet_gateway" "bill_gw" {
  vpc_id = "vpc-08283a2f3454394f5"
}
resource "aws_route_table" "bill_rt" {
  vpc_id = "vpc-08283a2f3454394f5"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bill_gw.id
  }
}
resource "aws_main_route_table_association" "main_rtb" {
  vpc_id         = "vpc-08283a2f3454394f5"
  route_table_id = aws_route_table.bill_rt.id
}
resource "aws_default_security_group" "default" {
  vpc_id = "vpc-08283a2f3454394f5"
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = true
      to_port          = 0
    },
  ]
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "bill_ec2" {
  ami = "ami-066333d9c572b0680"
  instance_type = "t3.medium"
  subnet_id = aws_subnet.bill_subnet.id
  iam_instance_profile = "jenkins"
  depends_on = [aws_internet_gateway.bill_gw]
}
resource "aws_cloudwatch_metric_alarm" "my_alarm" {
    alarm_name          = "my_alarm"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods  = 12
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    threshold           = 10
    alarm_description = "Stop the EC2 instance when CPU utilization stays below 10% on average for 12 periods of 5 minutes, i.e. 1 hour"
    alarm_actions     = ["arn:aws:automate:us-west-2:ec2:stop"]
    dimensions = {
        InstanceId = aws_instance.bill_ec2.id
    }
}