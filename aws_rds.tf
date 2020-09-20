provider "aws" {
	region = "ap-south-1"
}

resource "aws_vpc" "tf_vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "mytf-vpc"
  }
}

resource "aws_subnet" "tf_subnet" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "tf_subnet2" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2"
  }
}

resource "aws_internet_gateway" "tf_gw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "my-ig"
  }
}

resource "aws_route_table" "tf_rt" {
    vpc_id = aws_vpc.tf_vpc.id

    route {
        gateway_id = aws_internet_gateway.tf_gw.id
        cidr_block = "0.0.0.0/0"
    }

    tags = {
        Name = "my_rt"
    }
}

resource "aws_route_table_association" "tf_sub_a" {
    subnet_id      = aws_subnet.tf_subnet.id
    route_table_id = aws_route_table.tf_rt.id
}

resource "aws_route_table_association" "tf_sub_b" {
    subnet_id      = aws_subnet.tf_subnet2.id
    route_table_id = aws_route_table.tf_rt.id
}

resource "aws_security_group" "tf_sg2" {
  depends_on = [ aws_vpc.tf_vpc ]
  name        = "db-sg"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql_sg"
  }
}

resource "aws_db_subnet_group" "subnetdb" {
  name       = "db-subnet"
  subnet_ids = [ aws_subnet.tf_subnet.id , aws_subnet.tf_subnet2.id ]
}

resource "aws_db_instance" "mydb" {
  
  identifier        = "mydb-tf"
  engine            = "mysql"
  engine_version    = "5.7.30"
  instance_class    = "db.t2.micro"
  allocated_storage = 10

  db_subnet_group_name    = aws_db_subnet_group.subnetdb.id

  name     = "mydb"
  username = "root"
  password = "itisme1234"
  port     = 3306

  vpc_security_group_ids = [ aws_security_group.tf_sg2.id ]

  publicly_accessible = true

  iam_database_authentication_enabled = true

  parameter_group_name = "default.mysql5.7"

  tags = {
      Name = "vibhavdb"
  }
}