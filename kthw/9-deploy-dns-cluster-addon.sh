#!/bin/bash

## Links
#   https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

# might need to do coredns instead of kube-dns here
# https://kubernetes.io/docs/tasks/administer-cluster/coredns/

# installing kube-dns
kubectl create -f https://storage.googleapis.com/kubernetes-the-hard-way/kube-dns.yaml

# verify kube-dns pods start correctly
kubectl get pods -l k8s-app=kube-dns -n kube-system

NAME                        READY     STATUS    RESTARTS   AGE
kube-dns-598d7bf7d4-spbmj   3/3       Running   0          36s

# Test kube dns

kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

kubectl exec -ti $POD_NAME -- nslookup kubernetes

# Should get something like this
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local

# Cleanup test objects

kubectl delete deployment busybox

# Now quickly migrate to coredns
# https://kubernetes.io/docs/tasks/administer-cluster/coredns/

git clone git@github.com:coredns/deployment.git
cd deployment/kubernetes
sudo yum install -y jq

./deploy.sh | kubectl apply -f -
kubectl delete --namespace=kube-system deployment kube-dns

# re-run the nslookup tests above
