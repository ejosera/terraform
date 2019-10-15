provider "aws" {
	region = "eu-west-3"
}

resource "aws_instance" "example" {
	ami = "ami-087855b6c8b59a9e4"
	instance_type = "t2.micro"

	tags = {
		Name = "terraform-example"
	}
}
