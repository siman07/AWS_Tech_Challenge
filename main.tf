module "networking" {
  source    = "./modules/networking"
  namespace = var.namespace
}

module "ssh-key" {
  source    = "./modules/ssh-key"
  namespace = var.namespace
}

module "ec2" {
  source     = "./modules/ec2"
  namespace  = var.namespace
  vpc        = module.networking.vpc
  sg_pub_id  = module.networking.sg_pub_id
  sg_priv_id = module.networking.sg_priv_id
  key_name   = module.ssh-key.key_name
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.my_app_s3_bucket
  acl    = "private"
  tags = {
    Name        = "My bucket"
    Environment = terraform.workspace
  }
}

resource "aws_lb_target_group" "apache-app" {
  name     = "apache-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpn.id
}

# Attach EC2 instances to traget group

resource "aws_lb_target_group_attachment" "apache-app" {
  count            = 1
  target_group_arn = aws_lb_target_group.apache-app.arn
  target_id        = aws_instance.web.*.id[count.index]
  port             = 80
}

# Create ALB

resource "aws_lb" "apache-app" {
  name               = "apache-app-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = true

  tags = {
    Environment = terraform.workspace
  }
}

# Configure ALB Listerner

resource "aws_lb_listener" "apache-app" {
  load_balancer_arn = aws_lb.apache-app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache-app.arn
  }
}