variable "access_key" {
 description = <<DESCRIPTION
 Access key of your AWS user to 
 connect in your AWS account.
DESCRIPTION
}
variable "access_secret_key" { 
 description = <<DESCRIPTION
 Secret key of your AWS user to 
 connect in your AWS account.
DESCRIPTION
} 
variable "region" {
 description = <<DESCRIPTION
 Region in AWS Global Infrastructure.
 In this region will be created your 
 entire infrastructure.
 Example: us-east-1
DESCRIPTION
}
variable "key_name" { 
 description = <<DESCRIPTION
 Name of your private ssh key to
 access your EC2 instances.
DESCRIPTION
}
variable "public_key_path" {
 description = <<DESCRIPTION
 Path to the SSH public key.
 Ensure this keypair is added
 to your local SSH agent so provisioners
 can connect.
Example: ~/.ssh/my_key.pub
DESCRIPTION
}

variable "azs" {
    type = "map"
    default = {
	"ap-northeast-1" = "ap-northeast-1a"
	"ap-northeast-2" = "ap-northeast-2a"
	"ap-south-1" 	 = "ap-south-1a"
	"ap-southeast-1" = "ap-southeast-1a"
	"ap-southeast-2" = "ap-southeast-2a"
	"ca-central-1"	 = "ca-central-1a"
	"eu-central-1"	 = "eu-central-1a"
	"eu-west-1"      = "eu-west-1a"
	"eu-west-2"      = "eu-west-2a"
	"eu-west-3"      = "eu-west-3a"
	"sa-east-1"      = "sa-east-1a"
	"us-west-1"      = "us-west-1b"
	"us-west-2"      = "us-west-2a"
	"us-east-1"      = "us-east-1a"
	"us-east-2"      = "us-east-2a"
    }
}

# Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type
variable "images" {
    type    = "map"
    default = {
	"ap-northeast-1" = "ami-92df37ed"
	"ap-northeast-2" = "ami-c10fa6af"
	"ap-south-1" 	 = "ami-76d6f519"
	"ap-southeast-1" = "ami-de90a5a2"
	"ap-southeast-2" = "ami-423bec20"
	"ca-central-1"	 = "ami-338a0a57"
	"eu-central-1"	 = "ami-9a91b371"
	"eu-west-1"      = "ami-ca0135b3"
	"eu-west-2"      = "ami-a36f8dc4"
	"eu-west-3"      = "ami-969c2deb"
	"sa-east-1"      = "ami-3885d854"
	"us-west-1"      = "ami-25110f45"
	"us-west-2"      = "ami-e251209a"
	"us-east-1"      = "ami-14c5486b"
	"us-east-2"      = "ami-922914f7"
	}
}
