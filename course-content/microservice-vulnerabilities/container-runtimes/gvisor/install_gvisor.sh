#!/usr/bin/env bash
# https://gvisor.dev/docs/user_guide/install/


# gvisor
sudo apt-get update && \
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://gvisor.dev/archive.key | sudo apt-key add -

sudo add-apt-repository "deb https://storage.googleapis.com/gvisor/releases release main"
sudo apt-get update && sudo apt-get install -y runsc



# containerd enable runsc
# WORKING
mkdir -p /etc/containerd
cat >> /etc/containerd/config.toml <<EOF
disabled_plugins = ["restart"]
[plugins.linux]
  shim = "/usr/local/bin/gvisor-containerd-shim"
  shim_debug = true
[plugins.cri.containerd.runtimes.runsc]
  runtime_type = "io.containerd.runtime.v1.linux"
  runtime_engine = "/usr/bin/runsc"
  runtime_root = "/run/containerd/runsc"
EOF

# containerd runsc options
{
cat <<EOF | sudo tee /etc/containerd/runsc.toml
[runsc_config]
debug = true
debug-log = /var/log/%ID%/gvisor.log
EOF
}


# containerd runsc shim
{
wget https://github.com/google/gvisor/archive/release-20200622.1.tar.gz
tar xzf release-20200622.1.tar.gz
bash ./gvisor-release-20200622.1/tools/installers/shim.sh
#cp /usr/bin/containerd-shim /usr/local/bin/containerd-shim # ?
}


# crictl should use containerd as default
{
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
}

systemctl restart containerd

# kubelet should use containerd
{
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF
}
systemctl daemon-reload
systemctl restart kubelet
