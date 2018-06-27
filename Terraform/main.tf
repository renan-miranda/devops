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
  enable_dns_hostnames = "true"

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

  # ALL access to anywhere
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
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

  # Inbound internet access
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

  # Inbound internet access
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.subnet-app-main.id}"
  security_groups = ["${aws_security_group.sg01-jenkins.id}"]
  private_ip = "172.17.10.100"
  associate_public_ip_address = "true"
  key_name = "${aws_key_pair.auth.id}"
  
  root_block_device {
    volume_type = "gp2"
    volume_size = "80"
    delete_on_termination = "true"
  }

  tags {
    Name = "jenkins-ec2"
  }
}

# EC2 instance for hygieia
resource "aws_instance" "hygieia-ec2" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.subnet-app-main.id}"
  security_groups = ["${aws_security_group.sg01-hygieia.id}"]
  private_ip = "172.17.10.200"
  associate_public_ip_address = "true"
  key_name = "${aws_key_pair.auth.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "80"
    delete_on_termination = "true"
  }

  tags {
    Name = "hygieia-ec2"
  }
}
  
resource "local_file" "inventory-meta" {
  filename = "../Ansible/inventory"

  content = <<-EOF
#Servers for jenkins and hygieia
[jenkins]
${aws_instance.jenkins-ec2.public_dns} ansible_connection=ssh ansible_ssh_private_key_file=~/.ssh/prod-key-pair

[hygieia]
${aws_instance.hygieia-ec2.public_dns} ansible_connection=ssh ansible_ssh_private_key_file=~/.ssh/prod-key-pair
 EOF
}

resource "null_resource" "add-known-hosts" {
  provisioner "local-exec" {
    command = "ssh-keyscan -t rsa -H ${aws_instance.jenkins-ec2.public_dns} >> ~/.ssh/known_hosts"
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -t rsa -H ${aws_instance.hygieia-ec2.public_dns} >> ~/.ssh/known_hosts"
  }
}

resource "local_file" "env_aws" {
  filename = "../Ansible/aws_hosts.env"

  content = <<-EOF
#Variables to copy to aws servers
#Jenkins
JENKINS_PUBLIC_DNS="${aws_instance.jenkins-ec2.public_dns}"
JENKINS_PUBLIC_IP="${aws_instance.jenkins-ec2.public_ip}"
JENKINS_PRIVATE_IP="${aws_instance.jenkins-ec2.private_ip}"

#Hygieia
HYGIEIA_PUBLIC_DNS="${aws_instance.hygieia-ec2.public_dns}"
HYGIEIA_PUBLIC_IP="${aws_instance.hygieia-ec2.public_ip}"
HYGIEIA_PRIVATE_IP="${aws_instance.hygieia-ec2.private_ip}"
 EOF
}

