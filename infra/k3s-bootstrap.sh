#!/bin/bash

# Install prerequisites for k3s-selinux policy
dnf install -y container-selinux \
    && dnf install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.5.stable.1/k3s-selinux-1.5-1.el8.noarch.rpm \
    && dnf install -y htop git

# TODO: Install k3s server/agent (based on instance tags?)

# Install k3s (control plane node)
# curl -sfL https://get.k3s.io | sh -
# cat /var/lib/rancher/k3s/server/node-token

# Install k3s (agent node)
# curl -sfL https://get.k3s.io | K3S_URL=https://10.0.1.126:6443 K3S_TOKEN=K10903540a05fda7d5e9628fbe37cc3198aa3eb8d7fe25a61fe2aca172e90d4a643::server:df0918cb8855d1cad0542aa69157250a sh -

# Install k9s
dnf install -y https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.rpm

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure bashrc
echo "alias k='k3s kubectl'" >> ~/.bashrc
echo "alias k9s='k9s --kubeconfig /etc/rancher/k3s/k3s.yaml'" >> ~/.bashrc

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