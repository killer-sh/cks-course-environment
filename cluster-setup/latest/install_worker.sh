#!/bin/sh

# Source: https://kubernetes.io/docs/reference/setup-tools/kubeadm

KUBE_VERSION=1.37.1

set -e


### verify Ubuntu version
source /etc/lsb-release
if [ "$DISTRIB_RELEASE" != "24.04" ]; then
    echo "################################# "
    echo "############ WARNING ############ "
    echo "################################# "
    echo
    echo "This script only works on Ubuntu 24.04!"
    echo "You're using: ${DISTRIB_DESCRIPTION}"
    echo "Better ABORT with Ctrl+C. Or press any key to continue the install"
    read
fi


### get platform
PLATFORM=`uname -p`

if [ "${PLATFORM}" == "aarch64" ]; then
  PLATFORM="arm64"
elif [ "${PLATFORM}" == "x86_64" ]; then
  PLATFORM="amd64"
else
  echo "${PLATFORM} has to be either amd64 or arm64/aarch64. Check containerd supported binaries page"
  echo "https://github.com/containerd/containerd/blob/main/docs/getting-started.md#option-1-from-the-official-binaries"
  exit 1
fi


### install containerd >= 2.0 from official binaries if needed
CONTAINERD_VERSION=2.4.2
INSTALL_CONTAINERD=yes
if command -v containerd >/dev/null 2>&1; then
  INSTALLED_CONTAINERD=$(containerd --version | awk '{print $3}' | sed 's/^v//')
  if [ "$(echo "${INSTALLED_CONTAINERD}" | cut -d. -f1)" -ge 2 ]; then
    echo "containerd ${INSTALLED_CONTAINERD} already installed"
    INSTALL_CONTAINERD=no
  else
    echo "containerd ${INSTALLED_CONTAINERD} is too old, replacing with ${CONTAINERD_VERSION}"
    apt-get remove -y containerd containerd.io || true
  fi
fi
if [ "${INSTALL_CONTAINERD}" = "yes" ]; then
  curl -fsSL -o /tmp/containerd.tar.gz "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${PLATFORM}.tar.gz"
  tar Cxzf /usr/local /tmp/containerd.tar.gz
  rm /tmp/containerd.tar.gz
  curl -fsSL -o /etc/systemd/system/containerd.service "https://raw.githubusercontent.com/containerd/containerd/v${CONTAINERD_VERSION}/containerd.service"
  systemctl daemon-reload
fi


### set hostname to the first part before the first dot
short_hostname=$(hostname | cut -d. -f1)
hostnamectl set-hostname "$short_hostname"


### setup terminal
apt-get --allow-unauthenticated update
apt-get --allow-unauthenticated install -y bash-completion binutils
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc


### disable linux swap and remove any existing swap partitions
swapoff -a
sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab


### remove packages
kubeadm reset -f || true
crictl rm --force $(crictl ps -a -q) || true
apt-mark unhold kubelet kubeadm kubectl kubernetes-cni || true
apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni cri-tools || true
apt-get autoremove -y
systemctl daemon-reload



### install podman
. /etc/os-release
sudo apt-get update
sudo apt-get -y install podman
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
prefix = "docker.io"
location = "mirror.gcr.io"

[[registry.mirror]]
prefix = "docker.io"
location = "registry-1.docker.io"
EOF



### k8s
apt-get update
apt-get install -y apt-transport-https ca-certificates
mkdir -p /etc/apt/keyrings
rm /etc/apt/keyrings/kubernetes-1-37-apt-keyring.gpg || true
rm /etc/apt/keyrings/kubernetes-1-36-apt-keyring.gpg || true
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-37-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-36-apt-keyring.gpg
echo > /etc/apt/sources.list.d/kubernetes.list
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-1-37-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-1-36-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get --allow-unauthenticated update
apt-get --allow-unauthenticated install -y kubelet=${KUBE_VERSION}-1.1 kubeadm=${KUBE_VERSION}-1.1 kubectl=${KUBE_VERSION}-1.1 kubernetes-cni cri-tools runc



### configure containerd
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


### containerd registry hosts.toml
sudo mkdir -p /etc/containerd/certs.d/docker.io
cat > /etc/containerd/certs.d/docker.io/hosts.toml <<EOF
server = "https://docker.io"

[host."https://mirror.gcr.io"]
  capabilities = ["pull", "resolve"]

[host."https://registry-1.docker.io"]
  capabilities = ["pull", "resolve"]
EOF

sudo mkdir -p "/etc/containerd/certs.d/registry.killer.sh:5000"
cat > "/etc/containerd/certs.d/registry.killer.sh:5000/hosts.toml" <<EOF
server = "https://registry.killer.sh:5000"

[host."https://registry.killer.sh:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF


### containerd config version 3 (requires containerd>=2.0)
cat > /etc/containerd/config.toml <<EOF
version = 3

[plugins."io.containerd.cri.v1.images".registry]
  config_path = "/etc/containerd/certs.d"

[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.runc.options]
  SystemdCgroup = true
EOF



### crictl uses containerd as default
{
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
}


### disable appamor
aa-teardown > /dev/null 2>&1 || true
service apparmor stop > /dev/null 2>&1 || true
systemctl disable appamor > /dev/null 2>&1 || true
apt-get remove -y apparmor > /dev/null 2>&1 || true


### start services
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd
systemctl enable kubelet && systemctl start kubelet


### init k8s
kubeadm reset -f
systemctl daemon-reload
service kubelet start


echo
echo "EXECUTE ON MASTER: kubeadm token create --print-join-command --ttl 0"
echo "THEN RUN THE OUTPUT AS COMMAND HERE TO ADD AS WORKER"
echo
