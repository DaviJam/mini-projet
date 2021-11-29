variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "author_name" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "user_name" {
  type = string
}

variable "public_ip" {
  type = string
}
variable "ubuntu_owner_number" {
  type = string
}
