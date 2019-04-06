terraform {
  backend "s3" {
    bucket = "terraform-evseestems"
    key    = "terraform.tfstate"
    region = "us-east-2"
    //dynamodb_table = "terraform-consistency-check"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "terraform-evseestems"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_instance" "web-proxy" {
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"
  key_name = "PersonalGmailAWSKey"
  security_groups = ["${aws_security_group.web-proxies.name}"]
  tags = {
    "Name" = "web-proxy"
  }

  user_data = <<YAML
#!/bin/bash
yum update -y
yum install squid -y
# Modify squid config
sed -i 's/src 172.*$/src ${chomp(data.http.myip.body)}\/32/' /etc/squid/squid.conf
sed -i '/acl localnet src 192/d' /etc/squid/squid.conf
sed -i '/acl localnet src f/d' /etc/squid/squid.conf
echo -e "\n# Additions" >> /etc/squid/squid.conf
echo "request_header_access User-Agent deny all" >> /etc/squid/squid.conf
echo "request_header_replace User-Agent ${var.user_agent}" >> /etc/squid/squid.conf
echo "request_header_access Cache-Control deny all" >> /etc/squid/squid.conf
echo "request_header_access Via deny all" >> /etc/squid/squid.conf
echo "request_header_access X-Forwarded-For deny all" >> /etc/squid/squid.conf
# Enable and start squid
systemctl enable squid
systemctl start squid
YAML
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.web-proxy.id}"
}

resource "aws_security_group" "web-proxies" {
  name = "web-proxies"
}

resource "aws_security_group_rule" "allow-ssh-in" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["${chomp(data.http.myip.body)}/32"]

  security_group_id = "${aws_security_group.web-proxies.id}"
}

resource "aws_security_group_rule" "allow-https-for-userdata" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.web-proxies.id}"
}

resource "aws_security_group_rule" "allow-proxy-clients-in" {
  type            = "ingress"
  from_port       = 3128
  to_port         = 3128
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.web-proxies.id}"
}

resource "aws_security_group_rule" "allow-http-out" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.web-proxies.id}"
}

resource "aws_security_group_rule" "allow-https-out" {
  type            = "egress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.web-proxies.id}"
}
