resource "aws_launch_template" "httpd-launch-template" {
  name_prefix = "httpd"
  image_id = "ami-05091d5b01d0fda35"
  instance_type = "m5.large"
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = true
      encrypted = true
      volume_size = 30
    }
  }

  vpc_security_group_ids = [
    aws_security_group.inbound-from-public-internet.id,
    aws_security_group.outbound-to-app.id
  ]
  iam_instance_profile {
    name = aws_iam_instance_profile.httpd-deployment-s3-profile.name
  }

  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - ${var.stack_githash} - Apache HTTPD Launch Template"
  }
  tag_specifications {
    resource_type = "instance" 
    tags = {
      Name = "FISMA Terraform Playground - ${var.stack_githash} - Apache HTTPD"
    }
  }
}

resource "aws_autoscaling_group" "httpd-autoscaling-group" {
  vpc_zone_identifier = [
      var.edge-subnet-us-east-1a-id, 
      var.edge-subnet-us-east-1b-id
  ]

  desired_capacity = 1
  min_size = 1
  max_size = 1

  launch_template {
    id = aws_launch_template.httpd-launch-template.id
  }

  tag {
    key = "Name"
    value = "FISMA Terraform Playground - ${var.stack_githash} - Apache HTTPD"
    propagate_at_launch = true
  }
}