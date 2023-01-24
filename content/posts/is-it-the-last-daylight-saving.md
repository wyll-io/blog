---
title: "Is it the last daylight saving ?"
date: 2023-01-24
tags: ["linux", "time", "reverse"]
author: "François ALLAIS"
draft: true
---

In France, discussions are going well regarding the change of summer and winter time ! Let's go further in this article..
<!--more-->

There is always someone to say that this year is the last time we change the clock : `They want to keep the summer time forever`.

# How computer science sees it

From the computer science point of view, the daylight savings are a matter of **time**, and time is the most important thing for a computer. Think about all the servers that performs actions and needs to do it at the right moment.

## TZDATA

Timezones are handled by a package called `tzdata`, the code source can be found here : `https://salsa.debian.org/glibc-team/tzdata`. Basically this package holds all the rules for all countries in the world in what we call timesone databases.

You can clone it if you want to see what is under the scenes :

```
c:\dev\src>git clone https://salsa.debian.org/glibc-team/tzdata
Cloning into 'tzdata'...
warning: redirecting to https://salsa.debian.org/glibc-team/tzdata.git/
remote: Enumerating objects: 5983, done.
remote: Counting objects: 100% (1365/1365), done.
remote: Compressing objects: 100% (394/394), done.
remote: Total 5983 (delta 845), reused 1275 (delta 772), pack-reused 4618
Receiving objects: 100% (5983/5983), 3.24 MiB | 2.62 MiB/s, done.
Resolving deltas: 100% (3675/3675), done.

c:\dev\src>cd tzdata

c:\dev\src\tzdata>
```

In the folder you can find a file for each zone of the world, if you open the one nammed `europe`, you can see all the rule for the European continent. The file is a bit huge so you can go directly to [line 571](https://salsa.debian.org/glibc-team/tzdata/-/blob/sid/europe#L571) to see the rule that manage the France.

The file explains that the rule for France is the rule of Europe as its belongs to European commission. We can see it here :

```
# Zone	NAME		STDOFF	RULES	FORMAT	[UNTIL]
Zone	Europe/Paris	0:09:21 -	LMT	1891 Mar 16
			0:09:21	-	PMT	1911 Mar 11 # Paris Mean Time
# Shanks & Pottenger give 1940 Jun 14 0:00; go with Excoffier and Le Corre.
			0:00	France	WE%sT	1940 Jun 14 23:00
# Le Corre says Paris stuck with occupied-France time after the liberation;
# go with Shanks & Pottenger.
			1:00	C-Eur	CE%sT	1944 Aug 25
			0:00	France	WE%sT	1945 Sep 16  3:00
			1:00	France	CE%sT	1977
			1:00	EU	CE%sT
```

The last line is the one that is active today, it basically says that the summer time `saves one hour` and refers to the rule called `EU`. The formatted timezone name is `CET` with an optional caracter (we will see it below).  
Let's find the `EU rule`, it is here :

```
# Rule	NAME	FROM	TO	-	IN	ON	AT	SAVE	LETTER/S
Rule	EU	1977	1980	-	Apr	Sun>=1	 1:00u	1:00	S
Rule	EU	1977	only	-	Sep	lastSun	 1:00u	0	-
Rule	EU	1978	only	-	Oct	 1	 1:00u	0	-
Rule	EU	1979	1995	-	Sep	lastSun	 1:00u	0	-
Rule	EU	1981	max	-	Mar	lastSun	 1:00u	1:00	S
Rule	EU	1996	max	-	Oct	lastSun	 1:00u	0	-
```

Let's take a look at the two last lines :

 - `Rule	EU	1981	max	-	Mar	lastSun	 1:00u	1:00	S` : starting from the year 1981, the summer time is applied at the **last sunday of March**. We can also see that it append the letter `S` (for summer) that will be used for the formating.
 - `Rule	EU	1996	max	-	Oct	lastSun	 1:00u	0	` : the winter time has been last decide from 1996, it happens the **last sunday of October**.

If you are a history lover, you can read the whole part of the file for France and Europe, all the time changes are written. Great work !

## Rules compilation

When you install `tzdata`, under the hood it is compiling the rules with the `zic` utility, an other Linux package. This is done at this line of the file `tzdata/debian/rules`

```
# Build the timezone data
	/usr/sbin/zic -d $(TZGEN) -L /dev/null tzdata.zi ;
```

It will generate the file below :

```
To be added.
```

We can see all the shifts that will be applied to the clock. And the rule is not ready to be be changed.

## Conclusion

We can answer to the question of time changes with the tzdata package because it holds a very important information for computers : the clock. So basically, if it become true, we should be able to see commits to this package.