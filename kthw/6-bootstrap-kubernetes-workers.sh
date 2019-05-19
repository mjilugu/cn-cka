#!/bin/bash -e

## Links
# https://kubernetes.io/docs/concepts/architecture/
# https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/architecture.md#the-kubernetes-node

## Install worker binaries

sudo yum -y install socat conntrack ipset wget

wget --timestamping \
  https://github.com/kubernetes-incubator/cri-tools/releases/download/v1.14.0/crictl-v1.14.0-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-the-hard-way/runsc \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.0/cni-plugins-linux-amd64-v0.8.0.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.6/containerd-1.2.6.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kubelet

wget --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/runsc \
  https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kubelet

wget --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.14.0/crictl-v1.14.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.0/cni-plugins-linux-amd64-v0.8.0.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.6/containerd-1.2.6.linux-amd64.tar.gz

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

chmod +x kubectl kube-proxy kubelet runc.amd64 runsc

sudo mv runc.amd64 runc

sudo mv kubectl kube-proxy kubelet runc runsc /usr/bin

sudo tar -xvf crictl-v1.14.0-linux-amd64.tar.gz -C /usr/bin

sudo tar -xvf cni-plugins-linux-amd64-v0.8.0.tgz -C /opt/cni/bin/

sudo tar -xvf containerd-1.2.6.linux-amd64.tar.gz -C /

## Configure containerd

sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.taml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/binrunc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/binrunsc"
      runtime_root = "/run/containerd/runsc"
EOF

cat << EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

## Configure kubelet

HOSTNAME=$(hostname)
sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
sudo mv ca.pem /var/lib/kubernetes/

cat << EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF

cat << EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2 \\
  --hostname-override=${HOSTNAME} \\
  --allow-privileged=true
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

## Configure kube-proxy

sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

cat << EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

cat << EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

## Disable swap
swapoff /path/to/swap/volume
vi /etc/fstab and commentout swap line

sudo systemctl daemon-reload
sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl start containerd kubelet kube-proxy

sudo systemctl status containerd kubelet kube-proxy

# Verify on controller node

kubectl get nodes
NAME                          STATUS     ROLES    AGE   VERSION
kube-worker1.example.jilugu   NotReady   <none>   51s   v1.14.2
kube-worker2.example.jilugu   NotReady   <none>   18m   v1.14.2
