provider "aws" {
	region = "eu-west-3"
}



variable "server_port" {
	description = "The port the web server is listening"
	type = number
	default = 8080
}


// Prereq to create an Auto Scaling Group
// First create launch configuration to configure each EC2 on the AutoScaling Group
// Second create security group for EC2

// How to configure each EC2 on AutoScalingGroup
resource "aws_launch_configuration" "example" {
	image_id = "ami-087855b6c8b59a9e4"
	instance_type = "t2.micro"
	security_groups = [aws_security_group.instance.id]

	user_data = <<-EOF
		#!/bin/bash
		echo "Hello, World" > index.html
		nohup busybox httpd -f -p ${var.server_port} &
		EOF

	lifecycle {
		create_before_destroy = true
	}
}



// Ingress/Egress traffic for EC2
resource "aws_security_group" "instance" {
	name = "terraform-example-instance"

	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}



// Create the Auto Scaling Group
// AutoScalingGroup
resource "aws_autoscaling_group" "example" {
        launch_configuration =  aws_launch_configuration.example.name
        vpc_zone_identifier =   data.aws_subnet_ids.default.ids
        target_group_arns = [aws_lb_target_group.asg.arn]
        health_check_type = "ELB"
        min_size = 2
        max_size = 10

        tag {
                key = "Name"
                value = "terraform-asg-example"
                propagate_at_launch = true
        }
}



// Get all info of the default VPC in my aws account
data "aws_vpc" "default" {
        default = true
}



// Get id of my default vpc in my aws account 
data "aws_subnet_ids" "default" {
        vpc_id = data.aws_vpc.default.id
}



//
// All good but better if we have a Load Balancer
// My LB needs a listener
// And a security group
// and a target group
// and finall listener groups
resource "aws_lb" "example" {
        name = "terraform-asg-example"
        load_balancer_type = "application"
        subnets = data.aws_subnet_ids.default.ids
        security_groups = [aws_security_group.alb.id]
}

// LB listener	 
resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.example.arn
	port = 80
	protocol = "HTTP"
	# By default, return a simple 404 page
	default_action {
		type = "fixed-response"
		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
		}
	}
}

resource "aws_security_group" "alb" {
	name = "terraform-example-alb"
	# Allow inbound HTTP requests
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	# Allow all outbound requests
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}


resource "aws_lb_target_group" "asg" {
	name = "terraform-asg-example"
	port = var.server_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id
	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 3
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
}


resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100
	condition {
		field = "path-pattern"
		values = ["*"]
	}
	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.asg.arn
	}
}

output "alb_dns_name" {
	value = aws_lb.example.dns_name
	description = "The domain name of the load balancer"
}
