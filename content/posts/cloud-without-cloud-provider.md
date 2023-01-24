---
title: "A cloud without cloud provider"
date: 2023-01-13
tags: ["cloud", "openstack", "infra"]
author: "Florian Trincal"
draft: false
---

A cloud without cloud provider, it's possible ? In this article I will present the Openstack cloud solution, which allows to have a real cloud system in your company. 
<!--more-->

## A cloud is in every mouth today

In the current context, most companies are wondering about their information system’s migration to the cloud. Several blocking points may arise in particular in the fact of having its data hosted in cloud providers type GAFAM (like GCP and AWS), themselves subject to the patriotism act.
It is of course possible to use French cloud providers, such as OvhCloud or Scaleway for example, but here again the problem of transferring its data to a private partner. 

##  But what to do?

it's quite possible to have your own cloud system within your company, this allows you to use different concepts and technologies, it also allows you to pool resources. The most popular cloud systems known in the world is Openstack!!!

## What's Openstack ?

To present Openstack, we will go back in time to 2010. Openstack is an open-source cloud computing system born from the collaboration between NASA and the hosting provider Rackspace Hosting.

The goal of this project is to provide cloud-based resources and services on standardized hardware.

Openstack is used by all types of companies, telecom operators like Orange with their FlexEngine cloud, but also French cloud providers like OVHCloud.

The Public sector and especially the research sector also uses Openstack a lot. For example, NUBO cloud (the Openstack platform maintained by the Public Finance Department), or Orion cloud of the national agricultural and environmental research institute (INRAE).
On a larger scale at European level, we find in particular CERN (European Nuclear Research Committee)



## Where does Openstack fit into the different cloud categories?

There are 3 categories of cloud services: 

+ **SAAS (Software as Service)**, which represents applications that can be used in cloud environments such as Dropbox etc..

+ **PAAS (Plateform As Service)** which represents the layer below the cloud level, this level is intended to provide services for application deployment in SAAS mode as openshift can do for example

+ **IAAS (Infrastructure As Service)**, This is the lowest level of cloud layers, it is on this basis that all other cloud categories are based. And that’s where we find Openstack

![Openstack IAAS](/images/posts/openstack1.png)

## What does Openstack consist of?

Openstack consists of several services that will collaborate together, there are the open stack services and the optional services.

Before discussing the mandatory services of Openstack, we must also take into account that all the services need to store information in a database, Mariadb being the privileged system in most installations.
Inter-service communication is paramount , this role is assigned to the RabbitMQ messaging system. 

I will now introduce Openstack’s core services:

+ **NOVA :**
 It's the service that will allow to create and manage instances of calculations on the Openstack platform, the virtualization engine used by default is libvirt, but other engines are possible, there have even been installations based on the VmWare ESXI engine in the past.

 + **KEYSTONE :**
 It is the service that will manage all the authentications whether it is the inter-service authorizations or the authentications of the users.

 + **CINDER :** 
 This service will allow the creation of storage volume to attached instances, these volumes can generally be attached detached from one instance to another

 + **GLANCE:**
 Glance is a system image management service for instance creation. You can add, delete images and even take snapshots

 + **NEUTRON:**
 Neutron is the service of management of the network, it will allow the creation of virtual networks for the instances but also allow of associated floating ip, but also of ability to do filtering of protocols with the security groups

 + **HORIZON:**
 Horizon is the service allowing access to the web administration interface for users but also to the APIs, of the various services

 Now among the optional services it is interesting to have include:

 + **SWIFT:** 
 Swift is a distributed and redundant storage system, it allows the supply of volume in block mode accessible via APIs of type S3.

 + **HEAT:**
Heat is an orchestration engine specific to Openstack.
It makes it possible to automate the construction of an entire infrastructure, consisting of storage computes or networks, via a Yaml file.

 + **OCTAVIA:**
This service is particularly interesting when you want to manage your own load-balancing system.
Octavia provides a simple load-balancing system to complete a redundant architecture

 + **DESIGNATE:**
 With Designate, it is possible to fully manage the domain name management services as can the AWS route53 service.

 + **TROVE:**
 Trove is an on-demand database supply service. Trove provides databases such as Cassandra, CouchBase, CouchDB, DataStax Enterprise, DB2, MariaDB, MongoDB, MySQL, Oracle, Percona Server, PostgreSQL, Redis and Vertica. It manages user accesses but also the backup restoration of databases.

 + **IRONIC:**
Ironic is a service that can function either directly in an Openstack environment or independently. It allows to install physical compute nodes as instances automatically.

## How to use Openstack cloud with Terraform

Openstack like most cloud systems is fully compatible with the use of terraform, I will give a small example of deployment of an instance and a network in an existing openstack project.

The first files to create to connect to the Openstack apis are:

+ **provider.yaml**
```
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.48.0"
    }

}
}
## Configure the OpenStack Provider
provider "openstack" {
  cloud = "mon_cloud" ## corresponds to the name of the cloud in the cloud.yaml file
}

```
+ **clouds.yaml**
```
clouds:
  mon_cloud:

    auth:

      auth_url: https://mon-cloud.wyll.io:5000

      project_name: ""# name of existing project
      username: ""# name of user as right on project
      password: ""# password of user
      project_domain_name: "my_domain" # domain whose project depends
      domain_name: "INRA"  # domain whose user depends
    region_name: "my_region" # region whose project depends

    interface: "public"
    identity_api_version: 3
```
Other files must to be created to deploy instance on openstack project :

+ **main.yaml**

```
resource "openstack_compute_instance_v2" "instance" {
  name            = var.instance-name
  image_id        = data.openstack_images_image_v2.image_instance.id
  flavor_id       = data.openstack_compute_flavor_v2.instance.id
  key_pair        = var.key_pair
  security_groups = var.security_groups

network {
    uuid = data.openstack_networking_network_v2.my_network.id ## network used for instance ip
  }

}
### get foating ip on the pool
resource "openstack_networking_floatingip_v2" "fip1" {
  pool = var.floating-zone[0] ## floating ip to expose instance to external network
}

### associate floating ip to instance
resource "openstack_compute_floatingip_associate_v2" "fip1" {
  floating_ip = openstack_networking_floatingip_v2.fip1.address
  instance_id = openstack_compute_instance_v2.instance.id
}
```

+ **variables.yaml**
```
variable instance-name {
type = string
default = "toto"### name of instance
}

data "openstack_compute_flavor_v2" "instance" {
  name = "m1.small" # list of flavor create on openstack

data "openstack_images_image_v2" "image_instance" {
  name        = "ubuntu-22.04-LTS" # system image to be deployed
  most_recent = true
}

variable key_pair {
type = string
default = "my-key" ## ssh key to be used on instance
}

variable "security_groups" {
type = set(string)
default = ["default"] ### security group of project
}

variable net-name {
default = ["my_network", "my_network2"] ### list of instance networks
type = list(string)
}

data "openstack_networking_network_v2" "my_network" {
  name = "${var.net-name[0]}"
}

data "openstack_networking_network_v2" "my_network2" {
  name = "${var.net-name[1]}"
}

variable floating-zone {
    type = list(string)
    default = ["float_net1", "float_net2"] ### list of floating ip network
}
```
+ **output.yaml**
```
output instance_name {
description = "instance name"
value = openstack_compute_instance_v2.instance.name
}
output instance_prv-ip {
    description = "internal instance ip"
    value = openstack_compute_instance_v2.instance.access_ip_v4
}

output instance_floating-ip {
    description = "floating ip mapped on instance"
    value = openstack_networking_floatingip_v2.fip1.address
}
```

## And now the rest? ##

I piqued your interest, you want to see what Openstack looks like? in a second article I will show you how to install appliances all in one from openstack type kolla ansible all in one, or microstack.




