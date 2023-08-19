---
title: "Fully working Kubernetes cluster with Baremetal LB"
date: 2022-11-20
tags: ["aws", "kubernetes", "metallb"]
author: "François ALLAIS"
draft: true
---

# Introduction

If you want to use Kubernetes locally, or on a private environment, you will face some troubles regarding the Load Balancer. As a workaround, you can you [MetalLB](https://metallb.universe.tf).

I will deploy my Kubernetes cluster on a an AWS EC2 instance, running Ubuntu 20.04.
[ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
        [ERROR Mem]

# Kubernetes installation

The hosts will take a few minutes to bootstrap, after which you should log into each via ssh and begin installing the same set of packages for Docker and Kubernetes. containerd is now available as an alternative runtime, but is slightly more work to configure.

## Disable swap

Swap MUST be disable : `swapoff -a`.  
Change this in `/etc/default/grub` : *GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"*  
Then run this : `update-grub && reboot`.

## Docker installation

A known / tested version of Docker must be used with the kubeadm bootstrapper, otherwise we'll potentially encounter unknown behaviours. The apt package repository contains a sufficiently old version for us.

```
sudo apt update
sudo apt install docker.io
```

## Kubernetes installation

First, add the Kubernetes signing key.

```
sudo apt update
sudo apt install -y apt-transport-https
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```

Then you can add the repositories.

```
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
```

## Tools installation

Now you can install the Kubernetes tools :

 - kubelet
 - kubeadm
 - kubectl

```
sudo apt update
sudo apt install kubelet kubeadm kubectl
```

It is advised to mark these 3 packages on-hold so that they can't be upgraded i the future : `apt-mark hold kubectl kubelet kubeadm`.

## Init the cluster

Choose the appropriate network CIDR that your Pods will use, in my case, I can use **192.168.0.0/16**.

```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

As suggested, run these commands.

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Then check that the cluster is working : `watch kubectl get pods --all-namespaces`

## Networking

At this stage, you need to install a network add-on so that the *Pods* call communicate to each others, it is called a Container Network Interface (CNI). Here is a list of some that exist :

 - Flannel 
 - Antrea
 - Calico

For this article, I will demonstrate with Antrea and Calico, which are known to have a [good compatibility with MetalLB](https://metallb.universe.tf/installation/network-addons/)

### Calico

Download the Calico manifest : `curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/calico.yaml -O`
Apply it : `kubectl apply -f calico.yaml`.


Again, you can watch the progression with : `watch kubectl get pods --all-namespaces`

Wait until you see this :

```
Every 2.0s: kubectl get pods --all-namespaces                                                                                                                             ip-172-31-8-173: Wed Nov 23 16:19:13 2022

NAMESPACE     NAME                                       READY   STATUS    RESTARTS        AGE
kube-system   calico-kube-controllers-798cc86c47-28mhb   1/1     Running   0               116s
kube-system   calico-node-nhh4w                          1/1     Running   0               116s
kube-system   coredns-565d847f94-25qwl                   1/1     Running   0               4m59s
kube-system   coredns-565d847f94-t2l6x                   1/1     Running   0               4m59s
kube-system   etcd-ip-172-31-8-173                       1/1     Running   2 (3m4s ago)    4m19s
kube-system   kube-apiserver-ip-172-31-8-173             1/1     Running   1 (5m37s ago)   5m32s
kube-system   kube-controller-manager-ip-172-31-8-173    1/1     Running   3 (2m57s ago)   4m48s
kube-system   kube-proxy-j7bfv                           1/1     Running   4 (78s ago)     4m59s
kube-system   kube-scheduler-ip-172-31-8-173             1/1     Running   4 (3m24s ago)   4m33s
```

# MetalLB installation

## Manifest

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml