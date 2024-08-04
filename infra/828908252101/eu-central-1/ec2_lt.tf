resource "aws_key_pair" "admin" {
  key_name = "admin"
  # TODO: Generate a public key on-the-fly
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBOvyU9FzqovrUUq4oCapmrayYJBIkPeEahFuP+LkPcv elk-stack-poc"
}

resource "aws_launch_template" "k3s" {
  name = "ec2-lt-k3s"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
    }
  }

  image_id = "ami-013efd7d9f40467af" # Amazon Linux 2023

  # TODO: Uncomment when EC2 instances are stable
  #   instance_initiated_shutdown_behavior = "terminate"

  instance_type = "r6a.large"

  key_name = aws_key_pair.admin.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.public_asg.id]
  }

  # TODO: Provide script to create/join the cluster
  #   user_data = filebase64("${path.module}/example.sh")
}