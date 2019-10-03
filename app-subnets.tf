resource "aws_subnet" "app-subnet-us-east-1a" {
  availability_zone = "us-east-1a"
  cidr_block = "172.17.1.0/26"
  vpc_id = aws_vpc.datastage-vpc.id
  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - Application Subnet us-east-1a"
  }
}

resource "aws_subnet" "app-subnet-us-east-1b" {
  availability_zone = "us-east-1b"
  cidr_block = "172.17.1.64/26"
  vpc_id = aws_vpc.datastage-vpc.id
  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - Application Subnet us-east-1b"
  }
}

resource "aws_subnet" "app-subnet-us-east-1c" {
  availability_zone = "us-east-1c"
  cidr_block = "172.17.1.128/26"
  vpc_id = aws_vpc.datastage-vpc.id
  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - Application Subnet us-east-1c"
  }
}


