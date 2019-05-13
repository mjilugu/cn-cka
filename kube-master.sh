
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.5.40

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml




##########################################################################################################
##########################################################################################################
##########################################################################################################
##########################################################################################################

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.31.20.191:6443 --token qcn65a.qer38iq4ff1xeudq \
    --discovery-token-ca-cert-hash sha256:80c4ae51a8da62485314a4142d747df0ff72a3fb8051ee6b55468d1e8525337c
