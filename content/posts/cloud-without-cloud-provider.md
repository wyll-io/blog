---
title: "A cloud without cloud provider"
date: 2022-01-13
tags: ["cloud", "openstack", "infra"]
author: "Florian Trincal"
draft: true
---

# A cloud without cloud provider, it's possible ?

In this article I will present the Openstack cloud solution, which allows to have a real cloud system in your company. 

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
    - SAAS (Software as Service), which represents applications that can be used in cloud environments such as Dropbox etc..
    - PAAS (Plateform As Service) which represents the layer below the cloud level, this level is intended to provide services for application deployment in SAAS mode as openshift can do for example
    - IAAS (Infrastructure As Service), This is the lowest level of cloud layers, it is on this basis that all other cloud categories are based.
And that’s where we find Openstack
