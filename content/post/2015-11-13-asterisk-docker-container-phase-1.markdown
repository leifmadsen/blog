+++
categories = ["asterisk","docker","rpm","automation"]
date = "2015-11-10T19:41:55-05:00"
description = ""
keywords = ["asterisk","docker","rpms","automation"]
title = "Asterisk Docker Container: Phase 1"

+++
## AstriCon
At AstriCon 2015 this year, there was a lot (and I mean a lot) of discussion
around microservices (Docker), and what effort is required over the next year
by the development community in order to make Asterisk better suited to running
in that environment.

One of the first things is, clearly, to have a container image that Asterisk
runs in. I've done this a few times now, but having something that can be
passed over to the official Asterisk Git repository, and which everyone can
contribute to, utilize and play with would be the goal here. The community is
already pretty fragmented, and there are a bunch of useful, but unofficial
images, and I don't think any of them have become the defacto image.

## The Problem; Reproducibility
Part of the problem is really around packages. Digium does release some
official Asterisk packages, but it's not automated. Another interesting tidbit
that came out of AstriDevCon is that no one really uses packages.

Let me elaborate on what I mean by that. Steve Sokol actually made that
statement, and at first I was shocked. As he talked a bit more, there was a bit
of an a-ha moment, so let me try and distill it. Remember that we're in a room
of developers and highly skillful integrators. When Steve said, "no one uses
packages", he was referring to a poll that was done of developers and
integrators, and asking if they deploy their systems to customers using the
defacto packages that are provided with the various distributions.

The issue isn't that we don't have access to packages, but that the packages we
do have access to don't contain the various bits of custom code that developers
and highly skilled integrators tend to absorb and deploy. So what ultimately
happens is that code gets compiled on the system with the changes, and away
everyone goes.

Of course these same people are more than intelligent enough to handle their
own packaging. The issue tends to be that creating your own packages and
managing them is a bit of a pain in the ass. It's extra overhead that never
seems to ultimately bubble up to a high enough priority to solve (in many
cases). No one likes shaving yaks to get their work done.

So with that sidebar out of the way, let me ask a question: how does building
an "official" Docker image solve any of that? The answer is, it doesn't. We end
up in the exact same situation, with everyone having their own Docker images
and their own Dockerfile that as borrowed from someone else, and we end up with
community fragmentation.

## Approaching A Solution
I think there is a solution here though. Docker makes the building of utility
services significantly easier than someone having to install applications, spin
up the corresponding services, configure them, and ultimately host them on
their infrastructure. And we're not even talking yet about people who run
Ubuntu vs CentOS vs Debian vs Mint vs... Gentoo?

However, the underlying distribution in a Docker-based infrastructure becomes
much less of a concern. We have these nice abstraction points called
"containers" :) With the framework of a single container, the distribution can
be one type, and it can interact with other containers that are other
distribution types through things like volumes, networking, etc. We can also
distribute portions of the infrastructure into nice little container images
with minimal setup time for the infrastructure owner.

With one or more containers, we can easily distribute the functionality that
would normally be maintained by each person locally, and make the maintenance
of that functionality a bit more centralized through the distribution of
containers for each of those purposes. Then the only real documentation should
be how to use the containers to achieve the same goals as would be done in a
virtual machine installation. Ideally with significantly less investment of
time as well.

The goal then here, is to create a foundation that allows the building of
Asterisk and distributing it via a container image relatively simple. We can
then avoid any centralized infrastructure spin up that needs to be owned by a
single organization or individual, allowing collaboration across organizations
and developers, and also allowing everyone to have a slightly tweaked
deployment without the overhead of maintaining the entire stack.

## A Draft Solution
With that in mind, we also want people to have access to an Asterisk container
image that they can use, but with the ability to rebuild it locally if need be,
without having to setup a ton of infrastructure to do it. As a first step, it
would be ideal to just have something that is reproducible.

The simplest solution is really just to build Asterisk from source that is
mounted via volume into the container during build. While this definitely
solves multple problems, it provides its own set of obstacles. Primarily that
it results in a large number of dependencies built into the container which
results in a large container image.

> **NOTE**: There are ways around this, but it kind of breaks the simplicity of
> the `Dockerfile` when you break out information into external scripts.
> Externalizing everything also breaks the readability of the container build
> itself when you do a `docker inspect`.

The best way of building the Asterisk container image is to use packages, since
that doesn't increase the size of the distributed container image. It also
keeps the `Dockerfile` readable and a single layer of information. But now
we're right back to our "building packages is hard" issue. Luckily with Docker
we can make this a significantly more appealing a process.

> **NOTE**: Since I started working on this, Alan Graham posted some links to
> RPM building containers which might also be useful for this. I'm currently
> approaching this slightly differently, but there may be an opportunity to
> circle back around and see how these images could also be used to solve the
> problem:
>
> * https://github.com/alanfranz/docker-rpm-builder
> * https://github.com/alanfranz/fpm-within-docker

In my first approach, I didn't want to rewrite all the SPEC file madness for
Asterisk. That's a big job. I've previously built RPMs for Asterisk (many
times) using the [asterisk.spec
file](http://pkgs.fedoraproject.org/cgit/asterisk.git/) from the Fedora
project. It's a great starting point, and usually with some mild tweaking I can
get what I want out of it. The most typical thing I do is add my own custom
changes to the `.spec` file, change versions, maintainer, etc and then build
the RPMs with [mock](https://fedoraproject.org/wiki/Mock). This is better than
having a dependent VM or something for building the RPMs, but it still requires
knowledge of using `mock` and then of course modifying the `spec` files in the
first place. You also need to have a Fedora or CentOS machine to work on.

We can simplify this with a Docker container image that builds the RPMs for us.
I did that here: [asterisk-docker-builder version
0.1](https://github.com/leifmadsen/asterisk-docker-builder/tree/0.1)

The solution I took was to reuse some of the RPM building tools supplied by the
Fedora project. Using `fedpkg` I could generate the dependencies I required,
load them into a local repo, and use that to step through the dependency stack.
With the `.spec` files already created, there wasn't much extra work to do
since I could install dependencies with `yum-builddep` and then use
`createrepo` to build a local RPM repository that could host the dependencies
not available from upstream CentOS.

You can see that I somewhat break my own rule and use a `buildit.sh` script,
but since this was just for the RPM builder, I let it slide for now. The
resulting RPMs are then used during the build process for the Asterisk
container image. This results in a huge savings of space; with the compiled
version of the Docker image, the size was 1.6GB, but with RPMs, it is closer to
500MB.

## Outstanding Issues
I consider the solution I've been working on far from complete. In this blog
post I also don't get into how I solved all the little things, and how to use
the images (I think I did a decent version of that in the `README.md` file
within the Github repo). Here are a few of the problems yet to be solved:

1. dependency on the upstream `spec` file from Fedora
2. dependency on `fedpkg`
3. inability to build packages easily from local source

Let me break down a bit further why the above are issues.

### Dependency on upstream `spec`
When we rely on the upstream `spec` file, we're not really a lot further ahead.
Sure we have the ability to reproduce builds pretty easily, but to a certain
degree we're stuck with whatever version is being packaged upstream. The file
not being local makes it difficult to manage, so we're kind of back to building
packages ourselves.

### Dependency on `fedpkg`
A dependency on `fedpkg` is actually a nice thing to a certain degree, but
doesn't solve all our "build from local source" problems. With `fedpkg` the
default is to grab the `spec` file and sources from a server hosted via Fedora
itself (thus we're) building the same RPMs that Fedora ships with their
systems), but there is an override configuration file we can use. With the
override configuration file, we could actually point at our own `spec` file
hosted in `git` and also point at our own `sources` location, where our own
tarball of Asterisk resides (with our own changes).

Of course this goes back to having to deploy our own infrastructure to support
building packages. It's not ideal, but it's definitely much less than normal. I
think there are things we can do with companion containers though to make this
much more flexible. There might be other tools that are even better than
`fedpkg` to make the building simpler.

### Inability to build from local source
Right now we technically could build packages using the `fedpkg.conf` overrides
and point it at some other infrastructure (either self-hosted, or supplied via
companion containers). The primary issue is if you wanted to build a
development container for testing some code directly from your local source
directory without all the extra work of building tarballs, uploading them to a
remote server, and updating a `spec` file, you're kind of out of luck.

## Next Steps
I think at this point some additional work could be done here to make this all
a little less difficult. For example the usage of
[FPM](https://github.com/jordansissel/fpm) within a companion container could
make the creation of the packages much simpler. If that approach succeeds then
we skip a lot of the overhead of having to maintain `spec` files, outside
infrastructure to make the files available to `fedpkg` and a few other things
that make building packages annoying. It's not clear yet whether FPM really
works well for complex applications like Asterisk that have multiple outside
dependencies, but it's worth a look.

The other approach I've been thinking about is to have a `spec` file per
Asterisk version supplied directly with Asterisk, which makes the editing of
the file locally probably a lot simpler since it'll be tied to your base
version of Asterisk. From there you simply need to add any extra modules /
files that you're adding to the Asterisk source code. If changes only happen in
existing file, then there should be no need to change the file at all, other
than maybe a build flag change (which you might be able to pass in with an
`ENV` variable).

To solve the issue with building a package from the local source, we could
volume mount the working directory or Asterisk code back into the container
during the `docker run` and `tar` the source up, place the resulting archive
into a particular directory, update the signature file, and create a new RPM.
Building your own local Asterisk container then would be relatively straight
forward.

## Conclusion
I know this has been a lengthy post, but I wanted to get all the background
fleshed out so that anyone wanting to jump into this had the prerequisite
information. I have some approaches I'm going to attempt moving forward with
(likely FPM to start, since I think that creates a simple avenue if it works
out), but anyone who wanted to assist with this is more than welcome to get
with me, and provide some other information.

Maybe there are some simple tweaks I'm not seeing, or some other problem to be
solved that I haven't run into yet. The goal here is to get the requisite
`Dockerfile` or files into the Asterisk repository, add some documentation and
make it simple for people to build their own Asterisk containers with their
source. Of course if all you need is a vanilla Asterisk container right now,
I'm already hosting one from the resulting RPMs built by the Fedora projects
`spec` and `fedpkg` at the [Docker
Hub](https://hub.docker.com/r/leifmadsen/asterisk/) under my repository.
