---
author: leifmadsen
comments: true
date: 2011-02-27 21:57:41+00:00
layout: post
slug: using-exec-to-set-externaddr-in-sip-conf
title: 'Using #exec to set externaddr in sip.conf'
wordpress_id: 286
categories:
- Asterisk
tags:
- '#exec'
- Asterisk
- curl
- php
- recipe
- scripts
- sip.conf
---

Today I was working on a system, and knowing that the system is going to get moved, and that often one of the things forgotten is to update the **externaddr=** option in _sip.conf_ (when Asterisk is sitting behind NAT), I decided to put together a little script that returns the external IP address of the system. Using this script along with an **#exec** in the _sip.conf_ file will make it so the address gets updated when the system is moved to the new physical location. I used the _php5-curl_ package on Ubuntu. I used the example from this page for cURL: [http://www.php.net/manual/en/curl.examples-basic.php](http://www.php.net/manual/en/curl.examples-basic.php)

Here is the PHP script:

```php
#!/usr/bin/php
<?php

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://getip.krisk.org");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$output = curl_exec($ch);
curl_close($ch);

echo "externaddr=".$output."\n";

?>
```

And the Asterisk configuration required _asterisk.conf_ to be modified. Enable the _execincludes=yes_ option, and then add the following to the **[general]** section of _sip.conf_.

```bash
#exec /etc/asterisk/scripts/set_externaddr.php
```
