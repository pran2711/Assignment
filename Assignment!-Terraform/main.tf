provider "aws" {
  region     = "ap-south-1"
  access_key = ""
  secret_key = ""
 
}

# Create a new VPC and its components
resource "aws_vpc" "assignment_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway for accessing instance from internet

resource "aws_internet_gateway" "assignment_igw" {
  vpc_id = aws_vpc.assignment_vpc.id
}

#Create Route Table with internet gateway as a route

resource "aws_route_table" "assignment" {
  vpc_id = aws_vpc.assignment_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.assignment_igw.id
  }
}

# In this Project we are creating a load balancer. For that two subnets in two different AZ are required
# Create  two subnets in 2 differennt AZs

resource "aws_subnet" "assignment_subnet1" {
  vpc_id                  = aws_vpc.assignment_vpc.id
  cidr_block              = "10.0.0.0/19"
  availability_zone       = "ap-south-1a"
}

resource "aws_subnet" "assignment_subnet2" {
  vpc_id                  = aws_vpc.assignment_vpc.id
  cidr_block              = "10.0.64.0/20"
  availability_zone       = "ap-south-1b"
}

# Associate both the subnets with route table

resource "aws_route_table_association" "a" {
  for_each       = toset([aws_subnet.assignment_subnet1.id,aws_subnet.assignment_subnet2.id])
  subnet_id      = each.value
  route_table_id = aws_route_table.assignment.id
}

# Create a security group allowing traffic only from port 80

resource "aws_security_group" "assignment_security_group" {
  vpc_id = aws_vpc.assignment_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create two EC2 instances in 2 different subnets

resource "aws_instance" "assignment_instance_1" {
  ami           = "ami-025b4b7b37b743227"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.assignment_subnet1.id
  vpc_security_group_ids = [aws_security_group.assignment_security_group.id]
  associate_public_ip_address = true
}

resource "aws_instance" "assignment_instance_2" {
  ami           = "ami-025b4b7b37b743227"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.assignment_subnet2.id
  vpc_security_group_ids = [aws_security_group.assignment_security_group.id]
  associate_public_ip_address = true
}

# Finally create a load balancer 

resource "aws_lb" "assignment_load_balancer" {
  name               = "assignment-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.assignment_subnet1.id,aws_subnet.assignment_subnet2.id]
}

# Create a Target group and attach both the instances to it.


resource "aws_lb_target_group" "assignment_target_group" {
  name     = "assignment-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.assignment_vpc.id
}

resource "aws_lb_target_group_attachment" "assignment_target_group_attachment_1" {
  target_group_arn = aws_lb_target_group.assignment_target_group.arn
  target_id        = aws_instance.assignment_instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "assignment_target_group_attachment_2" {
  target_group_arn = aws_lb_target_group.assignment_target_group.arn
  target_id        = aws_instance.assignment_instance_2.id
  port             = 80
}



# Create a listener for the load balancer

resource "aws_lb_listener" "assignment_listener" {
  load_balancer_arn = aws_lb.assignment_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.assignment_target_group.arn
    type             = "forward"
  }
}