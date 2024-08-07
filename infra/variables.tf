variable "ingress_allowed_ip_cidr" {
  type = string
  description = "Home IP CIDR (e.g. '1.1.1.1/32')"
  sensitive = true
}