resource "aws_autoscaling_group" "k3s" {
  vpc_zone_identifier = tolist(aws_subnet.public_asg[*].id)
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2

  launch_template {
    id      = aws_launch_template.k3s.id
    version = "$Latest"
  }
}