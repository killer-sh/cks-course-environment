# Course Resources

Many sections reference commands or links in their resources.

## Create your course K8s cluster

### Cluster Specification
```
# cks-master
sudo -i
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_master.sh)


# cks-worker
sudo -i
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_worker.sh)


# run the printed kubeadm-join-command from the master on the worker
```

### Practice - Create GCP Account
```
https://console.cloud.google.com
```

### Create your course K8s cluster
```
# install gcloud sdk from
https://cloud.google.com/sdk/auth_success

# then run locally
gcloud auth login
gcloud projects list
gcloud config set project YOUR-PROJECT-ID
gcloud compute instances list # should be empty right now
```

### Practice - Create Kubeadm Cluster in GCP
```
# CREATE cks-master VM using gcloud command
# not necessary if created using the browser interface
gcloud compute instances create cks-master --zone=europe-west3-c \
--machine-type=e2-medium \
--image=ubuntu-2004-focal-v20220419 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB

# CREATE cks-worker VM using gcloud command
# not necessary if created using the browser interface
gcloud compute instances create cks-worker --zone=europe-west3-c \
--machine-type=e2-medium \
--image=ubuntu-2004-focal-v20220419 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB

# you can use a region near you
https://cloud.google.com/compute/docs/regions-zones


# INSTALL cks-master
gcloud compute ssh cks-master
sudo -i
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_master.sh)


# INSTALL cks-worker
gcloud compute ssh cks-worker
sudo -i
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_worker.sh)
```

### Practice - Firewall rules for NodePorts
```
gcloud compute firewall-rules create nodeports --allow tcp:30000-40000
```

## Foundation - Kubernetes Secure Architecture
```
# All You Need to Know About Certificates in Kubernetes
https://www.youtube.com/watch?v=gXz4cq3PKdg

# Kubernetes Components
https://kubernetes.io/docs/concepts/overview/components

# PKI certificates and requirements
https://kubernetes.io/docs/setup/best-practices/certificates
```

## Foundation - Containers under the hood
```
# What have containers done for you lately?
https://www.youtube.com/watch?v=MHv6cWjvQjM
```

## Cluster Setup - Network Policies
```
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/network-policies/default-deny

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/network-policies/frontend-backend

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/network-policies/frontend-backend-database

---------------------------------------------------------------------------

https://kubernetes.io/docs/concepts/services-networking/network-policies
```

## Cluster Setup - GUI Elements
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.1.0/aio/deploy/recommended.yaml

---------------------------------------------------------------------------

https://github.com/kubernetes/dashboard/blob/master/docs/common/dashboard-arguments.md

---------------------------------------------------------------------------

k -n kubernetes-dashboard create rolebinding insecure --serviceaccount kubernetes-dashboard:kubernetes-dashboard --clusterrole view

k -n kubernetes-dashboard create clusterrolebinding insecure --serviceaccount kubernetes-dashboard:kubernetes-dashboard --clusterrole view

---------------------------------------------------------------------------

https://github.com/kubernetes/dashboard/blob/master/docs/common/dashboard-arguments.md

https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md
```

## Cluster Setup - Secure Ingress
```
# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/cluster-setup/secure-ingress/nginx-ingress-controller.yaml

# Complete Example
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/secure-ingress

# K8s Ingress Docs
https://kubernetes.io/docs/concepts/services-networking/ingress

---------------------------------------------------------------------------

# generate cert & key
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
	# Common Name: secure-ingress.com

# Complete Example
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/secure-ingress

# curl command to access, replace your IP and secure NodePort->443
curl https://secure-ingress.com:31047/service2 -kv --resolve secure-ingress.com:31047:34.105.246.174

# k8s docs
https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
```

## Cluster Setup - Node Metadata Protection
```
https://cloud.google.com/compute/docs/storing-retrieving-metadata

curl "http://metadata.google.internal/computeMetadata/v1/instance/disks/" -H "Metadata-Flavor: Google"

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/protect-node-metadata
```

## Cluster Setup - CIS Benchmarks
```
# how to run
https://github.com/aquasecurity/kube-bench/blob/main/docs/running.md

# run on master
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -t aquasec/kube-bench:latest run --targets=master --version 1.22

# run on worker
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -t aquasec/kube-bench:latest run --targets=node --version 1.22

---------------------------------------------------------------------------

https://www.youtube.com/watch?v=53-v3stlnCo

https://github.com/docker/docker-bench-security
```

## Cluster Hardening - RBAC
```
k create ns red
k create ns blue

k -n red create role secret-manager --verb=get --resource=secrets
k -n red create rolebinding secret-manager --role=secret-manager --user=jane
k -n blue create role secret-manager --verb=get --verb=list --resource=secrets
k -n blue create rolebinding secret-manager --role=secret-manager --user=jane


# check permissions
k -n red auth can-i -h
k -n red auth can-i create pods --as jane # no
k -n red auth can-i get secrets --as jane # yes
k -n red auth can-i list secrets --as jane # no

k -n blue auth can-i list secrets --as jane # yes
k -n blue auth can-i get secrets --as jane # yes

k -n default auth can-i get secrets --as jane #no

---------------------------------------------------------------------------

k create clusterrole deploy-deleter --verb=delete --resource=deployment

k create clusterrolebinding deploy-deleter --clusterrole=deploy-deleter --user=jane

k -n red create rolebinding deploy-deleter --clusterrole=deploy-deleter --user=jim

# test jane
k auth can-i delete deploy --as jane # yes
k auth can-i delete deploy --as jane -n red # yes
k auth can-i delete deploy --as jane -n blue # yes
k auth can-i delete deploy --as jane -A # yes
k auth can-i create deploy --as jane --all-namespaces # no

# test jim
k auth can-i delete deploy --as jim # no
k auth can-i delete deploy --as jim -A # no
k auth can-i delete deploy --as jim -n red # yes
k auth can-i delete deploy --as jim -n blue # no

---------------------------------------------------------------------------

openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr # only set Common Name = jane


# create CertificateSigningRequest with base64 jane.csr
https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests
cat jane.csr | base64 -w 0


# add new KUBECONFIG
k config set-credentials jane --client-key=jane.key --client-certificate=jane.crt
k config set-context jane --cluster=kubernetes --user=jane
k config view
k config get-contexts
k config use-context jane
```

## Cluster Hardening - Exercise caution in using ServiceAccounts
```
# from inside a Pod we can do:
cat /run/secrets/kubernetes.io/serviceaccount/token

curl https://kubernetes.default -k -H "Authorization: Bearer SA_TOKEN"

https://kubernetes.io/docs/tasks/run-application/access-api-from-pod

---------------------------------------------------------------------------


# Bound Service Account Tokens
https://github.com/kubernetes/enhancements/blob/master/keps/sig-auth/1205-bound-service-account-tokens/README.md

---------------------------------------------------------------------------

https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account

https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin

https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account

```

## Cluster Hardening - Restrict API Access
```
# inspect apiserver cert
cd /etc/kubernetes/pki
openssl x509 -in apiserver.crt -text

---------------------------------------------------------------------------

https://kubernetes.io/docs/concepts/security/controlling-access
```

## Cluster Hardening - Upgrade Kubernetes

```
# master
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/previous/install_master.sh)

# worker
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/previous/install_worker.sh)

---------------------------------------------------------------------------

# drain
kubectl drain cks-controlplane

# upgrade kubeadm
apt-get update
apt-cache show kubeadm | grep 1.22
apt-mark unhold kubeadm
apt-mark hold kubectl kubelet
apt-get install kubeadm=1.22.5-00
apt-mark hold kubeadm

# kubeadm upgrade
kubeadm version # correct version?
kubeadm upgrade plan
kubeadm upgrade apply 1.22.5

# kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get install kubelet=1.22.5-00 kubectl=1.22.5-00
apt-mark hold kubelet kubectl

# restart kubelet
service kubelet restart
service kubelet status

# show result
kubeadm upgrade plan
kubectl version

# uncordon
kubectl uncordon cks-controlplane

---------------------------------------------------------------------------

# drain
kubectl drain cks-node

# upgrade kubeadm
apt-get update
apt-cache show kubeadm | grep 1.22
apt-mark unhold kubeadm
apt-mark hold kubectl kubelet
apt-get install kubeadm=1.22.5-00
apt-mark hold kubeadm

# kubeadm upgrade
kubeadm version # correct version?
kubeadm upgrade node

# kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get install kubelet=1.22.5-00 kubectl=1.22.5-00
apt-mark hold kubelet kubectl

# restart kubelet
service kubelet restart
service kubelet status

# uncordon
kubectl uncordon cks-node

---------------------------------------------------------------------------

# kubeadm upgrade
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade

# k8s versions
https://kubernetes.io/docs/setup/release/version-skew-policy
```

## Microservice Vulnerabilities - Manage Kubernetes Secrets
```
# access secret int etcd
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd

ETCDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt --key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt endpoint health

# --endpoints "https://127.0.0.1:2379" not necessary because we’re on same node

ETCDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt --key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt get /registry/secrets/default/secret1

---------------------------------------------------------------------------


# encrypt etcd docs page
# contains also example on how to read etcd secret
https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data

# read secret from etcd
ETCDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt --key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt get /registry/secrets/default/very-secure

---------------------------------------------------------------------------

https://v1-22.docs.kubernetes.io/docs/concepts/configuration/secret/#risks

https://www.youtube.com/watch?v=f4Ru6CPG1z4

https://www.cncf.io/webinars/kubernetes-secrets-management-build-secure-apps-faster-without-secrets
```

## Microservice Vulnerabilities - Container Runtime Sandboxes
```
# Example of Pod+RuntimeClass:
https://github.com/killer-sh/cks-course-environment/blob/master/course-content/microservice-vulnerabilities/container-runtimes/gvisor/example.yaml

---------------------------------------------------------------------------

# IF THE INSTALL SCRIPT FAILS then you can try to change the URL= further down in the script from latest to a specific release
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/microservice-vulnerabilities/container-runtimes/gvisor/install_gvisor.sh)

# Example of Pod+RuntimeClass:
https://github.com/killer-sh/cks-course-environment/blob/master/course-content/microservice-vulnerabilities/container-runtimes/gvisor/example.yaml

---------------------------------------------------------------------------

# Container Runtime Landscape
https://www.youtube.com/watch?v=RyXL1zOa8Bw

# Gvisor
https://www.youtube.com/watch?v=kxUZ4lVFuVo

# Kata Containers
https://www.youtube.com/watch?v=4gmLXyMeYWI
```

## Microservice Vulnerabilities - OS Level Security Domains
```
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core

```

## Microservice Vulnerabilities - Open Policy Agent (OPA)

```
kubectl create -f https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/opa/gatekeeper.yaml

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/opa/deny-all

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/opa/namespace-labels

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/opa/deployment-replica-count

---------------------------------------------------------------------------

https://play.openpolicyagent.org

https://github.com/BouweCeunen/gatekeeper-policies

---------------------------------------------------------------------------

https://www.youtube.com/watch?v=RDWndems-sk
```

## Supply Chain Security - Image Footprint
```
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/supply-chain-security/image-footprint

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/tree/master/course-content/supply-chain-security/image-footprint

---------------------------------------------------------------------------

https://docs.docker.com/develop/develop-images/dockerfile_best-practices
```

## Supply Chain Security - Static Analysis
```
docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < pod.yaml

---------------------------------------------------------------------------

git clone https://github.com/killer-sh/cks-course-environment.git

cd cks-course-environment/course-content/supply-chain-security/static-analysis/conftest/kubernetes

./run.sh

---------------------------------------------------------------------------

git clone https://github.com/killer-sh/cks-course-environment.git

cd cks-course-environment/course-content/supply-chain-security/static-analysis/conftest/docker

./run.sh
```

## Supply Chain Security - Image Vulnerability Scanning
```
https://github.com/aquasecurity/trivy#docker

docker run ghcr.io/aquasecurity/trivy:latest image nginx:latest
```

## Supply Chain Security - Secure Supply Chain
```
# install opa
kubectl create -f https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/opa/gatekeeper.yaml

# opa resources
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/supply-chain-security/secure-the-supply-chain/whitelist-registries/opa

---------------------------------------------------------------------------

# get example
git clone https://github.com/killer-sh/cks-course-environment.git
cp -r cks-course-environment/course-content/supply-chain-security/secure-the-supply-chain/whitelist-registries/ImagePolicyWebhook/ /etc/kubernetes/admission


# to debug the apiserver we check logs in:
/var/log/pods/kube-system_kube-apiserver*


# example of an external service which can be used
https://github.com/flavio/kube-image-bouncer
```

## Runtime Security - Behavioral Analytics at host and container level
```
https://man7.org/linux/man-pages/man2/syscalls.2.html

---------------------------------------------------------------------------

# install falco
curl -s https://falco.org/repo/falcosecurity-packages.asc | apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | tee -a /etc/apt/sources.list.d/falcosecurity.list
apt-get update -y
apt-get install -y linux-headers-$(uname -r)
apt-get install -y falco=0.32.1

# docs about falco
https://v1-16.docs.kubernetes.io/docs/tasks/debug-application-cluster/falco

---------------------------------------------------------------------------

https://falco.org/docs/rules/supported-fields

---------------------------------------------------------------------------

# Syscall talk by Liz Rice
https://www.youtube.com/watch?v=8g-NUUmCeGI
```

## Runtime Security - Auditing
```
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/runtime-security/auditing

---------------------------------------------------------------------------

https://www.youtube.com/watch?v=HXtLTxo30SY
```

## System Hardening - Kernel Hardening Tools
```angular2html
# apparmor profile
https://github.com/killer-sh/cks-course-environment/blob/master/course-content/system-hardening/kernel-hardening-tools/apparmor/profile-docker-nginx

# k8s docs apparmor
https://kubernetes.io/docs/tutorials/clusters/apparmor/#example

---------------------------------------------------------------------------

https://github.com/killer-sh/cks-course-environment/blob/master/course-content/system-hardening/kernel-hardening-tools/seccomp/profile-docker-nginx.json

---------------------------------------------------------------------------

# syscalls
https://www.youtube.com/watch?v=8g-NUUmCeGI

# AppArmor, SELinux Introduction 
https://www.youtube.com/watch?v=JFjXvIwAeVI
```
