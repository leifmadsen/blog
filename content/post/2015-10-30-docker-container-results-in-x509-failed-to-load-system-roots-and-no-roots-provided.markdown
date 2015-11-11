+++
author = "leifmadsen"
date = "2015-10-30 20:30:27+00:00"
excerpt = "How to resolve x509 failed to load system roots in a Docker container when connecting to an HTTPS fronted API."
slug = "docker-container-results-in-x509-failed-to-load-system-roots-and-no-roots-provided"
title = 'Docker container results in x509: failed to load system roots and no roots provided'
categories = ["Asterisk","DevOps","Docker"]
keywords = ["api", "Asterisk","containers","docker","https","proxy"]

+++

We have a small system running in AWS as a CentOS 7 image. It has a few containers that we're using to host a few Golang API proxies. We migrated a customers API proxy that was running on the local VM into a container, and spun it up. Upon testing, we ran into the following error:

```
x509: failed to load system roots and no roots provided
```

We get that failure when trying to connect to an HTTPS endpoint (remote API that we're proxying to Asterisk).

Figured it had to do with the fact we were using a scratch disk to build the container image, and that there were no certs loaded. Did some Googling and found some people with similar problems, but their solutions didn't work for us on our CentOS 7 host system.

Then I thought maybe there was some issue with following a symlink as the source since we were loading in the `ca-bundle.crt` file as a volume. I didn't test enough to determine if that was the issue (it probably wasn't), but this post gave me a hint:

[https://github.com/docker/docker/issues/5157#issuecomment-69325677](https://github.com/docker/docker/issues/5157#issuecomment-69325677)

So we did the following:

```
docker run -d -p 8085:8085 -v /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:/etc/ssl/certs/ca-certificates.crt [etc...]
```

After linking that file and mounting it in the container, all was well. I suspect it's the path to the `ca-certificates.crt` that was the real trick.
