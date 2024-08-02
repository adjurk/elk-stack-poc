# elk-stack-poc

Goal: Deploy a sample ELK (ElasticSearch, Logstash, Kibana) stack on AWS with as much IaC as possible on k3s.

## Components

**Assumptions:**
- **Minimal cost possible** - use AWS Free Tier, `destroy` resources when not in use and recreate thanks to IaC
- **Medium ops overhead** - implementing in k3s but with IaC where possible for a simple `apply`

**Must-haves:**
- [ ] Sample Python app writing logs to container stdout in a loop
- [ ] k3s
  - [ ] Fluent Bit as DaemonSet (instead of Logstash)
  	- [ ] Metrics enabled
  - [ ] ElasticSearch
  - [ ] Logstash
  	- [ ] Blacklist/Transform logs
  - [ ] Kibana
  	- [ ] Dashboards (template must be in repo)
  - [ ] Grafana
  	- [ ] Fluent Bit dashboard imported/in repo
  - [ ] Prometheus
	- [ ] Configured with Packer
- Terraform
  - [x] EC2 Launch Template
  - [x] Basic VPC setup
  - [x] ASG
- [ ] README - scope, design decisions

**Could-haves**:
- [ ] HLD diagram in AWS
- [ ] Python app:
	- `GET /health` API
- [x] 100% IaC
- [ ] Terraform remote state

**Nice-to-haves**:
- [ ] CI/CD to deploy infra
- [ ] Signed Git commits
- [ ] AWS Pricing Calculator estimate