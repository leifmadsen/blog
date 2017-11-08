+++
date = "2017-11-07T13:48:19-05:00"
categories = ["nfvpe","ansible","continuous integration"]
keywords = ["ansible","awx","tower","CI","continous integration","DevOps","devops","testing","integation","majik"]
description = ""
title = "AWX: The Poor Man's CI?"
draft = "true"

+++
{{< load-photoswipe >}}
I'm just going to go ahead and blame [@dougbtv](https://twitter.com/dougbtv)
for all my awesome and terrible ideas. We've been working on several
[Ansible](https://github.com/ansible/ansible) playbooks to spin up development
environments; like
[kucean](https://github.com/redhat-nfvpe/kube-centos-ansible).

Due to the rapid development nature of things like Kubernetes, Heketi,
GlusterFS, and other tools, it's both possible and probable that our playbooks
could become broken at any given time. We've been wanting to get some continous
integration spun up to test this with something like [Zuul v3](https://docs.openstack.org/infra/zuul/feature/zuulv3/index.html)
but the learning curve for something like that is a bit more than we'd like to
tackle for some simple periodic runs. Same goes for [Jenkins](https://jenkins.io/doc/)
or any other number of continous integration software bits.

Enter the brilliantly mad mind of @dougbtv. He wondered if AWX (Ansible Tower)
could be turned into a sort of "Poor Man's CI"? Hold my beer. Challenge
accepted!
<!--more-->

## Get AWX Installed

The first thing we need to do is get AWX installed. Lucky for you, I already
wrote up a [blog
post](http://blog.leifmadsen.com/blog/2017/11/07/deploying-awx-to-openstack-rdo-cloud/)
showing you how to consume some Ansible automation to get an OpenStack virtual
machine up and running and populated with the fiddly bits of AWX. There is also
the [upstream AWX installation guides](https://github.com/ansible/awx/blob/devel/INSTALL.md)
that you can follow to get AWX up and running in your environment.

## So what are we trying to accomplish?

First, let's step back and define what we're trying to do. The goal here is to
build something quick and dirty that would let us build configure some periodic
runs of our Ansible playbooks. Some of the nice to have bits would be:

* easily run our existing Ansible playbooks / Ansible native
* run against some cloud infrastructure
* continue to work against our local virtual, KVM-based development
  environments
* give some historical record of successful and failed runs
* provide notifications to our Slack channel when things fail

So what don't we want? Heavy infrastructure that we need to spend a lot of time
maintaining. Long setup times. Large amount of yak-shaving (overhead) to get
"something" up and going.

Because I was able to get AWX up and running in a short period of time through
automation (see previous section about getting AWX installed), it seemed like
AWX might fit the bill to fill in our complete lack of automation with
"something".

## Spoiler alert!

Turns out, AWX makes a pretty decent little periodic testing system when used
in conjunction with cloud infrastructure where your machines can be provisioned
and deprovisioned through Ansible playbooks, and then layering your
infrastructure deployment on top of that.

In our case, we wanted a twice-per-day deployment of
[kucean](https://github.com/redhat-nfvpe/kube-centos-ansible) to run against
the RDO Cloud, and for a failure notification to pop into our Slack channel
when things stopped working.

I was able to build out just enough Ansible plays to make the whole thing work
out, and was pretty impressed with how clean some of the separation of
variables, facts, and other playbook specific data was. Notifications worked
swimmingly, and the Job Workflow stuff did exactly what I hoped.

Now that we know things weren't a complete disaster (much the opposite), you
know it's worth continuing to read on how we did it!

## Building a minimal CI environment

Our minimal CI environment will be entirely deployed into an OpenStack cloud,
where AWX will run, and will also have access to deploying virtual machines in
the same cloud for our jobs (although it could easily be another cloud
environment, project, etc).

{{% figure src="/media/awx-ci-topology.png" alt="Basic AWX CI Topology" caption-position="bottom" %}}

Our AWX environment will make use of my
[openstack-inventory-builder](https://github.com/leifmadsen/openstack-inventory-builder)
playbook which does the heavy lifting of creating our OpenStack virtual
machines via a variable list. By using the playbook, we can create a job
template for the provisioning and deprovisioning of the virtual machines that
are agnostic to our deployment.

In the following sections I'll show you how I setup AWX to periodically
deprovision a set of virtual machine, reinstantiate them, run
[kucean](https://github.com/redhat-nfvpe/kube-centos-ansible) against them to
get a Kubernetes environment running, and report back to our Slack channel via
notifications.

### Creating the projects

In AWX, a project is an SCM (source control management) object that contains
the Ansible playbooks you want to use in a job template. For our configuration
we'll be setting up two projects;
[openstack-inventory-builder](https://github.com/leifmadsen/openstack-inventory-builder)
and [kucean](https://github.com/redhat-nfvpe/kube-centos-ansible).

To create these projects, we need to click on the Projects tab and click Add.
We then need to fill in the fields like in the screenshot below.

{{< figure src="/media/awx-ci/project-configuration.png" alt="Project configuration in AWX" >}}

### Creating credentials


### Creating inventories


### Creating inventory sources


### Creating job templates

### Creating a job workflow

### Setting up a Slack notification
