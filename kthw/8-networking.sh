#!/bin/bash

##
#  https://kubernetes.io/docs/concepts/cluster-administration/networking/
#  https://github.com/weaveworks/weave

# Enable IP forwarding on both worker nodes

sudo sysctl net.ipv4.conf.all.forwarding=1
echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf

# Install Weave Net
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.200.0.0/16"

# Verify that weave net pods are up and running
kubectl get pods -n kube-system

NAME              READY     STATUS    RESTARTS   AGE
weave-net-m69xq   2/2       Running   0          11s
weave-net-vmb2n   2/2       Running   0          11s

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

NAME      ENDPOINTS                       AGE
nginx     10.200.0.2:80,10.200.128.1:80   50m

# Make sure the busybox pod can connect to nginx pod on both of those IP
# addresses
kubectl exec $POD_NAME -- curl 10.200.0.2:80
kubectl exec $POD_NAME -- curl 10.200.128.1:80

# Verify that we can connect to the services

kubectl get svc

NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.32.0.1    <none>        443/TCP   1h
nginx        ClusterIP   10.32.0.54   <none>        80/TCP    53m

# Make sure we can access services from the busybox pod

kubectl exec $POD_NAME -- curl 10.32.0.54

# Cleanup

kubectl delete deployment busybox
kubectl delete deployment nginx
kubectl delete svc nginx
