#!/usr/bin/env bash
# IF THIS FAILS then you can try to change the URL= further down from specific to the latest release
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
(
  set -e
  ARCH=$(uname -m)
  URL=https://storage.googleapis.com/gvisor/releases/release/20210806/${ARCH}
  # URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH} # TRY THIS URL INSTEAD IF THE SCRIPT DOESNT WORK FOR YOU
  wget ${URL}/runsc ${URL}/runsc.sha512 \
    ${URL}/containerd-shim-runsc-v1 ${URL}/containerd-shim-runsc-v1.sha512
  sha512sum -c runsc.sha512 \
    -c containerd-shim-runsc-v1.sha512
  rm -f *.sha512
  chmod a+rx runsc containerd-shim-runsc-v1
  sudo mv runsc containerd-shim-runsc-v1 /usr/local/bin
)

# containerd enable runsc
mkdir -p /etc/containerd
cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins."io.containerd.runtime.v1.linux"]
  shim_debug = true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
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
