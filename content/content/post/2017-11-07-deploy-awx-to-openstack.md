+++
date = "2017-11-07T10:20:24-05:00"
title = "Deploying AWX to OpenStack RDO Cloud"
draft = false
categories = ["nfvpe","openstack","ansible"]
keywords = ["openstack","awx","ansible","tower","UI","testing","continous integration"]
description = ""

+++

Recently I've been playing around with AWX (the upstream, open source code base
of Ansible Tower), and wanted to make it easy to deploy. Standing on the
shoulders of giants (namely [@geerlingguy](https://galaxy.ansible.com/geerlingguy/))
I built out a wrapper playbook that would let me easily deploy AWX into a VM on
an OpenStack cloud (in my case, the RDO Cloud). In this blog post, I'll show
you the wrapper playbook I built, and how to consume it to deploy a development
AWX environment.
<!--more-->

## Setting Up Our OpenStack Connection

Before we get started deploying AWX, we need to make sure we can authenticate
to our OpenStack cloud, where we'll instantiate a VM and run my
[openstack-awx](https://github.com/leifmadsen/openstack-awx) playbook against.

### Setup cloud configuration

First, let's create a `clouds.yaml` configuration which contains our
authentication information. You can get most of the information you need by
downloading your OpenStack RC file, or clicking on View Credentials in Horizon
under Access & Security > API Access. You'll need to know your password as well
for your account.

Armed with this information, we can create an entry in our `clouds.yaml` file.
I'll assume we haven't set this up before, so we'll create a directory and
populate the file.

```
$ mkdir -p ~/.config/openstack/
$ cat > ~/.config/openstack/clouds.yaml <<EOF
clouds:
    rdocloud:
        auth:
            auth_url: https://phx2.cloud.rdoproject.org:13000/v2.0
            username: itsme
            password: ehrmegherdN0wa4y!
            project_name: "itsme"
```

### Install the OpenStack client

We'll also want to install the OpenStack client tools so we can validate that
we can authenticate and communicate with the OpenStack API. There are various
ways to install this, but since I'm on a Fedora desktop, the easiest thing to
do is install `python-openstackclient` from `dnf`. (Alternatively, you could
use `pip` and install `python-openstackclient` from there as well.)

```
$ sudo dnf install python-openstackclient -y
```

And we can test our connection with the `openstack` command.

```
$ openstack --os-cloud rdocloud server list
+--------------------------------------+-----------------+--------+------------------------------------------+------------+
| ID                                   | Name            | Status | Networks                                 | Image Name |
+--------------------------------------+-----------------+--------+------------------------------------------+------------+
| da9fe12c-6432-4d4d-8119-b3c59b212b98 | RDO-awx         | ACTIVE | lmadsen-int=192.168.1.70, 38.???.???.??? |            |
+--------------------------------------+-----------------+--------+------------------------------------------+------------+
```

### Setup our security groups

In order to access our web interface and API, we'll need to open a couple of
web ports. I created an `awx` security group with ports `80` and `443` open
using the `TCP` protocol (`HTTP` and `HTTPS` respectively). The playbooks we'll
use below assume that you have the `default` and `awx` security groups
available. When we instantiate the virtual machine, those 2 security groups
will be assigned to the virtual machine, and things will fail if it can't find
them.

### Install Ansible dependency `shade`

We'll also need `shade` installed so that the `os_server` module in Ansible can
communicate with the cloud. We can install with `dnf` or `pip`.

**DNF**
```
$ sudo dnf install python2-shade -y
```

**pip**
```
$ pip install --user shade
```

## Deploy AWX

Now that we know we can communicate with our OpenStack cloud, we can go ahead
and deploy AWX using my [openstack-awx wrapper
playbook](https://github.com/leifmadsen/openstack-awx), and a bunch of work
from [@geerlingguy](https://twitter.com/geerlingguy).

### Clone the wrapper playbook

You'll need `git` installed to clone my repository from GitHub. Go ahead and
fork it now and pull from your own repo if you think you might want to make
some changes in the future.

```
mkdir -p ~/src/github/leifmadsen/
cd ~/src/github/leifmadsen
git clone https://github.com/leifmadsen/openstack-awx
cd openstack-awx
```

### Download dependencies

With our wrapper playbook cloned, we need to install our dependencies. We can
do this with `ansible-galaxy`. I'll assume you've already [installed
Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html) but if
you haven't you could probably just run `sudo dnf install ansible -y`.

OK, let's install some roles from Ansible Galaxy.

```
$ ansible-galaxy install -r requirements.yml

- downloading role 'repo-epel', owned by geerlingguy
- downloading role from https://github.com/geerlingguy/ansible-role-repo-epel/archive/1.2.2.tar.gz
- extracting geerlingguy.repo-epel to /home/lmadsen/src/github/leifmadsen/openstack-awx/roles/geerlingguy.repo-epel
- geerlingguy.repo-epel (1.2.2) was installed successfully
...snipped
```

### Configure cloud variables

The next step is to configure some `cloud_...` variables that I'm using in the
`openstack.yml` playbook which are loaded via a `vars_files` (imports variables
from a file). I'm storing variables in `~/.ansible/vars/rdo_vars.yml` but you
can modify the playbook to import from whatever location you want. The idea
behind loading the file from another location is so that we're not associating
the cloud configuration directly with this playbook.

Run the following command to import the initial variables to the file.

```
$ mkdir ~/.ansible/vars/
$ cat > ~/.ansible/vars/rdo_vars.yml <<EOF
cloud_name_prefix: RDO
cloud_name: rdocloud
cloud_region_name: regionOne
cloud_availability_zone: nova
cloud_image: 42a43956-a445-47e5-89d0-593b9c7b07d0
cloud_flavor: m1.medium
cloud_key_name: lmadsen-personal
```

At this point we can break down the contents of the file.

* `cloud_name_prefix`: Prefix added to the name of the virtual machine
* `cloud_name`: Name of the cloud we're using; configured in `clouds.yaml`
* `cloud_region_name`: Region of our OpenStack project
* `cloud_availability_zone`: Zone of our OpenStack project
* `cloud_image`: The hash of the image we want to deploy. Look it up from
  Horizon. I'm using CentOS 7.3.
* `cloud_flavor`: The flavor / size of the virtual machine we're instantiating
* `cloud_key_name`: Which SSH key to use when instantiating the VM (you'll need
  to set this up too)

> **Create our SSH key and credentials in OpenStack**
>
> A little sidebar here. You can create a new SSH key with `ssh-keygen` and
> then import the SSH public key into your OpenStack project with Horizon under
> the Access & Security > Key Pairs section. Whatever you name this keypair
> should be reflected in the `cloud_key_name` variable. The SSH keypair is how
> you'll authenticate to the virtual machine. Be sure it's a key you're loading
> into your SSH agent via `ssh-add` from your client machine.

### Running the plays

We're nearing the end! To deploy our virtual machine on OpenStack and setup an
AWX development environment, we'll use Ansible to run our `site.yml` playbook.

```
$ ansible-playbook - inventory/localhost/ site.yml
```

Running the plays can take quite a while, as a virtual machine needs to be
first instantiated, followed by the installation of Docker, multiple
dependencies, building Docker images, and then starting up the containers. At
the end, you should be able to access the web interface at the floating IP of 
the virtual machine.

The default login is `admin` and `password`.

# Conclusion

You should now have a working AWX system that didn't really take all that much
work to get up and running. Again, I need to thank Jeff Geerling for his
fantastic set of playbooks that I keep coming back to and wrapping. After
all his heavy lifting, it was nearly trivial to get AWX up and running after
maybe no more than an hour of playbook writing on my part.
