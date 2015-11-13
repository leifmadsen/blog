---
author: leifmadsen
comments: true
date: 2009-07-29 12:49:51+00:00
layout: post
slug: importing-master-csv-into-mysql-cdr-table
title: Importing Master.csv into MySQL CDR table
wordpress_id: 94
categories:
- Asterisk
tags:
- Asterisk
- cdr
- database
- import
- mysql
---

> Edit: I have updated the original post, which contained 'custom' field name in the database instead of 'userfield' which is a field Asterisk-Stat uses.
> Edit2: Updated the field from 'amaflag' to 'amaflags' thanks to Justin.
> Edit3: Updated the script based on feedback from Mads Peter Nielsen and Gabriel. Thanks!

Today I had a client that had a need to run some statistical analysis on their data, but since they didn't have anything like that developed, I had to go on a search to find them something. After asking around on IRC (and pretty much knowing what the answer was already), I settled on installing the [Areski asterisk-stat](http://www.areski.net/asterisk-stat-v2/about.php) application.

> **Note:**
>
> Installing Asterisk-Stat is really quite straight forward, however, the installation documentation is not verbose. It says to modify the describe.php file, but doesn't tell you where it is. After figuring that I needed to modify my own describe.php file in the root folder, I found that it exists in the lib/ subdirectory. Hope that helps someone._

Since I had data in the Master.csv file (which is the file Asterisk writes its CDR data to by default), I just needed to import the data into a MySQL database (which I was doing because Asterisk-Stat doesn't support reading in data from a flat-file), and run my newly installed Asterisk-Stat application.

Instead of reinventing the wheel again, I figured I'd check out the various links on the [internet](http://www.wired.com/culture/lifestyle/news/2004/08/64596) for how to do it. This inevitably lead me to the [voip-info](http://www.voip-info.org) wiki, where lots of outdated, incomplete, misinformation exists. I will give credit that it gave me enough information (or links to information) to get what I needed done, but it required putting together a few pieces, and then modifying those pieces.

OK, time to get off my soap box and give you what you really want. And really, I can't yell at it too much -- I did eventually end up with what I needed!

First, I copied the Master.csv from /var/log/asterisk/cdr-csv/ into a temporary working directory. This way I wasn't messing around with the customers live data. Also note, this is a one time import, and will eventually need to move them over to writing their data to the database directly, but that is another article.

So now that I have my working copy of Master.csv, it's time to create the database, and import the data. I started by first installing the various applications I needed: httpd (apache), php, php-mysql, gd, and mysql-server. I then configured the database with a user login (so I didn't need to modify as root), and created a database to put Asterisk related data into.

```
# mysql -u root -p
mysql> create database asterisk;
mysql> GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'localhost' IDENTIFIED BY 'somemagicpassword';
mysql> flush privileges;
```

OK awesome, I have now created my database, and have the 'asterisk' user assigned to it. Now lets create our 'cdr' table. Note that the following table description was taken from [this page](http://www.voip-info.org/wiki/view/Asterisk+CDR+csv+conversion+mysql). It was the table description I found which contained the appropriate number of columns to match up with *my* Master.csv file, and which the column names matched up with the data. Your mileage may vary based on Asterisk version (note I'm using a 1.4 based version of Asterisk). Run the following from the MySQL command prompt.

```sql
create table cdr (
       accountcode varchar (30),
       src varchar(64),
       dst varchar(64),
       dcontext varchar(32),
       clid varchar(32),
       channel varchar(32),
       dstchannel varchar(32),
       lastapp varchar(32),
       lastdata varchar(64),
       calldate timestamp NOT NULL,
       answerdate timestamp NOT NULL,
       hangupdate timestamp NOT NULL,
       duration int(8) unsigned default NULL,
       billsec int(8) unsigned default NULL,
       disposition varchar(32),
       amaflags varchar(128),
       uniqueid varchar(128),
       userfield varchar(128),
       PRIMARY KEY (clid,channel,calldate,uniqueid)
);
```

Now that we have a table to import the data into, I had to find a script that would work. I found one originally, then realized it didn't import the data as I needed it (oops, my bad for not looking carefully enough at the table structure), so I modified it to work with my table structure. The script was originally created by John Lange (thanks John!), and you can find it on [his blog](http://www.johnlange.ca/tech-tips/asterisk/asterisk-cdr-csv-mysql-import-v20/). Find below my modified version of his script to work with the above mentioned CDR table layout.

```php
<?php
/*** process asterisk cdr file (Master.csv) insert usage
* values into a mysql database which is created for use
* with the Asterisk_addons cdr_addon_mysql.so
* The script will only insert NEW records so it is safe
* to run on the same log over-and-over.
*
* Author: John Lange (john@johnlange.ca)
* Date: Version 2 Released July 8, 2008
*
* Here is what the script does:
*
* Parse each row from the text log and insert it into the database after testing for a
* matching "calldate, src, duration" record in the database. Note that not all fields are
* tested.
*
* If you have a large existing database it is recommended that you add an index to the calldate
* field which will greatly speed up this import.
*
*/
/*
 * Modified by Leif Madsen, July 29, 2009 to add additional columns.
 * Original post and code by John Lange: http://www.johnlange.ca/tech-tips/asterisk/asterisk-cdr-csv-mysql-import-v20/
 */
$locale_db_host = 'localhost';
$locale_db_name = 'asterisk';
$locale_db_login = 'asterisk';
$locale_db_pass = 'somemagicpassword';
if($argc == 2) {
$logfile = $argv[1];
} else {
print("Usage ".$argv[0]." <filename>\n");
print("Where filename is the path to the Asterisk csv file to import (Master.csv)\n");
print("This script is safe to run multiple times on a growing log file as it only imports records that are newer than the database\n");
exit(0);
}
// connect to db
$linkmb = mysql_connect($locale_db_host, $locale_db_login, $locale_db_pass) or die("Could not connect : " . mysql_error());
mysql_select_db($locale_db_name, $linkmb) or die("Could not select database $locale_db_name");
//** 1) Find records in the asterisk log file. **
$rows = 0;
$handle = fopen($logfile, "r");
while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
// NOTE: the fields in Master.csv can vary. This should work by default on all installations but you may have to edit the next line to match your configuration
list($accountcode,$src, $dst, $dcontext, $clid, $channel, $dstchannel, $lastapp, $lastdata, $start, $answer, $end, $duration, $billsec, $disposition, $amaflags, $uniqueid, $userfield ) = $data;
/** 2) Test to see if the entry is unique **/
$sql="SELECT calldate, src, duration".
" FROM cdr".
" WHERE calldate='$start'".
" AND src='$src'".
" AND duration='$duration'".
" LIMIT 1";
if(!($result = mysql_query($sql, $linkmb))) {
print("Invalid query: " . mysql_error()."\n");
print("SQL: $sql\n");
die();
}
if(mysql_num_rows($result) == 0) { // we found a new record so add it to the DB
// 3) insert each row in the database
$sql = "INSERT INTO cdr (calldate, answerdate, hangupdate, clid, src, dst, dcontext, channel, dstchannel, lastapp, lastdata, duration, billsec, disposition, amaflags, accountcode, uniqueid, userfield) VALUES('$start', '$answer', '$end', '".mysql_real_escape_string($clid)."', '$src', '$dst', '$dcontext', '$channel', '$dstchannel', '$lastapp', '$lastdata', '$duration', '$billsec', '$disposition', '$amaflags', '$accountcode', '$uniqueid', '$userfield')";
if(!($result2 = mysql_query($sql, $linkmb))) {
print("Invalid query: " . mysql_error()."\n");
print("SQL: $sql\n");
die();
}
print("Inserted: $end $src $duration\n");
$rows++;
} else {
print("Not unique: $end $src $duration\n");
}
}
fclose($handle);
print("$rows imported\n");
?>
```

Now all that is left to do is import the data!

```bash
# php importcdr.php Master.csv
```
