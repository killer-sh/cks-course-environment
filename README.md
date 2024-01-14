# Kubernetes CKS Course Environment

This is the repository of the [CKS FULL COURSE](https://youtu.be/d9xfB5qaOfg) on Youtube

There is also the [CKS SIMULATOR](https://killer.sh/cks)


## Course Resources

Many sections reference commands or links in their resources.

[RESOURCES](Resources.md)

## Killercoda Scenarios

Many topics have interactive in-browser Killercoda scenarios at the end. Solve these to test and harden your knowledge!

[SCENARIOS](Scenarios.md)

## Setup Cluster in Gcloud

### Setup cks-master

#### Create VM
```
1. create VM:
name: cks-master
family: e2-medium (2vCPU, 4GB)
image: ubuntu20.04 LTS focal
disk: 50GB
```

Like:
```
gcloud compute instances create cks-master --zone=europe-west3-c \
--machine-type=e2-medium \
--image=ubuntu-2004-focal-v20220419 \
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
image: ubuntu20.04 LTS focal
disk: 50GB
```

Like:
```
gcloud compute instances create cks-worker --zone=europe-west3-c \
--machine-type=e2-medium \
--image=ubuntu-2004-focal-v20220419 \
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
