data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.k3s.name
  user_data              = file("${path.module}/scripts/k3s-setup.sh")

  metadata_options { http_tokens = "required" } # IMDSv2 only

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project}-k3s" }
}
