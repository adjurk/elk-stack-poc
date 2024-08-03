#!/bin/bash

# Install prerequisites for k3s-selinux policy
dnf install -y container-selinux \
    && dnf install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.5.stable.1/k3s-selinux-1.5-1.el8.noarch.rpm \
    && dnf install -y htop

# TODO: Install k3s server/agent (based on instance tags?)

# Install k3s (control plane node)
# curl -sfL https://get.k3s.io | sh -
# cat /var/lib/rancher/k3s/server/node-token

# Install k3s (agent node)
# curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.12:6443 K3S_TOKEN=K105c544632b5326f421b7b94359e91aa7b2827c6dc42cc6c23c6661ad5631fced5::server:5c06a12f9a6187b6f6d2c628a3b8423d sh -

# Install k9s
dnf install -y https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.rpm

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure bashrc
alias k='k3s kubectl'
alias k9s='k9s --kubeconfig /etc/rancher/k3s/k3s.yaml'

# TODO: Use manifests from a static location instead of hosted

# Install ECK CRDs and ECK Operator
kubectl create -f https://download.elastic.co/downloads/eck/2.13.0/crds.yaml \
    && kubectl apply -f https://download.elastic.co/downloads/eck/2.13.0/operator.yaml

# Install Elastic Stack Helm Chart
# https://www.elastic.co/guide/en/cloud-on-k8s/2.13/k8s-stack-helm-chart.html
helm repo add elastic https://helm.elastic.co
helm repo update

## Install an eck-managed Elasticsearch, Kibana, Beats and Logstash using custom values.
## https://www.elastic.co/guide/en/cloud-on-k8s/2.13/k8s-stack-helm-chart.html#k8s-install-logstash-elasticsearch-kibana-helm
helm install eck-stack-with-logstash elastic/eck-stack \
    --values https://raw.githubusercontent.com/elastic/cloud-on-k8s/2.13/deploy/eck-stack/examples/logstash/basic-eck.yaml -n elastic-stack --create-namespace