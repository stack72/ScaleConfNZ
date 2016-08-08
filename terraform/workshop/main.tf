provider "aws" {
    region = "ap-southeast-2"
}

resource "aws_key_pair" "ssh_key" {
  key_name = "sydney-devops"
  public_key = "${file("ssh/ndc_demo.pub")}"
}

data "aws_availability_zones" "zones" {}
module "vpc" {
  source = "../modules/vpc"

  name = "test"

  cidr            = "10.5.0.0/16"
  private_subnets = ["10.5.160.0/19", "10.5.192.0/19", "10.5.224.0/19"]
  public_subnets  = ["10.5.0.0/21", "10.5.8.0/21", "10.5.16.0/21"]

  availability_zones = ["${data.aws_availability_zones.zones.names}"]
}

variable "openvpn_ami" {
    default = "ami-d37540b0"
}
module "vpn" {
    source = "../modules/vpn"

    vpc_id = "${module.vpc.vpc_id}"
    public_subnets = ["${module.vpc.public_subnets}"]
    ami = "${var.openvpn_ami}"
    key_name = "${aws_key_pair.ssh_key.key_name}"
    tag_name = "scale-conf"
}
output "vpn_setup_command" {
    value = "${format("ssh openvpnas@%s", module.vpn.vpn_ip)}"
}
output "vpn_web_console" {
  value = "${format("https://%s/", module.vpn.vpn_ip)}"
}
