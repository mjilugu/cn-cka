#/bin/bash

## Link
#   https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md

## Install cfssl
wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-386 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-386
chmod +x cfssl_linux-386 cfssljson_linux-386
sudo mv cfssl_linux-386 /usr/local/bin/cfssl
sudo mv cfssljson_linux-386 /usr/local/bin/cfssljson
cfssl version

## Install kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.14.2/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
