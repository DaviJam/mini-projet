resource "aws_ebs_volume" "ebs" {
  availability_zone = var.ebs_avail_zone
  size              = var.ebs_size_gio
  tags = {
    Name = "${var.author_name}-ebs"
  }
}
