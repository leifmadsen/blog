---
author: leifmadsen
comments: true
date: 2009-08-04 17:57:11+00:00
layout: post
slug: consuming-soap-complextype-webservice-with-php
title: Consuming SOAP complexType webservice with PHP
wordpress_id: 117
categories:
- Programming
tags:
- code
- complextype
- php
- soap
- webservice
- xml
---

I recently had a client request that I communicate with a webservice via SOAP in order to do some credit card authorization for an Asterisk project they were implementing. After a couple of days of reading several posts I found via Google (which funny enough weren't exactly what I was looking for, but gave me JUST enough information to finally start putting it all together), I had something that worked.

In order to potentially save someone the hassle of having to figure out how to consume a complexType in SOAP via PHP (and not using NuSoap as many of the posts pointed out), I'm writing this down. As with many of my posts, there is probably just enough information here that will be useful for me in the future should I need to do this again. If this helps someone else out, then great!

> **Note:**
>
> I am not a programmer. What I'm showing may be entirely the WRONG approach to solving this issue, but it solves it for me. Feel free to provide better examples by commenting on this article. In addition, there is the potential I may be using the wrong terminology. Please feel free to correct me, and I will then update the article to reflect anything deemed to be incorrect._

First, you need to install the php-soap module for your PHP installation. This could require you to recompile PHP with SOAP support, or if you're using a package based distro (like me), you may just need to do something like:

```# yum install php-soap```

In order to give you just enough of a reference point to figure out what I'm trying to do here, the following snippet of XML code is from the webservice I'm trying to consume. It is the complextype which I need to perform request against, and defines how the object should be passed. I'll then show the result. This is *not* the entire WSDL.

First we're looking at the element named 'Purchase'. This element contains a complexType object named _oPurchaseRequest_ and receives a request of the type _PurchaseRequestType_.

```xml
<s:element name="Purchase">
 <s:complexType>
   <s:sequence>
     <s:element minOccurs="0" maxOccurs="1" name="oPurchaseRequest" type="tns:PurchaseRequestType"/>
   </s:sequence>
 </s:complexType>
</s:element>
```

The structure of the PurchaseRequestType is as follows. This is how we need to structure our complexType.

```xml
<s:complexType name="PurchaseRequestType">
 <s:sequence>
   <s:element minOccurs="0" maxOccurs="1" name="MembershipNumber" type="s:string"/>
   <s:element minOccurs="0" maxOccurs="1" name="SessionID" type="s:string"/>
   <s:element minOccurs="0" maxOccurs="1" name="Password" type="s:string"/>
   <s:element minOccurs="0" maxOccurs="1" name="Gender" type="s:string"/>
   <s:element minOccurs="1" maxOccurs="1" name="RatePlanID" type="s:int"/>
   <s:element minOccurs="0" maxOccurs="1" name="CCNumber" type="s:string"/>
   <s:element minOccurs="1" maxOccurs="1" name="CCExpireMonth" type="s:int"/>
   <s:element minOccurs="1" maxOccurs="1" name="CCExpireYear" type="s:int"/>
   <s:element minOccurs="1" maxOccurs="1" name="CCCode" type="s:int"/>
   <s:element minOccurs="1" maxOccurs="1" name="Zip" type="s:int"/>
  </s:sequence>
 </s:complexType>
```

The magic really happens in the following code. It is how I built the object in order to be consumed by the webservice. It works by first creating a new standard class, and then creating another standard class inside the oPurchaseRequest object (which is the name of the complexType that the Purchase element is expecting). Then you build the oPurchaseRequest by adding the elements outlined by the PurchaseRequestType complexType, and assigning values to them.

```php
$search_query = new StdClass();
$search_query->oPurchaseRequest = new StdClass();
$search_query->oPurchaseRequest->MembershipNumber = $MembershipNumber;
$search_query->oPurchaseRequest->SessionID = $SessionID;
$search_query->oPurchaseRequest->Password = $Password;
$search_query->oPurchaseRequest->Gender = $Gender;
$search_query->oPurchaseRequest->RatePlanID = $RatePlanID;
$search_query->oPurchaseRequest->CCNumber = $CCNumber;
$search_query->oPurchaseRequest->CCExpireMonth = $CCExpireMonth;
$search_query->oPurchaseRequest->CCExpireYear = $CCExpireYear;
$search_query->oPurchaseRequest->CCCode = $CCCode;
$search_query->oPurchaseRequest->Zip = $Zip;
```

The entire snippet of code is available below.

```php
// We can take in our arguments from the console if we're using PHP CLI
$MembershipNumber = $argv[1];
$SessionID = $argv[2];
$Password = $argv[3];
$Gender = $argv[4];
$RatePlanID = $argv[5];
$CCNumber = $argv[6];
$CCExpireMonth = $argv[7];
$CCExpireYear = $argv[8];
$CCCode = $argv[9];
$Zip = $argv[10];

// Create the object we'll pass back over the SOAP interface. This is the MAGIC!
$search_query = new StdClass();
$search_query->oPurchaseRequest = new StdClass();
$search_query->oPurchaseRequest->MembershipNumber = $MembershipNumber;
$search_query->oPurchaseRequest->SessionID = $SessionID;
$search_query->oPurchaseRequest->Password = $Password;
$search_query->oPurchaseRequest->Gender = $Gender;
$search_query->oPurchaseRequest->RatePlanID = $RatePlanID;
$search_query->oPurchaseRequest->CCNumber = $CCNumber;
$search_query->oPurchaseRequest->CCExpireMonth = $CCExpireMonth;
$search_query->oPurchaseRequest->CCExpireYear = $CCExpireYear;
$search_query->oPurchaseRequest->CCCode = $CCCode;
$search_query->oPurchaseRequest->Zip = $Zip;

// setup some SOAP options
echo "Setting up SOAP options\n";
$soap_options = array(
        'trace'       => 1,     // traces let us look at the actual SOAP messages later
        'exceptions'  => 1 );


// configure our WSDL location
echo "Configuring WSDL\n";
$wsdl = "https://locationofservices.tld/asterisk.asmx?WSDL";


// Make sure the PHP-Soap module is installed
echo "Checking SoapClient exists\n";
if (!class_exists('SoapClient'))
{
        die ("You haven't installed the PHP-Soap module.");
}

// we use the WSDL file to create a connection to the web service
echo "Creating webservice connection to $wsdl\n";
$webservice = new SoapClient($wsdl,$soap_options);

echo "Attempting Purchase\n";
try {
        $result = $webservice->Purchase($search_query);

        // save our results to some variables
        $TransactionID = $result->PurchaseResult->TransactionID;
        $ResponseCode = $result->PurchaseResult->ResponseCode;
        $ResponseDetail = $result->PurchaseResult->ResponseDetail;
        $AddMinutes = $result->PurchaseResult->AddMinutes;

        // perform some logic, output the data to Asterisk, or whatever you want to do with it.

} catch (SOAPFault $f) {
        // handle the fault here
}

echo "Script complete\n\n";
```

You'll notice that our results are passed back in the 'try' statement. We assign the values passed back to some variables we could use. The layout of the result is similar to the request. It is laid out as follows in the WSDL.

```php
<s:element name="PurchaseResponse">
 <s:complexType>
  <s:sequence>
   <s:element minOccurs="0" maxOccurs="1" name="PurchaseResult" type="tns:PurchaseResponseType"/>
  </s:sequence>
 </s:complexType>
</s:element>

<s:complexType name="PurchaseResponseType">
 <s:sequence>
  <s:element minOccurs="0" maxOccurs="1" name="TransactionID" type="s:string"/>
  <s:element minOccurs="1" maxOccurs="1" name="ResponseCode" type="tns:ResponseCodes"/>
  <s:element minOccurs="0" maxOccurs="1" name="ResponseDetail" type="s:string"/>
  <s:element minOccurs="1" maxOccurs="1" name="AddMinutes" type="s:int"/>
 </s:sequence>
</s:complexType>
```

Hope that helps!
