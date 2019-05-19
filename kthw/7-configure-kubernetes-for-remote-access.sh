#!/bin/bash

##
# https://kubernetes.io/docs/reference/kubectl/overview/


# Create tunnel
ssh -L 6443:localhost:6443 dcuser@nginx

# Configure local kubectl

cd ~/kthw

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://localhost:6443

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way

# Verify everything is working

kubectl get pods
kubectl get nodes
kubectl version
