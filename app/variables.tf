variable "secret_path" {
  type    = string
  default = "<paste your secret path>"
}

variable "region" {
  type    = string
  default = "<paste your required region>"
}

variable "author_name" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ebs_avail_zone" {
  type = string
}

variable "ebs_size_gio" {
  type = string
}

variable "user_ssh" {
  type = string
}


variable "ubuntu_owner_number" {
  type = string
}
