variable "region"        { default = "us-east-1" }
variable "project"       { default = "devsecops" }
variable "key_name"      { default = "devsecops-key" }
variable "instance_type" { default = "t3.micro" } # use t2.micro if your Free Tier page says so

variable "my_ip" {
  description = "Your public IP, e.g. 1.2.3.4/32"
  type        = string
}
