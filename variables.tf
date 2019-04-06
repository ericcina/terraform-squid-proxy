variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-1"
}

variable "amis" {
  type = "map"
  default = {
    "us-east-2" = "ami-0b500ef59d8335eee"
    "us-east-1" = "ami-011b3ccf1bd6db744"
    "ca-central-1" = "ami-49f0762d"
  }
}

variable "user_agent" {
  type = "string"
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}

