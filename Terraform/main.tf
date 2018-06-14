# Infrastructure for Hygieia and Jenkins servers

# Prompt for AWS Providers
provider "aws" {
  version = "~> 1.0"
  access_key = "${var.access_key}"
  secret_key = "${var.access_secret_key}"
  region 	 = "${var.region}"
}

# Creates a key pair to connect in your EC2 instances
resource "aws_key_pair" "auth" {
 key_name = "${var.key_name}"
 public_key = "${file(var.public_key_path)}"
}

# Create Default VPC
resource "aws_vpc" "prod-main" {
  cidr_block  = "172.17.0.0/16"

  tags {
    Name = "prod-main"
  }
}

# Create Internet Gateway for VPC
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = "${aws_vpc.prod-main.id}"

  tags {
    Name = "prod-igw"
  }
}

# Public Route Table for VPC
# Attached with IGW created on last step
resource "aws_route_table" "prod-public-rt" {
  depends_on = ["aws_internet_gateway.prod-igw"]
  vpc_id = "${aws_vpc.prod-main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.prod-igw.id}"
  }

  tags {
    Name = "prod-public-rt"
  }
}

# Create one subnet for both servers
resource "aws_subnet" "subnet-app-main" {
  vpc_id     = "${aws_vpc.prod-main.id}"
  cidr_block = "172.17.10.0/24"
  availability_zone = "${lookup(var.azs, var.region)}"
  
  tags {
    Name = "subnet-app-main"
  }
}

# NACL for VPC
resource "aws_network_acl" "prod-nacl" {
  depends_on = ["aws_route_table.prod-public-rt"]
  vpc_id = "${aws_vpc.prod-main.id}"
  subnet_ids = ["${aws_subnet.subnet-app-main.id}"]

  # HTTP access from the VPC
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # SSH access from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  
  # Hygieia Port access from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 3000
    to_port    = 3000
  }
  
  # ALL access to anywhere
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# Change the route table for subnet
resource "aws_route_table_association" "subnet_public_rt" {
  subnet_id      = "${aws_subnet.subnet-app-main.id}"
  route_table_id = "${aws_route_table.prod-public-rt.id}"
}

# Change the main route table on VPC
resource "aws_main_route_table_association" "vpc_public_rt" {
  vpc_id         = "${aws_vpc.prod-main.id}"
  route_table_id = "${aws_route_table.prod-public-rt.id}"
}

# Create Security Group for jenkins
resource "aws_security_group" "sg01-jenkins" {
  name        = "sg01-jenkins"
  description = "Used in the Jenkins Server"
  vpc_id      = "${aws_vpc.prod-main.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTP access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "sg01-jenkins"
  }
}

# Create Security Group for hygieia
resource "aws_security_group" "sg01-hygieia" {
  name        = "sg01-hygieia"
  description = "Used in the Hygieia Server"
  vpc_id      = "${aws_vpc.prod-main.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Hygieia access from anywhere
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "sg01-hygieia"
  }
}

# EC2 instance for jenkins
resource "aws_instance" "jenkins-ec2" {
  ami = "${lookup(var.images, var.region)}"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.subnet-app-main.id}"
  security_groups = ["${aws_security_group.sg01-jenkins.id}"]
  private_ip = "172.17.10.100"
  associate_public_ip_address = "true"
  key_name = "${aws_key_pair.auth.id}"
  
  tags {
    Name = "jenkins-ec2"
  }
}

# EC2 instance for hygieia
resource "aws_instance" "hygieia-ec2" {
  ami = "${lookup(var.images, var.region)}"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.subnet-app-main.id}"
  security_groups = ["${aws_security_group.sg01-hygieia.id}"]
  private_ip = "172.17.10.200"
  associate_public_ip_address = "true"
  key_name = "${aws_key_pair.auth.id}"
  
  tags {
    Name = "hygieia-ec2"
  }
}
