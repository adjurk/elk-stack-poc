# elk-stack-poc

Goal: Deploy a sample ELK (ElasticSearch, Logstash, Kibana) stack on AWS with as much IaC as possible on k3s.

This repo will guide you through setting up an ELK stack on AWS hosted on k3s, monitored with Prometheus & Grafana.

## Components

**Assumptions:**
- **Minimal cost possible** - avoid costly services (e.g. simple k3s cluster instead of charging for EKS), `destroy` resources when not in use and recreate thanks to IaC
- **Medium ops overhead** - implementing in k3s but with IaC where possible for a simple `apply`
- **Fast provisioning** - infra ready within 5 minutes, easy app deployment
- **Built with scaling in mind** - can scale from serving 10 to 1000 clients by scaling in/out and up/down

Here are some of the ideas for this project:

**Must-haves:**
- [x] k3s
  - [x] Filebeat as DaemonSet
  - [x] ElasticSearch
  - [x] Logstash
  	- [x] Blacklist/Transform logs
  - [x] Kibana
  	- [x] Dashboards (template must be in repo)
  - [x] Grafana
  	- [x] ELK imported/in repo
  - [x] Prometheus
    - [x] Node Exporter
    - [x] ELK Exporter
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
- [ ] AWS Pricing Calculator estimate
- [ ] Terraform remote state

## Prerequisites

- An AWS account with IAM permissions capable of provisioning resources defined in the infra directory
- Latest version of the Terraform CLI for provisioning the infrastructure

## Running

Deploying this demo boils down to:
1. Deploying base AWS resources
2. Installing [k3s](https://k3s.io) (a lightweight Kubernetes distro)
3. Deploying the ELK stack with ECK (Elastic Cloud for Kubernetes)
4. Deploying additional monitoring with Prometheus and Grafana

### Deploy base AWS resources

First step is to deploy the neccessary infrastructure:
- A VPC (and its related resources such as subnets, route tables, etc.)
- An EC2 Security Group (with only a single allowed inbound IP address)
- An EC2 Auto Scaling Group for Kubernetes nodes

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

### Install k3s Server & Agent(s)

Choose one node you'd like to become a control plane node and install k3s server:

```bash
# Install prerequisites for k3s-selinux policy & some tools
dnf install -y container-selinux \
    && dnf install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.5.stable.1/k3s-selinux-1.5-1.el8.noarch.rpm \
    && dnf install -y htop git

# Install k3s (control plane node)
curl -sfL https://get.k3s.io | sh -

# View the node token for joining agent nodes
cat /var/lib/rancher/k3s/server/node-token
```

Now you can install k3s on 1+ agent nodes and join the cluster:

```bash
# Install prerequisites for k3s-selinux policy & some tools
dnf install -y container-selinux \
    && dnf install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.5.stable.1/k3s-selinux-1.5-1.el8.noarch.rpm \
    && dnf install -y htop git

# Replace x.x.x.x with the private IP address of the server node
# Replace K3S_TOKEN value with the node token
curl -sfL https://get.k3s.io | K3S_URL=https://x.x.x.x:6443 K3S_TOKEN=<TOKEN_HERE> sh -
```

You can confirm the nodes are ready for deploying the ELK stack by checking their status:

```bash
$ kubectl get node
NAME                                          STATUS   ROLES                  AGE    VERSION
ip-10-0-0-60.eu-central-1.compute.internal    Ready    <none>                 2d6h   v1.30.3+k3s1
ip-10-0-1-126.eu-central-1.compute.internal   Ready    control-plane,master   2d6h   v1.30.3+k3s1
```

**Note:** As of 2024-08-07, there's a [coredns issue with default k3s installation](https://github.com/coredns/coredns/issues/3600) which results in constant warnings. There's no significant impact on the functionality of CoreDNS, but you can mitigate the warnings by applying a custom ConfigMap:

```bash
kubectl apply -f infra/kubernetes/coredns-cm.yaml
kubectl rollout restart deployment/coredns -n kube-system
```

### Deploy the ELK stack with ECK Cloud on Kubernetes

> Based on: [Elastic Docs - Elastic Cloud on Kubernetes - Quickstart](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html)

[Elastic Cloud on Kubernetes](https://www.elastic.co/elastic-cloud-kubernetes) allows for easy provisioning of the ELK stack with ECK CRDs and the ECK Operator maintaining desired state.

```bash
# Install ECK CRDs and ECK Operator
kubectl create -f https://download.elastic.co/downloads/eck/2.13.0/crds.yaml \
    && kubectl apply -f https://download.elastic.co/downloads/eck/2.13.0/operator.yaml

# Install Elastic Stack Helm Chart
# https://www.elastic.co/guide/en/cloud-on-k8s/2.13/k8s-stack-helm-chart.html
helm repo add elastic https://helm.elastic.co
helm repo update

## Install an eck-managed Elasticsearch, Kibana, Beats and Logstash using custom values.
## https://www.elastic.co/guide/en/cloud-on-k8s/2.13/k8s-stack-helm-chart.html#k8s-install-logstash-elasticsearch-kibana-helm
cd infra/helm
helm install eck-stack-with-logstash elastic/eck-stack \
    --values eck-values.yaml --version 0.11.0 -n elastic-stack --create-namespace
```

After installing ELK, you can use a port forward as [a workaround](#wishlist) for accessing Kibana:

```bash
screen -dmS port-fw-kibana kubectl port-forward svc/eck-stack-with-logstash-eck-kibana-kb-http --address 0.0.0.0 3000:80 -n elastic-stack
```

It should now be accessible via port `:5601` (mind the Security Group rule).

You can also deploy the `ajurkiewicz/sleeper` image to ingest sample logs with Filebeat into Logstash and ElasticSearch:

```bash
cd src
kubectl apply -f sleeper-deployment.yaml
```

There's a sample dashboard available in the `infra/kibana` directory. Use Kibana's `Stack Management > Saved Objects > Import` to import the `.ndjson` file.

### Deploy the Prometheus & Grafana Monitoring Stack

> Based on: [Grafana Docs - Install Grafana using Helm](https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/#install-grafana-using-helm)

- [Prometheus](http://prometheus.io) is responsible for serving metrics and setting up scrape targets. 
- [Grafana](https://grafana.com/docs/grafana/latest/fundamentals/) uses the Prometheus data source to visualize metrics as dashboards and could also be used to set up alerting based on set thresholds. 
- The [elasticsearch-exporter](https://github.com/prometheus-community/elasticsearch_exporter) enables scraping the ES cluster for key metrics.

```bash
# Prometheus

## Install Prometheus Helm Chart with custom values in a new 'monitoring' namespace
cd infra/helm
helm install prometheus prometheus-community/prometheus --values prometheus-values.yaml --version 25.25.0 --namespace monitoring --create-namespace

# Grafana

## Install Grafana with default values
## WARNING: default Grafana values result in loss of data when a Pod goes down
helm install grafana grafana/grafana --version 8.4.1 --namespace monitoring

## Get 'admin' user password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

After installing Grafana, you can use a port forward as [a workaround](#wishlist) for accessing the service:

```bash
screen -dmS port-fw-grafana kubectl port-forward svc/grafana --address 0.0.0.0 3000:80 -n monitoring
```

Grafana should now be accessible via port `:3000` (mind the Security Group rule).

Before installing the elasticsearch-exporter, make sure to provide `user` and `pass` for Elasticsearch in the `infra/helm/elasticsearch-exporter-values.yaml` Helm values file.

```bash
# elasticsearch-exporter

## Install elasticsearch-exporter with custom values
helm install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter --version 6.2.0 --namespace elastic-stack --values elasticsearch-exporter-values.yaml
```

## Wishlist

This solution is far from perfect. Here's a couple of things I'd love to add here someday:

- [ ] [AWS Cloud Controller Manager](https://cloud-provider-aws.sigs.k8s.io/#aws-cloud-controller-manager) – to replace k3s' ServiceLB and provision ELB for a production-ready external cluster access via external domains
- [ ] Persistent storage (like EBS) for ElasticSearch, Prometheus and Grafana
- [ ] 100% IaC - ELK PoC deploys as code and is configured with no human intervention
  - [ ] k3s installation with Ansible
  - [ ] Kustomize for deploying Helm charts