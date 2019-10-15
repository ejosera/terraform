provider "aws" {
	region = "eu-west-3"
}

// Get all vpc data from my default aws account
data "aws_vpc" "default" {
	default = true
}


// Display all vpc data from my default aws account
output "vpc_default_vpc" {
	value = data.aws_vpc.default
}


// Get vpc id from my default aws account
data "aws_subnet_ids" "default" {
        vpc_id = data.aws_vpc.default.id
}



output "vpc_default_id" {
	value = data.aws_vpc.default.id
}




output "vpc_default_id_subnets_ids" {
	value = data.aws_subnet_ids.default.ids
}
