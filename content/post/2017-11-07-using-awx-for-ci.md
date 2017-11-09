+++
date = "2017-11-07T13:48:19-05:00"
categories = ["nfvpe","ansible","continuous integration"]
keywords = ["ansible","awx","tower","CI","continous integration","DevOps","devops","testing","integation","majik"]
description = ""
title = "AWX: The Poor Man's CI?"

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
integration spun up to test this with [Zuul v3](https://docs.openstack.org/infra/zuul/feature/zuulv3/index.html)
but the learning curve for that is a bit more than we'd prefer to
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
swimmingly, and the Workflow Template stuff did exactly what I hoped.

Now that we know things weren't a complete disaster (much the opposite), you
know it's worth continuing to read on how we did it!

## Building a minimal CI environment

Our minimal CI environment will be entirely deployed into an OpenStack cloud,
where AWX will run, and will also have access to deploying virtual machines in
the same cloud for our jobs (although it could easily be another cloud
environment, project, etc).

{{< figure src="/media/awx-ci-topology.png" alt="Basic AWX CI Topology" caption-position="bottom" >}}

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

## Creating the projects

In AWX, a project is an SCM (source control management) object that contains
the Ansible playbooks you want to use in a job template. For our configuration
we'll be setting up two projects;
[openstack-inventory-builder](https://github.com/leifmadsen/openstack-inventory-builder)
and [kucean](https://github.com/redhat-nfvpe/kube-centos-ansible).

To create these projects, we need to click on the Projects tab and click Add.
We then need to fill in the fields like in the screenshot below.

{{< figure src="/media/awx-ci/project-configuration.png" alt="Project configuration in AWX" >}}

* **name**: a unique name for the project
* **organization**: just use the default organization for now
* **SCM type**: Git
* **SCM url**: the GitHub URL for the project (HTTPS connection)
* **SCM branch/tag/commit**: using master branch
* **SCM update options**
  * **Clean**: reverts and local changes to the project / repo
  * **Delete on Update**: delete the entire repo when performing an update
  * **Update on Launch**: update the project prior to any job run using this
    project

We do the same setup for https://github.com/redhat-nfvpe/kube-centos-ansible,
which will leave us with 2 projects; `openstack-inventory-builder` and
`kube-centos-ansible` (aka `kucean`). We'll use these 2 projects to instantiate
some virtual machines in our OpenStack cloud, and deploy a Kubernetes cluster.

## Creating credentials

With our projects created, we need to build our credentials. We're going to
build three sets of credentials.

{{< figure src="/media/awx-ci/credentials-list.png" alt="List of credentials we'll create" >}}

* _Local_: machine connection to locally run the Ansible playbooks on our AWX
  virtual machine
* _RDO-AWX_: machine connection that allows us to SSH into the resulting
  virtual machines in our OpenStack cloud
* _RDO Cloud_: OpenStack connection that allows us to operate against the
  OpenStack API to instantiate virtual machines

### Local connection

Click on the _Add_ button and create our Local connection like in our image
below.

{{< figure src="/media/awx-ci/credential-local-create.png" alt="Local machine connection" >}}

There shouldn't be a need to populate anything, as we'll later apply this to a
local Ansible connection in our inventory setup with
`ansible_connection=local`.

### RDO-AWX connection

With this connection we need to generate an SSH key that we can use to connect
to our virtual machines. If you have a connection setup to your cloud (like we
setup in my blog post [Deploying AWX to OpenStack RDO Cloud](http://blog.leifmadsen.com/blog/2017/11/07/deploying-awx-to-openstack-rdo-cloud/)) then you can just run
the following command which will result in a new keypair being created in your
cloud. A private RSA key will be dumped to STDOUT, which you'll then copy into
the AWX web interface.

```sh
$ openstack --os-cloud rdocloud keypair create rdo-awx
```

{{< figure src="/media/awx-ci/credential-rdo-awx.png" alt="RDO SSH connection for logging into virtual machines" >}}

### RDO Cloud connection

For our third and final connection, we'll click the _Add_ button and create an
OpenStack credential. First, select `OpenStack` under _Credential Type_ and
populate the fields. You'll need your OpenStack username, password, API URL,
and project.

{{< figure src="/media/awx-ci/credential-rdo-cloud.png" alt="RDO Cloud credential configuration">}}

## Creating inventories

With our credentials all setup, we can start building our inventories. The
inventories are where our jobs will be run against. We need to create two
inventories; Local and RDO Cloud.

The _Local_ inventory will simply be a local Ansible connection where our
`openstack-inventory-builder` project will be launched from, resulting in the
instantitation of virtual machines in our cloud.

The _RDO Cloud_ inventory will contain a list of virtual machines and metadata
that we can run our Kubernetes jobs against.

> **Dependency requirements**
>
> On your AWX host, you'll also need `shade` installed to allow the Ansible
> playbooks to be run for provisioning and deprovisioning. In the
> `openstack-inventory-builder` repository (project) there is a
> `dependencies.yml` playbook you only need to run once on the AWX host.
>
> We'll create the dependency job in one of the upcoming sections.

### Local inventory

The _Local_ inventory will contain a single host; `localhost`. We'll use the
_Local_ inventory to execute our `openstack-inventory-builder` playbooks which
will result in a connection to the OpenStack API to instantiate our virtual
machines.

In order to allow the `openstack-inventory-builder` playbooks `provision.yml`
and `deprovision.yml` to operate, we need to feed it several variables. We'll
configure the values for these variables in the _Variables_ section of
the inventory.

First, click on the Inventories section of the left-side menu bar and then
click _Add_. Select _Inventory_ for a standard inventory object.

Name the inventory anything you want (I used _Local_) and optionally set a
_Description_ and _Organization_ (I'm using the _Default_ organization).

Next, you need to setup the _Variables_ section, which are values that we'll
pass to the `openstack-inventory-builder` job. I've documented that variables
and configuration on the [GitHub repo for `openstack-inventory-builder`](https://github.com/leifmadsen/openstack-inventory-builder), so I won't repeat everything here,
but here is an example set of values you should enter into the _Variables_
field under the yaml document top indicator `---`.

```
---
cloud_name_prefix: AWX
cloud_region_name: regionOne
cloud_availability_zone: nova
cloud_image: 42a43956-a445-47e5-89d0-593b9c7b07d0
cloud_flavor: m1.medium
cloud_key_name: rdo-awx
my_auth_url: https://dc.mycloud.tld:13000/v2.0
my_username: itsme
my_password: ehrmegherdmyp4$$!
my_project_name: "itsme"
```

The big things to note here are the `cloud_key_name` which must match the name
of the keypair you created in the _Credentials_ section for _RDO-AWX_. You'll
also need to configure the authentication to the cloud with the `my_*`
variables like we did in the _RDO Cloud_ credentials section. (I couldn't ever
really figure out how to get AWX to properly read a `clouds.yaml` file, so this
was my work around...)

You'll also need the `cloud_image` value. You can get a list of valid image IDs
by running `openstack --os-cloud rdocloud image list`. For
`kube-centos-ansible` I'm using the ID the corresponds to the image providing
me CentOS 7 x86_64 GenericCloud 1706.

{{< figure src="/media/awx-ci/inventory-local.png" alt="Configuration of the Local inventory" >}}

Now you can click on the _Save_ button.

#### Create the host

For our _Local_ inventory we'll need to add a host; `localhost`. Once you've
saved your _Local_ inventory you should be able to click on the _HOSTS_ tab. In
the _HOSTS_ tab, click on _Add host_.

Set the _Host name_ to `localhost` and put `ansible_connection: local` in the
_Variables_ field under the `---`. Using `ansible_connection: local` keeps us
from having to connect to the machine locally via SSH.

{{< figure src="/media/awx-ci/inventory-host-localhost.png" alt="Inventory localhost connection setup">}}

### Cloud inventory

We're making good progress now and nearing the fun stuff shortly. With our
local inventory sorted, next we need to configure our cloud inventory. The
cloud inventory will get used after our provisioning and deprovisioning
happens, and will be the workhorse for the more interesting jobs, like
deploying Kubernetes into our cloud.

Like before, start by clicking on _Inventories_ and _Add_ a standard inventory
object.

Name the inventory anything you'd like (I used _RDO Cloud_) and optionally set
a _Description_ and _Organization_ (again, I used _Default_).

When you're done setting that up, click on _Save_.

For our _Local_ inventory we added a static host manually called `localhost`.
In this case, our cloud inventory is dynamic, and we want AWX to automatically
update the inventory for us prior to running our jobs. We need this because our
inventory is not static in the cloud, since we'll be tearing down the virtual
machines and spinning up new ones each time we run the Kubernetes deployment
job with `kube-centos-ansible`.

#### Creating inventory sources

Obviously a static inventory isn't going to work for this setup, so we'll
populate the hosts dynamically by using a _Source_.

Click on the _Sources_ tab in your _RDO Cloud_ inventory, and click on _Add
Source_.

First, select the drop down under _Source_ and pick _OpenStack_.

{{< figure src="/media/awx-ci/inventory-cloud-source.png" alt="RDO Cloud source configuration" >}}

Set your _Name_ and _Description_, and then use the magnifying glass icon to
search under the _Credential_ header. We'll use our previously defined _RDO
Cloud_ credential which will allow AWX to connect to the OpenStack API and pull
down various amounts of metadata about the state of our virtual machines.

I then setup the various _Update Options_ as well. These include:

* **Overwrite**: remove old hosts during an update
* **Overwrite Variables**: avoids doing a variable merge and prefers the
  external values (_NOTE_ I probably don't need this)
* **Update on Launch**: any job that uses this source will result in an
  inventory update before launching the job

When you're all done setting this up, click on _Save_.

## Creating job templates

And we're into the home stretch! We can create our job templates now and start
launching jobs. The first job we'll setup is the previously mentioned
`dependencies.yml` playbook from the `openstack-inventory-builder` project.

{{< figure src="/media/awx-ci/job-template-list.png" alt="List of job templates we'll be building" >}}

### Create the OpenStack Setup job template

Click on the _Templates_ menu item on the left of the browser window and select
_Add_. Now select the _Job Template_ object.

{{< figure src="/media/awx-ci/job-template-object.png" alt="Job Template object under the Add button" >}}

Our first job template is going to be _OpenStack Setup_ which we'll just launch
manually after we create it to get the AWX machine ready for the other job
templates we'll create next. The following diagram shows the configuration for
this setup. The main components we're worried about include:

* **Inventory**: Use the _Local_ inventory
* **Project**: Use the `openstack-inventory-builder` project
* **Playbook**: Select the `dependencies.yml` playbook
* **Credential**: Use our `Local` machine credential

{{< figure src="/media/awx-ci/job-template-openstack-setup.png" alt="Job template configuration for the OpenStack Setup job">}}

When you're done configuring your job template, click _Save_.

#### Run the OpenStack Setup Job Template

Before we go and build out all our jobs, now is an excellent time to test our
setup and make sure everything is working. As long as everything has been done
correctly, we should result in the `git pull` of our
`openstack-inventory-builder` project, and Ansible running the
`dependencies.yml` playbook local to our AWX virtual machine.

In the _Templates_ section, you should have a single entry called _OpenStack
Setup_. Under the _Actions_ section on the right side of the browser window you
should see a rocketship icon. Click on that icon, and your job will launch.

{{< figure src="/media/awx-ci/job-template-launch-openstack-setup.png"
alt="Launch the OpenStack Setup job template" >}}

Once you've launched the job, you'll be taken to a window showing you the
progress of the job run. If you forgot to add the `ansible_connection: local`
variable to your `localhost` host configuration, you'll see something like
this:

{{< figure src="/media/awx-ci/job-openstack-setup-failed.png" alt="Failed OpenStack Setup job run" >}}

If all goes well, you'll have a successful job run that installs a couple of
required depencies for our upcoming job templates.

{{< figure src="/media/awx-ci/job-openstack-setup-success.png" alt="Succesful OpenStack Setup job run" >}}

### Create the virtual machine (de)provisioning jobs

Great! We know that we can run a job now. The next step is to build out two
more jobs; _virtual machine provisioning and deprovisioning_.

As before, go to _Templates_, click on _Add_, and select the _Job Template_
object. Name your job _OpenStack Provisioner_ and fill in the following fields:

* **Inventory**: Local
* **Project**: `openstack-inventory-builder`
* **Playbook**: `provision.yml`
* **Credential**: Machine: Local
* **Options**
  * **Use Fact Cache**: _enabled_

{{< figure src="/media/awx-ci/job-openstack-provisioner-config.png" alt="OpenStack Provisioner job configuration" >}}

> Now that you have the `provision.yml` playbook setup, go back to the
> _Templates_ section and do the same setup, but for the `deprovision.yml`
> playbook. We're going to make use of these in the next section.

### Creating a workflow template

With both our _OpenStack Provisioner_ and _OpenStack Deprovisioner_ jobs setup,
let's make use of them!

You may be wondering, _"How does the provisioning and deprovisioning jobs know
what virtual machines to spin up and tear down?"_. Excellent question!

If you read through the [`openstack-inventory-builder` documentation on
GitHub](https://github.com/leifmadsen/openstack-inventory-builder/blob/master/README.md#create-a-job-template)
you may notice a variable called `instance_list` that defines the virtual
machines we're going to instantiate. By using this list, we can build different
topologies using our _OpenStack Provisioner_ and _OpenStack Deprovisioner_ jobs
and defining the virtual machines we want to bring up independent of those
jobs.. By separating the `instance_list` from our (de)provisioning jobs, we can
re-use them, and build different setups!

We accomplish the different topology setup magic with a _Workflow Template_.

#### Configuring our first workflow

A workflow template is mostly a meta job that allows you to build chains of jobs
together. We're going to make use of a workflow template to build out our
environment first (create our virtual machines). Later, we'll enhance this by
using `kube-centos-ansible` to create a Kubernetes cluster across 4 virtual
machines.

To create a workflow, click on _Templates_ in the menu, click on the _Add_
button, and select the _Workflow Template_ object.

{{< figure src="/media/awx-ci/job-template-object.png" alt="Job Template object under the Add button" >}}

Just like with a regular job template, set a _Name_ (Kubernetes Workflow
Deploy), _Description_ (Deploy Kubernetes), and _Organization_ (Default).

The next part is what defines the virtual machine objects. In the _Extra
Variables_ section, create a list of virtual machines we want to spin up within
the `instance_list` variable.

```
---
instance_list:
  - { name: kube-master, group: master, security_groups: "default"}
  - { name: kube-node-1, group: nodes, security_groups: "default" }
  - { name: kube-node-2, group: nodes, security_groups: "default" }
  - { name: kube-node-3, group: nodes, security_groups: "default" }
```

Defining our `instance_list` as above will create 4 virtual machines; one
Kubernetes master, and 3 Kubernetes nodes. We'll assign the `kube-master` VM to
the `master` group, and the remaining VMs to the `nodes` group. These group
names will be used by Ansible when we run `kube-centos-ansible` to determine
how to setup the virtual machines. Additionally, we assign the `default`
security group (in OpenStack) to the virtual machines.

{{< figure src="/media/awx-ci/workflow-kube-setup.png" alt="Kubernetes workflow template configuration">}}

> **OpenStack Default Security Group**
>
> In my OpenStack project, I've defined two networks; _public_ and _internal_.
> The _public_ network is the subnet that allows me to get a floating IP for
> the virtual machine, allowing it to be accessed from the internet. The
> _internal_ network is where the virtual machines connect through a virtual
> switch, and allows all virtual machines on that broadcast domain (LAN) to speak
> with each other.
>
> For this project, I've setup my `default` security group to allow all
> connections between virtual machines on the same LAN via an Ingress rule,
> i.e. TCP/UDP, port 1-65535, 192.168.1.0/24. You may want to setup your
> security groups more restrictive. By default, the `default` configuration in
> most clouds will not be sufficient, so you'll need to adjust the security
> groups to suit your topology.

To start, you may wish to just test with a single line in the `instance_list`
instead of all four items, but suffice it to say, once you get your list the
way you want it, click the _Save_ button!

#### Building the workflow

With our workflow template initially setup, we need to load the _Workflow
Editor_ to create the actual job workflow. Click on the _Workflow Editor_ tab
and it'll open a new screen showing you a _Start_ icon in the middle of the
screen.

{{< figure src="/media/awx-ci/workflow-editor-start.png" alt="Blank workflow template configuration">}}

On the right side, we can select from one of three object types:

* Jobs
* Project Sync
* Inventory Sync

During our inventory and project configuration, we selected all the extra
options so that those objects would update when they were called by a job. If
we didn't set that up, we could have either created a period schedule to update
the projects and inventory from the cloud, or added a separate workflow step
here to perform an inventory and/or project update prior to running any jobs.

That's the great thing about workflows; they are incredibly flexible. You can
pick where in the workflow an inventory or project needs updating, run several
jobs in parallel, and control branching based on a job executing successfully
or as a failure.

For now though, we're going to keep things simple. We want to first make sure
we can create our virtual machine(s). To do this, select the _OpenStack
Provisioner_ job on the right, and click on _Select_.

{{< figure src="/media/awx-ci/workflow-openstack-added.png" alt="OpenStack provisioner added to the workflow">}}

If you hover over the _OpenStack Provisioner_ box, you'll see a `+` and an `x`
which allows you to add to the workflow, or remove a workflow item. We'll use
that when we start to build out a more elaborate setup, but for now, let's save
this and test it out.

#### Testing the workflow

Before we get too crazy and build out elaborate workflows with grace and
panache, we're going to test and make sure things are working as they should.
With our workflow template saved, naviate back to the _Templates_ page.

Like we did earlier when we tested the _OpenStack Setup_ job, click on the
rocketship icon to launch the job. Once you click on that, you'll be taken to
the following screen.

{{< figure src="/media/awx-ci/workflow-openstack-launch.png" alt="Launching our first workflow" >}}

If you click on the _Details_ link inside the workflow item box, you'll be
taken to the Ansible run console output where you can monitor the progression
of the job.

{{< figure src="/media/awx-ci/workflow-deploy.png" alt="Ansible console output of our initial workflow deployment" >}}

Ideally everything will go well for you, and we'll result in one or more
virtual machines being spun up!

# What's Next?

At this point, you could probably experiment and start building out workflows
and launching jobs. In another blog post I'll show how I chain jobs together in
workflows to build out a Kubernetes environment, schedule those for periodic
runs, and report the status of those jobs to a Slack channel.

So far, I've been pretty impressed with AWX and all the things that it does.
In an environment that requires more elaborate CI infrastructure, including a
more fluid and automated job configuration setup, AWX might not be the proper
tool. But in my simple use case of "spin up some basic CI and get back on with
it", AWX really appears to be a pretty nice little tool that can be brought up
and configured quickly so that I can get back to what I was doing.

After I got all of this configured and working as a proof of concept, I
started looking at the `tower_...` Ansible modules, which (in theory) allow me
to automate the configuration of my AWX deployment itself, which would
certainly be a win in configuration management department.

Unfortunately, the state of the `tower_...` modules does not really permit that
reality. The `tower_...` modules in the current release of Ansible only work
with `tower-cli` version `< 3.2.0` (which is used as a library to communicate
with AWX / Tower). In `tower-cli 3.2.0`, they changed from Tower API version 1
to version 2, and that broke the `tower_...` modules. Additionally, `tower-cli
3.1.8` doesn't have all of the configuration abilities that `3.2.0` has,
including ability to add an inventory source.

I'm hopeful that as more people start consuming AWX, that the Ansible modules
will catch up and things will stabilize. When that time happens, the
configuration management of AWX will be incredibly powerful, allowing for even
more elaborate scenario configurations, centrally managed. You could even
potentially run an AWX instance that managed multiple AWX instances... (insert
yo dawg joke here).

It should also be noted that the deployment of AWX I'm building on right now
isn't production ready or scalable, as it instantiates a handful of containers
on a single virtual host using Docker. Persistent storage isn't done correctly,
and a lot of things seem to be glued together in a way that isn't all that
flexible. If I was going to be using this in a long-life deployment, I'd likely
look at deploying the components into something like OpenShift, allowing
Kubernetes to manage the lifecycle of the containers, along with proper
persistent storage via GlusterFS and Heketi.

What I set out to do was to see just how crazy sauce Doug's initial idea was.
Personally, I think it looks like AWX has a role in a CI environment going
forward, but I'm more interested in what the community thinks. Leave comments
here, or reach out to me on [twitter](https://twitter.com/leifmadsen).

Happy AWXing!
