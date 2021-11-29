module "ec2" {
  source              = "../Modules/EC2"
  author_name         = var.author_name
  instance_type       = var.instance_type
  private_key_path    = var.private_key_path
  availability_zone   = var.ebs_avail_zone
  sg_name             = module.sg.out-sg-name
  public_ip           = module.eip.out_eip_ip
  ubuntu_owner_number = var.ubuntu_owner_number
  user_name           = var.user_ssh
}

module "sg" {
  source   = "../Modules/SG"
  tag_name = var.author_name
}

module "eip" {
  source      = "../Modules/EIP"
  author_name = var.author_name
}

module "ebs" {
  source         = "../Modules/EBS"
  author_name    = var.author_name
  ebs_avail_zone = var.ebs_avail_zone
  ebs_size_gio   = var.ebs_size_gio
}

resource "aws_eip_association" "eip_association" {
  allocation_id = module.eip.out_eip_id
  instance_id   = module.ec2.out-ec2-id
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdf"
  instance_id = module.ec2.out-ec2-id
  volume_id   = module.ebs.out_ebs_id
}
