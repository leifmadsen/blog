---
author: leifmadsen
comments: true
date: 2009-08-27 14:02:24+00:00
layout: post
slug: creating-vcards-with-qr-codes
title: Creating vCards with QR Codes
wordpress_id: 127
categories:
- Technology
tags:
- datamatrix
- qr code
- semacode
- vcard
---

Recently I've been noticing a lot more use of QR codes around the internet. A QR code is those 2D matrices that look like a bar code, but aren't just the ordinary vertical lines that you would see on your box of cereal. These are a box that contain pixels that have been coded to contain information about pretty much anything. I've been seeing some people using them for contact information, web links, and pretty much anything you can think of to distribute information. 

I also recently saw a show on Discovery where in Japan people will post these large images on a wall somewhere hoping people will scan them with their cell phones, thereby visiting a site of a product, or perhaps giving information about an upcoming show.

These codes can then be scanned by an application on your cell phone which then displays the data for you. On my Nokia E71, if I scan in a QR code which is in the format of a vCard, then my phone will recognize that, and let me save the contact information to my phone book. How cool is that!

I figured it'd be neat to build a vCard (which is a standard format that can be used by cell phones to distribute contact information so you can easily add it to your phone book), so I went looking on the internet for some free QR code generators, specifically for vCards. I was somewhat disappointed because all the vCard generators seemed to be missing a field for a SIP URI, which I wanted to add. So I ended up using Wikipedia to find the standard vCard format, and then noticed I just needed to add the X-SIP field to my vCard information, and voila, I had the field I wanted!

If you want to generate a vCard as well, you can use the [http://www.invx.com](http://www.invx.com) website. I found it the most forgiving, and generated the best QR codes. Additionally, it generates a semacode at the same time if you're looking for that kind of thing :)

Here is the result of my internet scouring for QR code data generators. If you wanna try it out, feel free to scan with your cell phone and add my contact details to your cell phone! If you don't have a bar code scanner for your cell phone, then there are several that you can find on the Internet. I tried one from [http://www.i-nigma.com](http://www.i-nigma.com) which seemed to work pretty well. I have one that comes with my cell phone anyways, which I actually liked quite a bit, so I'm just using that, but thought I'd try something else just for fun. You can also install it from you cell phone by visiting [http://www.i-nigma.mobi](http://www.i-nigma.mobi).

NOTE: At some point you can only encode so much information into the graphic because the cell phone seems to get confused. For example, the image I'm generating below seems to be pretty much at the limit that my cell phone will easily pick up. It seems to be the more data you encode, the less likely your cell is to pick it up on the first try.

![](http://leifmadsen.com/sites/default/files/qr-code-vcard3.0.png)

_Update (2011/04/11): This is the most popular post I've ever written it seems, and it blows the other posts out of the water in terms of constant views. It seems that QR Codes are very popular now and will continue to do so. Blackberry users have a QR Code for adding accounts to the BBM, most products now contain a small QR Code which matches the barcode, and we're seeing QR codes on business cards, and in random spots for advertising which get people to a webpage. The latest edition to the web is Kimtag which is a QR code that takes you to a webpage that contains all a persons contact information and social media links. Here is mine:_

[![QR Code for leifmadsen at Kimtag](http://ix.kimtag.com/leifmadsen_qrs.png)](http://kimtag.com/leifmadsen)

_Update (2011/04/12): Been doing more research as to how to get contacts into my Blackberry, and it seems the best way is to really just create a QRCode that goes to an external site and then provides the vCard that way. Below is a graphic I generated at [http://qrcode.offermobi.com/qrgen/vcard/](http://qrcode.offermobi.com/qrgen/vcard/) which seems to work quite well. The advantage is you can use the QRcode scanner in the BBM application. (I tried it on a recent version of BBM using the 'Scan a Group Barcode' option.) Enjoy!_

![](http://qrcode.offermobi.com/images/barcodes/vcard/1/164-1302631602.gif)
