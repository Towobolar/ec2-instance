provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    terraform = "true"
    Name      = "my vpc"
  }
}

resource "aws_subnet" "public_sn" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "Public subnet"
  }
}

resource "aws_key_pair" "server-demo-key" {
  key_name   = "demo-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDuNDjqNLmFDfpAfLyk0xJI/mnsQJY7CBxcAqMOHnEUkRjdVtwDCGDadnG77iZjI0sNpVXqkZacSaxx684xGdy0tWihuixP81Kn+Zsgdwi+Mx4WjPfgT2s27lba2kZhJC0pEr5hzHEJWNwX1aOvQjGzIGr+898y6gwp/DK3cggFEQ/jNBCS76NYUFODQGpR4Wiw9cOo1B1TiGe0UW3H183+h/q1Fv3yGvFm6J0iQC83soT5hcskmuoDbstJF/y5jd7ghcQB+v67C3IWuC9oKnq+mte0oRg7+G7NnGsv1S3yBQobs8AuazOTPUmmQ/q/ThSClqwPUTd3ajfAd2sqz73+04ZDO+oZJsdYUUTl+rPzH3Qsn645iD+NJhK+G9Y8Kq6NWs2x+C2ikIPof8QIL/GfOfAk4TNi5DwCNTnhEJthPug6Zw7MhsySNjR5B5lin2Pa9iAmKLQ5XTNDvLs+gNqeEVWoBoYvM78CEh4A7+Q2Q224DvMeKrpgiVqUdI02Ht0= abbey@TOWOBOLA"
}

resource "aws_instance" "test_server" {
  ami                         = "ami-09885f3ec1667cbfc"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_sn.id
  vpc_security_group_ids      = [aws_security_group.testserver-sg.id]
  key_name                    = aws_key_pair.server-demo-key.id
  associate_public_ip_address = true

  tags = {
    Name = "test server ec2"
  }
}

resource "aws_security_group" "testserver-sg" {
  name        = "test-sg"
  description = "allow inbound ssh and https traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet gw"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "internet public route"
  }
}

resource "aws_route_table_association" "public-association-1" {
  subnet_id      = aws_subnet.public_sn.id
  route_table_id = aws_route_table.public-rt.id
}