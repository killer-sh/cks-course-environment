#!/usr/bin/env bash
# https://github.com/kata-containers/documentation/blob/master/how-to/containerd-kata.md

ARCH=$(arch)
BRANCH="${BRANCH:-master}"
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${BRANCH}/xUbuntu_$(lsb_release -rs)/ /' > /etc/apt/sources.list.d/kata-containers.list"
curl -sL  http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${BRANCH}/xUbuntu_$(lsb_release -rs)/Release.key | sudo apt-key add -
sudo -E apt-get update
sudo -E apt-get -y install kata-runtime kata-proxy kata-shim



# docker
# https://github.com/kata-containers/documentation/blob/master/install/docker/ubuntu-docker-install.md


## https://github.com/kata-containers/documentation/blob/master/how-to/run-kata-with-k8s.md
## to make work with k8s
#sudo mkdir -p  /etc/systemd/system/kubelet.service.d/
#cat << EOF | sudo tee  /etc/systemd/system/kubelet.service.d/0-containerd.conf
#[Service]
#Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
#EOF
#iptables -P FORWARD ACCEPT
#systemctl daemon-reload
#systemctl restart containerd
#systemctl restart kubelet
