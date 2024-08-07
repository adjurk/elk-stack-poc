# elk-stack-poc

Goal: Deploy a sample ELK (ElasticSearch, Logstash, Kibana) stack on AWS with as much IaC as possible on k3s.

## Components

**Assumptions:**
- **Minimal cost possible** - avoid costly services (e.g. simple k3s cluster instead of charging for EKS), `destroy` resources when not in use and recreate thanks to IaC
- **Medium ops overhead** - implementing in k3s but with IaC where possible for a simple `apply`
- **Fast provisioning** - ready within 5 minutes
- **Built for scale** - can go from serving 10 to 1000 clients with horizontal scaling

**Must-haves:**
- [ ] k3s
  - [x] Filebeat as DaemonSet
  	- [ ] Metrics enabled
  - [x] ElasticSearch
  - [x] Logstash
  	- [x] Blacklist/Transform logs
  - [x] Kibana
  	- [x] Dashboards (template must be in repo)
  - [ ] Grafana
  	- [ ] ELK imported/in repo
  - [ ] Prometheus
    - [ ] Node Exporter
    - [ ] ELK Exporter
- Terraform
  - [x] EC2 Launch Template
  - [x] Basic VPC setup
  - [x] ASG
- [x] README - scope, design decisions

**Could-haves**:
- [ ] HLD diagram in AWS
- [x] Python app:
	- Sample Python app writing JSON logs to container stdout in a loop
	- `GET /health` API
- [ ] 100% IaC
  - [ ] Automated cluster setup
- [ ] Proper Ingress (instead of port forward)
- [ ] Configure domains

**Nice-to-haves**:
- [ ] CI/CD to deploy infra
- [x] Signed Git commits
- [ ] AWS Pricing Calculator estimate
- [ ] Terraform remote state

## Prerequisites

- An AWS account with IAM permissions capable of provisioning resources defined in the infra directory

## Running

### Deploy base AWS resources

```bash
cd infra
# Initialize the backend & provider
terraform init
# Add your IP to tfvars which will be applied to an Ingress Rules for the EC2 Security Group
echo "ingress_allowed_ip_cidr = \""$(curl -s ip.me)"/32\"" > secret.tfvars
# Run a plan and check what resources would be provisioned
terraform plan -var-file='secret.tfvars'
# Apply the infrastructure and wait until it's complete (should take ~2-5 min)
terraform apply -var-file='secret.tfvars'
```

### Deploy the ELK stack with ECK Cloud on Kubernetes

WIP