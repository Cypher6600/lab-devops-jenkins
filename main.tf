terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.48.0"
    }
  }
}
provider "aws" {
  profile = "PowerUserAccess-529396670287"
  region = "us-west-2"  
}
# resource "aws_vpc" "bill_vpc" {
#   cidr_block = "192.168.100.0/24"
#   enable_dns_hostnames = true
  
#   tags = {
#     Name = "bill_vpc"
#   }
# }
# resource "aws_subnet" "bill_subnet" {
#   vpc_id            = aws_vpc.bill_vpc.id
#   cidr_block        = "192.168.100.0/27"
#   availability_zone = "us-west-2a"
#   map_public_ip_on_launch = true
  
#   tags = {
#     Name = "bill-subnet"
#   }
# }
# resource "aws_internet_gateway" "bill_gw" {
#   vpc_id = aws_vpc.bill_vpc.id
# }
# resource "aws_default_route_table" "bill_rt" {
#   vpc_id = aws_vpc.bill_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.my_gateway.id
#   }
# }
# resource "aws_network_interface" "net1" {
#   subnet_id   = aws_subnet.my_subnet.id
#   private_ips = ["192.168.100.100"]
  
#   tags = {
#       Name = "bill-network"
#   }
# }
# resource "aws_route_table_association" "public_subnet_rta" {
#   subnet_id      =  aws_subnet.my_subnet.id
#   route_table_id = aws_route_table.my_table.id
# }
resource "aws_security_group" "allow_tls" {
vpc_id = aws_vpc.bill_vpc.id
  name        = "Security_01"
  description = "Allow SSH & HTTP inbound traffic"
ingress {
    description = "allowing HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "allowing SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "Security_01"
  }
}
output "sec_op"{
 value = aws_security_group.allow_tls.name
}
resource "aws_instance" "bill_ec2" {
  ami = "ami-066333d9c572b0680"
  instance_type = "t3.medium"
  subnet_id = aws_subnet.bill_subnet.id
 vpc_security_group_ids = aws_security_group.allow_tls.id 
#   network_interface {
#       device_index = 0
#   network_interface_id = aws_network_interface.net1.id
#    }
}
resource "aws_key_pair" "bill_key" {
  key_name   = "bill-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCRJ+6PJIROASTo4DwA9P6IAdqe8bIE2CUvmKlWbao605hmUr+o/RRi04zlrgMG7uSyJIkm/Mv/f/ljoT/V6cBwJdQX8gzobHQSe++eb/V3GayMIgMmP+qYKu+2Oek32Kdl0ahdOljR08cty31NRuFHg83o0MMoo5qF9lulK0VFpKAg+h7moxI0ezlgnEzszxWad+JWrDsh7LZYVZcZwhX+V8zQhsJATg7Nxcu3IZCSdTLbv/YahAWjdEF/g7c7cEbMLqir7AeWQaQk7pNrm1cs0Nl3RYYB8NTb0deShMewB0ErpC5S3R0QGM71IK2L28xSFG9W/RFAC6NZVxSJLhgv"
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
    alarm_actions     = ["arn:aws:automate:${var.region}:ec2:stop"]
    dimensions = {
        InstanceId = "${aws_instance.my_instance.id}"
    }
}
resource "aws_iam_instance_profile" "test_profile" {
  name = "jenkins"
  role = "${aws_iam_role.test_role.name}"
}