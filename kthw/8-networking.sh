#!/bin/bash

##
#  https://kubernetes.io/docs/concepts/cluster-administration/networking/
#  https://github.com/weaveworks/weave

# Enable port forwarding on both worker nodes

sudo sysctl net.ipv4.conf.all.forwarding=1
echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf

# Install Weave Net
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.200.0.0/16"

# Create a Nginx deployment with 2 replicas:

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      run: nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create a service for the deployment

kubectl expose deployment/nginx

# Create test busybox pod

kubectl run busybox --image=radial/busyboxplus:curl --command -- sleep 3600
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

# Get IP addresses of nginx pods

kubectl get ep nginx

# Make sure the busybox pod can connect to nginx pod on both of those IP
# addresses
kubectl exec $POD_NAME -- curl <first nginx pod IP address>
kubectl exec $POD_NAME -- curl <second nginx pod IP address>

# Verify that we can connect to the services

kubectl get svc

# Make sure we can access services from the busybox pod

kubectl exec $POD_NAME -- curl <nginx service IP address>

# Cleanup

kubectl delete deployment busybox
kubectl delete deployment nginx
kubectl delete svc nginx
