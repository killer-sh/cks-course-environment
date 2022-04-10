#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm

set -e

KUBE_VERSION=1.23.4
. /etc/os-release


### add repos
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF


### update repos
sudo apt-get update


### setup terminal
sudo apt-get install -y bash-completion binutils
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'set number' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc


### disable linux swap and remove any existing swap partitions
sudo swapoff -a
sudo sed -i -e '/[[:space:]]\+swap[[:space:]]\+/ s/^\(.*\)$/#\1/g' /etc/fstab


### remove packages
sudo kubeadm reset -f || true
sudo crictl rm --force $(sudo crictl ps -a -q) || true
sudo apt-mark unhold kubelet kubeadm kubectl kubernetes-cni || true
sudo apt-get purge -y kubelet kubeadm kubectl kubernetes-cni || true
sudo apt-get remove -y docker.io containerd || true
sudo apt-get autoremove -y
sudo systemctl daemon-reload


### cleanup cni leftovers
sudo bash -c 'rm -rf /opt/cni/bin/* || true'
sudo bash -c 'rm -rf /etc/cni/net.d/* || true'


### install packages
sudo apt-get install -y docker.io containerd kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni
sudo apt-mark hold kubelet kubeadm kubectl kubernetes-cni


### containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo mkdir -p /etc/containerd


### containerd config
cat <<EOF | sudo tee /etc/containerd/config.toml
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF


### crictl uses containerd as default
{
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
}


### kubelet should use containerd
{
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF
}


### install podman
sudo apt-get install software-properties-common -y
sudo apt-get -qq -y install podman containers-common
cat <<EOF | sudo tee /etc/containers/registries.conf
[registries.search]
registries = ['docker.io']
EOF


### start services
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl enable kubelet
sudo systemctl start kubelet


### init k8s
rm ~/.kube/config || true
sudo kubeadm init --kubernetes-version=${KUBE_VERSION} --ignore-preflight-errors=NumCPU --skip-token-print

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/$USER/.kube/config
sudo chown $USER:$USER /home/$USER/.kube/config
sudo chmod 600 /home/$USER/.kube/config

# workaround because https://github.com/weaveworks/weave/issues/3927
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
curl -L https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n') -o weave.yaml
sed -i 's/ghcr.io\/weaveworks\/launcher/docker.io\/weaveworks/g' weave.yaml
kubectl -f weave.yaml apply
rm weave.yaml

sudo apt-mark unhold kubelet kubeadm kubectl kubernetes-cni


# etcdctl
ETCDCTL_VERSION=v3.5.1
ETCDCTL_VERSION_FULL=etcd-${ETCDCTL_VERSION}-linux-amd64
wget https://github.com/etcd-io/etcd/releases/download/${ETCDCTL_VERSION}/${ETCDCTL_VERSION_FULL}.tar.gz
tar xzf ${ETCDCTL_VERSION_FULL}.tar.gz
sudo mv ${ETCDCTL_VERSION_FULL}/etcdctl /usr/local/bin/
sudo chown root:root /usr/local/bin/etcdctl
rm -rf ${ETCDCTL_VERSION_FULL} ${ETCDCTL_VERSION_FULL}.tar.gz


# k9s
K9S_VERSION=v0.25.18
wget https://github.com/derailed/k9s/releases/download/$K9S_VERSION/k9s_Linux_x86_64.tar.gz
tar xzf k9s_Linux_x86_64.tar.gz k9s
sudo mv k9s /usr/local/bin/
sudo chown root:root /usr/local/bin/k9s
rm k9s_Linux_x86_64.tar.gz


echo
echo "### COMMAND TO ADD A WORKER NODE ###"
kubeadm token create --print-join-command --ttl 0
