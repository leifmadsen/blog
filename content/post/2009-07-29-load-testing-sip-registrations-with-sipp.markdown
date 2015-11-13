---
author: leifmadsen
comments: true
date: 2009-07-29 16:34:49+00:00
layout: post
slug: load-testing-sip-registrations-with-sipp
title: Load testing SIP registrations with SIPp
wordpress_id: 111
categories:
- Asterisk
tags:
- Asterisk
- load testing
- registration
- sip
- sipp
---

Today I had a need to go and load a bunch of registrations into Asterisk for a bug I was working on. Since I've had this need a couple of times now, and I keep going and having to redevelop it, I think I'll just write about it here, and then when I need it again, I can just look it up. Maybe this will be useful for someone else as well.

First of all, this is all based on the post I found on the SipX wiki. You can read the page I based this all off of [here](http://sipx-wiki.calivia.com/index.php/Using_SIPp_to_run_performance_tests). Lots of good info there. All I'm really adding of value is the PHP scripts I used to generate the peers in the database, and the register_client.csv file.

First, lets load a bunch of peers into Asterisk. I'm loading peers numbered 101 --> 199.

```php
<?php

if (!$link = mysql_connect('localhost','asterisk','asterisk')) {
	echo "Could not connect\n";
	die(mysql_error());
}

if (!mysql_select_db('asterisk',$link)) {
	echo "Could not get into database\n";
	die(mysql_error());
}

for($counter = 100; $counter <= 199; $counter++) {
	$sql = "INSERT INTO sipfriends (type,name,username,secret,context,canreinvite,nat,host,mailbox,dtmfmode,disallow,allow) VALUES ('friend','$counter','$counter','welcome','start','no','yes','dynamic','$counter@default','rfc2833','all','ulaw')";
	echo $sql."\n";
	$result = mysql_query($sql,$link);
	if (!$result) {
		echo "DB error " . mysql_error();
		exit;
	}
}

mysql_close($link);

?>
```

Next, we need to generate the register_client.csv file in order to tell SIPp which peers to authenticate, and how.

```php
<?php

$myFile = "register_client.csv";
$fh = fopen($myFile, w);

for ($counter = 100; $counter <= 199; $counter++) {
	$data = "$counter;example.com;[authentication username=$counter password=welcome];\n";
	fwrite($fh, $data);
}

fclose($fh);

?>
```


And finally, here is the line used to send a bunch of registrations to Asterisk. If you want to do a load test, you may need to adjust the numbers so it does a better job of "blasting" the end point you want to test.

```bash
sipp -sf register_client.xml -inf register_client.csv -r 10 -trace_err -trace_stat -nd -fd 1 -i  
```

If you have any questions, just ask, and I'll try to comment here. This post is potentially light on specifics since these are notes for my future reference.
