# Kubernetes CKS Course Environment

This is the repository of the [CKS FULL COURSE](https://www.udemy.com/course/certified-kubernetes-security-specialist/?referralCode=D9329DEE203E7FEBE86B)

There is also just the [CKS SIMULATOR](https://killer.sh/cks)

## Setup Cluster in Gcloud

### Setup cks-master

#### Create VM
```
1. create VM:
name: cks-master
family: e2-medium (2vCPU, 4GB)
image: ubuntu18.04 LTS bionic
disk: 50GB
```

Like:
```
gcloud compute instances create cks-master --zone=europe-west3-c \
--machine-type=e2-medium \
--image=ubuntu-1804-bionic-v20201014 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB
```

#### Configure
```
sudo -i
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_master.sh)
```

### Setup cks-worker

#### Create VM
```
1. create VM:
name: cks-worker
family: e2-medium (2vCPU, 4GB)
image: ubuntu18.04 LTS bionic
disk: 50GB
```

Like:
```
gcloud compute instances create cks-worker --zone=europe-west3-c \
--machine-type=e2-medium \
--image=ubuntu-1804-bionic-v20201014 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB
```

#### Configure
```
sudo -i
bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_worker.sh)
```

### Connect to cluster
```
# install "gcloud" command

# connect "gcloud" to your GCP
gcloud auth login
gcloud projects list
gcloud config set project YOUR_PROJECT

# connect to instance
gcloud compute instances list
gcloud compute ssh cks-master
```

### Open ports
```
gcloud compute firewall-rules create nodeports --allow tcp:30000-40000
```
