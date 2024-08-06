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
  	- [ ] Blacklist/Transform logs
  - [x] Kibana
  	- [x] Dashboards (template must be in repo)
  - [ ] Grafana
  	- [ ] Fluent Bit dashboard imported/in repo
  - [ ] Prometheus
	- [ ] Configured with Packer
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

- 

## Running

### Deploy base AWS resources