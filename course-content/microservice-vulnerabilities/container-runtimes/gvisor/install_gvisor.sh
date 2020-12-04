#!/usr/bin/env bash
# https://gvisor.dev/docs/user_guide/install

# gvisor
sudo apt-get update && \
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common


# install from web
{
  set -e
  URL=https://storage.googleapis.com/gvisor/releases/release/latest
#  URL=https://storage.googleapis.com/gvisor/releases/release/20201130.0 # try this version instead if latest doesn't work for you
  wget ${URL}/runsc ${URL}/runsc.sha512 \
    ${URL}/gvisor-containerd-shim ${URL}/gvisor-containerd-shim.sha512 \
    ${URL}/containerd-shim-runsc-v1 ${URL}/containerd-shim-runsc-v1.sha512
  sha512sum -c runsc.sha512 \
    -c gvisor-containerd-shim.sha512 \
    -c containerd-shim-runsc-v1.sha512
  rm -f *.sha512
  chmod a+rx runsc gvisor-containerd-shim containerd-shim-runsc-v1
  sudo mv runsc gvisor-containerd-shim containerd-shim-runsc-v1 /usr/local/bin
}

# containerd enable runsc
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = ["restart"]
[plugins.linux]
  shim_debug = true
[plugins.cri.containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF

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
