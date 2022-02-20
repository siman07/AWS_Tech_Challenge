data "aws_ami" "RHEL-8" {
  most_recent = true

  filter {
    name   = "name"
    values = ["rhel8-ami-hvm*"]
  }
}

resource "aws_instance" "ec2_public" {
  ami                         = data.aws_ami.RHEL-8.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.vpc.public_subnets[0]
  vpc_security_group_ids      = [var.sg_pub_id]

  tags = {
    "Name" = "${var.namespace}-EC2-PUBLIC"
  }

resource "aws_ebs_volume" "my_vol" {
  availability_zone = aws_instance.os1.availability_zone
  size              = 10
}

resource "aws_volume_attachment" "rhel_ebs" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.my_vol.id
  instance_id = aws_instance.RHEL-8.id
}

   provisioner "file" {
    source      = "./${var.key_name}.pem"
    destination = "/home/ec2-user/${var.key_name}.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }
  }

   provisioner "remote-exec" {
    inline = ["chmod 400 ~/${var.key_name}.pem"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }

  }

}

resource "aws_instance" "ec2_private" {
  ami                         = data.aws_ami.RHEL-8.id
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.vpc.private_subnets[1]
  vpc_security_group_ids      = [var.sg_priv_id]

  tags = {
    "Name" = "${var.namespace}-EC2-PRIVATE"
  }

}
